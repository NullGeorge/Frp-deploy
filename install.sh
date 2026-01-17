#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/frp-installer.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

# Конфигурация
ACTION="menu"
YES=0
DRY_RUN=0
INSTALL_SERVER=0
INSTALL_CLIENT=0

FRP_DIR="/opt/frp"
BIN_DIR="/opt/frp/bin"
CONF_DIR="/etc/frp"
SYSTEMD_DIR="/etc/systemd/system"

BIND_PORT=7000
QUIC_PORT=7000
TOKEN=""
SERVER_ADDR=""

# Цвета для TUI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

log() {
  echo "[FRP-INSTALLER] $(date '+%Y-%m-%d %H:%M:%S') $*"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    log "ERROR: required command '$1' not found"
    exit 1
  }
}

check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
  fi
}

detect_arch() {
  case "$(uname -m)" in
    x86_64) echo "linux_amd64" ;;
    aarch64) echo "linux_arm64" ;;
    armv7l) echo "linux_arm" ;;
    *) log "Unsupported architecture"; exit 1 ;;
  esac
}

get_downloader() {
  if command -v curl >/dev/null 2>&1; then
    echo "curl -fsSL"
  elif command -v wget >/dev/null 2>&1; then
    echo "wget -qO-"
  else
    log "Neither curl nor wget found"
    exit 1
  fi
}

draw_header() {
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}FRP Installer & Manager${NC}                                ${CYAN}║${NC}"
  echo -e "${CYAN}║${NC}  Fast Reverse Proxy Installation Tool                   ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
  echo
}

show_status() {
  echo -e "${BOLD}Current Status:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  
  if systemctl is-active --quiet frps 2>/dev/null; then
    echo -e "  FRP Server:  ${GREEN}● Running${NC}"
  elif systemctl list-unit-files | grep -q frps.service 2>/dev/null; then
    echo -e "  FRP Server:  ${YELLOW}○ Installed (stopped)${NC}"
  else
    echo -e "  FRP Server:  ${RED}✗ Not installed${NC}"
  fi
  
  if [[ -f "$BIN_DIR/frpc" ]]; then
    echo -e "  FRP Client:  ${GREEN}✓ Installed${NC}"
  else
    echo -e "  FRP Client:  ${RED}✗ Not installed${NC}"
  fi
  
  if [[ -f "$CONF_DIR/frps.toml" ]]; then
    echo -e "  Config dir:  ${GREEN}$CONF_DIR${NC}"
  fi
  
  echo
}

main_menu() {
  while true; do
    draw_header
    show_status
    
    echo -e "${BOLD}Main Menu:${NC}"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -e "  ${GREEN}1)${NC} Install FRP components"
    echo -e "  ${YELLOW}2)${NC} Manage installed components"
    echo -e "  ${BLUE}3)${NC} View configuration"
    echo -e "  ${MAGENTA}4)${NC} Update FRP"
    echo -e "  ${RED}5)${NC} Uninstall components"
    echo -e "  ${CYAN}6)${NC} View logs"
    echo -e "  ${RED}0)${NC} Exit"
    echo -e "─────────────────────────────────────────────────────────────"
    echo -n "Select option: "
    
    read -r choice
    
    case "$choice" in
      1) install_menu ;;
      2) manage_menu ;;
      3) view_config ;;
      4) update_frp ;;
      5) uninstall_menu ;;
      6) view_logs ;;
      0) exit 0 ;;
      *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
  done
}

install_menu() {
  draw_header
  echo -e "${BOLD}Install FRP Components:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -e "  ${GREEN}1)${NC} Install FRP Server only"
  echo -e "  ${GREEN}2)${NC} Install FRP Client only"
  echo -e "  ${GREEN}3)${NC} Install both Server and Client"
  echo -e "  ${RED}0)${NC} Back to main menu"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -n "Select option: "
  
  read -r choice
  
  case "$choice" in
    1) INSTALL_SERVER=1; INSTALL_CLIENT=0; configure_and_install ;;
    2) INSTALL_SERVER=0; INSTALL_CLIENT=1; configure_and_install ;;
    3) INSTALL_SERVER=1; INSTALL_CLIENT=1; configure_and_install ;;
    0) return ;;
    *) echo -e "${RED}Invalid option${NC}"; sleep 1; install_menu ;;
  esac
}

configure_and_install() {
  # В не-интерактивном режиме пропускаем запросы
  if [[ "$YES" -eq 1 ]]; then
    if [[ "$INSTALL_SERVER" -eq 1 ]]; then
      # Для сервера: авто-генерация токена если не указан
      if [[ -z "$TOKEN" ]]; then
        need_cmd openssl
        TOKEN=$(openssl rand -hex 16)
        log "Generated auth token: $TOKEN"
      fi
    fi
    
    if [[ "$INSTALL_CLIENT" -eq 1 ]]; then
      # Для клиента: проверяем обязательные параметры
      if [[ -z "$SERVER_ADDR" ]]; then
        log "ERROR: --server-addr required for client installation"
        exit 1
      fi
      if [[ -z "$TOKEN" ]]; then
        log "ERROR: --token required for client installation"
        exit 1
      fi
    fi
    
    install_frp
    return
  fi
  
  # Интерактивный режим (оригинальный код)
  draw_header
  echo -e "${BOLD}Configuration:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  
  if [[ "$INSTALL_SERVER" -eq 1 ]]; then
    echo -n "Bind port [7000]: "
    read -r input_port
    BIND_PORT="${input_port:-7000}"
    
    echo -n "QUIC port [7000]: "
    read -r input_quic
    QUIC_PORT="${input_quic:-7000}"
    
    echo -n "Auth token (leave empty for auto-generate): "
    read -r input_token
    if [[ -z "$input_token" ]]; then
      need_cmd openssl
      TOKEN=$(openssl rand -hex 16)
      echo -e "  ${GREEN}Generated token: $TOKEN${NC}"
    else
      TOKEN="$input_token"
    fi
  fi
  
  if [[ "$INSTALL_CLIENT" -eq 1 ]]; then
    echo -n "Server address: "
    read -r SERVER_ADDR
    [[ -z "$SERVER_ADDR" ]] && { echo -e "${RED}Server address required${NC}"; sleep 2; return; }
    
    echo -n "Server port [7000]: "
    read -r input_sport
    BIND_PORT="${input_sport:-7000}"
    
    echo -n "Auth token: "
    read -r TOKEN
    [[ -z "$TOKEN" ]] && { echo -e "${RED}Token required${NC}"; sleep 2; return; }
  fi
  
  echo
  echo -e "${YELLOW}Ready to install. Continue? [y/N]:${NC} "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
  
  install_frp
  
  echo
  echo -e "${GREEN}Installation completed!${NC}"
  echo "Press Enter to continue..."
  read -r
}

install_frp() {
  need_cmd tar
  
  ARCH=$(detect_arch)
  DL=$(get_downloader)
  
  log "Fetching latest FRP release..."
  LATEST=$(eval "$DL https://api.github.com/repos/fatedier/frp/releases/latest" | grep tag_name | cut -d '"' -f 4)
  
  if [[ -z "$LATEST" ]]; then
    log "ERROR: Could not fetch latest version"
    exit 1
  fi
  
  URL="https://github.com/fatedier/frp/releases/download/${LATEST}/frp_${LATEST#v}_${ARCH}.tar.gz"
  
  log "Installing FRP ${LATEST}..."
  
  run "mkdir -p $FRP_DIR $BIN_DIR $CONF_DIR"
  run "cd $FRP_DIR"
  
  log "Downloading FRP..."
  run "$DL $URL > frp.tar.gz"
  run "tar -xzf frp.tar.gz"
  
  if [[ "$INSTALL_SERVER" -eq 1 ]]; then
    log "Installing FRP Server..."
    run "cp frp_${LATEST#v}_${ARCH}/frps $BIN_DIR/"
    run "chmod +x $BIN_DIR/frps"
    
    run "cat > $CONF_DIR/frps.toml <<EOF
bindPort = $BIND_PORT
quicBindPort = $QUIC_PORT

auth.method = \"token\"
auth.token = \"$TOKEN\"
EOF"
    
    run "cat > $SYSTEMD_DIR/frps.service <<EOF
[Unit]
Description=FRP Server
After=network.target

[Service]
Type=simple
ExecStart=$BIN_DIR/frps -c $CONF_DIR/frps.toml
Restart=always
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF"
    
    run "systemctl daemon-reload"
    run "systemctl enable frps"
    run "systemctl restart frps"
    
    SERVER_IP=$(curl -4 -fsSL ifconfig.co 2>/dev/null || echo "UNKNOWN")
    
    log "FRP Server installed and started"
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}FRP Server Configuration:${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "  Server IP:    ${CYAN}$SERVER_IP${NC}"
    echo -e "  Bind port:    ${CYAN}$BIND_PORT${NC}"
    echo -e "  QUIC port:    ${CYAN}$QUIC_PORT${NC}"
    echo -e "  Auth token:   ${YELLOW}$TOKEN${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  fi
  
  if [[ "$INSTALL_CLIENT" -eq 1 ]]; then
    log "Installing FRP Client..."
    run "cp frp_${LATEST#v}_${ARCH}/frpc $BIN_DIR/"
    run "chmod +x $BIN_DIR/frpc"
    
    run "cat > $CONF_DIR/frpc.toml <<EOF
serverAddr = \"$SERVER_ADDR\"
serverPort = $BIND_PORT
auth.method = \"token\"
auth.token = \"$TOKEN\"

[[proxies]]
name = \"ssh\"
type = \"tcp\"
localIP = \"127.0.0.1\"
localPort = 22
remotePort = 6000
EOF"
    
    run "cat > $SYSTEMD_DIR/frpc@.service <<'EOF'
[Unit]
Description=FRP Client (%i)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$BIN_DIR/frpc -c $CONF_DIR/%i.toml
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF"
    
    run "systemctl daemon-reload"
    
    log "FRP Client installed"
    echo
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}FRP Client Configuration:${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
    echo -e "  Config file:  ${CYAN}$CONF_DIR/frpc.toml${NC}"
    echo -e "  Start with:   ${YELLOW}systemctl start frpc@frpc${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════${NC}"
  fi
  
  run "rm -rf frp_${LATEST#v}_${ARCH} frp.tar.gz"
}

manage_menu() {
  draw_header
  show_status
  
  echo -e "${BOLD}Manage Components:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -e "  ${GREEN}1)${NC} Start FRP Server"
  echo -e "  ${YELLOW}2)${NC} Stop FRP Server"
  echo -e "  ${BLUE}3)${NC} Restart FRP Server"
  echo -e "  ${CYAN}4)${NC} Enable FRP Server (autostart)"
  echo -e "  ${MAGENTA}5)${NC} Disable FRP Server (no autostart)"
  echo -e "  ${GREEN}6)${NC} Start FRP Client"
  echo -e "  ${YELLOW}7)${NC} Stop FRP Client"
  echo -e "  ${RED}0)${NC} Back to main menu"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -n "Select option: "
  
  read -r choice
  
  case "$choice" in
    1) systemctl start frps && echo -e "${GREEN}Server started${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    2) systemctl stop frps && echo -e "${YELLOW}Server stopped${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    3) systemctl restart frps && echo -e "${GREEN}Server restarted${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    4) systemctl enable frps && echo -e "${GREEN}Server enabled${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    5) systemctl disable frps && echo -e "${YELLOW}Server disabled${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    6) systemctl start frpc@frpc && echo -e "${GREEN}Client started${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    7) systemctl stop frpc@frpc && echo -e "${YELLOW}Client stopped${NC}" || echo -e "${RED}Failed${NC}"; sleep 2 ;;
    0) return ;;
    *) echo -e "${RED}Invalid option${NC}"; sleep 1; manage_menu ;;
  esac
  
  manage_menu
}

view_config() {
  draw_header
  echo -e "${BOLD}Configuration Files:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  
  if [[ -f "$CONF_DIR/frps.toml" ]]; then
    echo -e "${GREEN}Server config ($CONF_DIR/frps.toml):${NC}"
    cat "$CONF_DIR/frps.toml"
    echo
  fi
  
  if [[ -f "$CONF_DIR/frpc.toml" ]]; then
    echo -e "${GREEN}Client config ($CONF_DIR/frpc.toml):${NC}"
    cat "$CONF_DIR/frpc.toml"
    echo
  fi
  
  if [[ ! -f "$CONF_DIR/frps.toml" && ! -f "$CONF_DIR/frpc.toml" ]]; then
    echo -e "${YELLOW}No configuration files found${NC}"
  fi
  
  echo
  echo "Press Enter to continue..."
  read -r
}

uninstall_menu() {
  draw_header
  echo -e "${BOLD}Uninstall Components:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -e "  ${RED}1)${NC} Uninstall FRP Server only"
  echo -e "  ${RED}2)${NC} Uninstall FRP Client only"
  echo -e "  ${RED}3)${NC} Uninstall everything (Server + Client)"
  echo -e "  ${GREEN}0)${NC} Back to main menu"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -n "Select option: "
  
  read -r choice
  
  case "$choice" in
    1) uninstall_component "server" ;;
    2) uninstall_component "client" ;;
    3) uninstall_component "all" ;;
    0) return ;;
    *) echo -e "${RED}Invalid option${NC}"; sleep 1; uninstall_menu ;;
  esac
}

uninstall_component() {
  local component="$1"
  
  # В не-интерактивном режиме пропускаем подтверждение
  if [[ "$YES" -ne 1 ]]; then
    echo -e "${RED}Warning: This will remove the selected component(s)${NC}"
    echo -n "Are you sure? [y/N]: "
    read -r confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
  fi
  
  case "$component" in
    server)
      run "systemctl stop frps || true"
      run "systemctl disable frps || true"
      run "rm -f $SYSTEMD_DIR/frps.service"
      run "rm -f $BIN_DIR/frps"
      run "rm -f $CONF_DIR/frps.toml"
      run "systemctl daemon-reload"
      log "FRP Server uninstalled"
      ;;
    client)
      run "systemctl stop frpc@frpc || true"
      run "systemctl disable frpc@frpc || true"
      run "rm -f $SYSTEMD_DIR/frpc@.service"
      run "rm -f $BIN_DIR/frpc"
      run "rm -f $CONF_DIR/frpc.toml"
      run "systemctl daemon-reload"
      log "FRP Client uninstalled"
      ;;
    all)
      run "systemctl stop frps frpc@frpc || true"
      run "systemctl disable frps frpc@frpc || true"
      run "rm -f $SYSTEMD_DIR/frps.service $SYSTEMD_DIR/frpc@.service"
      run "rm -rf $FRP_DIR $CONF_DIR"
      run "systemctl daemon-reload"
      log "FRP completely uninstalled"
      ;;
  esac
  
  echo -e "${GREEN}Uninstallation completed${NC}"
  
  # В интерактивном режиме ждём нажатия Enter
  if [[ "$YES" -ne 1 ]]; then
    echo "Press Enter to continue..."
    read -r
  fi
}

update_frp() {
  draw_header
  echo -e "${BOLD}Update FRP:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  
  # Определяем что установлено
  local has_server=0
  local has_client=0
  
  [[ -f "$BIN_DIR/frps" ]] && has_server=1
  [[ -f "$BIN_DIR/frpc" ]] && has_client=1
  
  if [[ $has_server -eq 0 && $has_client -eq 0 ]]; then
    echo -e "${YELLOW}No FRP components installed${NC}"
    sleep 2
    return
  fi
  
  echo -e "This will update installed FRP components"
  echo -n "Continue? [y/N]: "
  read -r confirm
  
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && return
  
  # Сохраняем конфигурации
  [[ -f "$CONF_DIR/frps.toml" ]] && cp "$CONF_DIR/frps.toml" "$CONF_DIR/frps.toml.bak"
  [[ -f "$CONF_DIR/frpc.toml" ]] && cp "$CONF_DIR/frpc.toml" "$CONF_DIR/frpc.toml.bak"
  
  INSTALL_SERVER=$has_server
  INSTALL_CLIENT=$has_client
  
  # Останавливаем сервисы
  [[ $has_server -eq 1 ]] && systemctl stop frps
  [[ $has_client -eq 1 ]] && systemctl stop frpc@frpc
  
  install_frp
  
  # Восстанавливаем конфигурации
  [[ -f "$CONF_DIR/frps.toml.bak" ]] && mv "$CONF_DIR/frps.toml.bak" "$CONF_DIR/frps.toml"
  [[ -f "$CONF_DIR/frpc.toml.bak" ]] && mv "$CONF_DIR/frpc.toml.bak" "$CONF_DIR/frpc.toml"
  
  # Перезапускаем сервисы
  [[ $has_server -eq 1 ]] && systemctl start frps
  [[ $has_client -eq 1 ]] && systemctl start frpc@frpc
  
  echo -e "${GREEN}Update completed!${NC}"
  echo "Press Enter to continue..."
  read -r
}

view_logs() {
  draw_header
  echo -e "${BOLD}View Logs:${NC}"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -e "  ${GREEN}1)${NC} View FRP Server logs"
  echo -e "  ${GREEN}2)${NC} View FRP Client logs"
  echo -e "  ${BLUE}3)${NC} View installer log"
  echo -e "  ${RED}0)${NC} Back to main menu"
  echo -e "─────────────────────────────────────────────────────────────"
  echo -n "Select option: "
  
  read -r choice
  
  case "$choice" in
    1) journalctl -u frps -n 50 --no-pager; echo; echo "Press Enter..."; read -r ;;
    2) journalctl -u frpc@frpc -n 50 --no-pager; echo; echo "Press Enter..."; read -r ;;
    3) tail -n 50 "$LOG_FILE"; echo; echo "Press Enter..."; read -r ;;
    0) return ;;
    *) echo -e "${RED}Invalid option${NC}"; sleep 1; view_logs ;;
  esac
  
  view_logs
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      install|update|uninstall)
        ACTION="$1"
        ;;
      --token=*) TOKEN="${1#*=}" ;;
      --token) TOKEN="$2"; shift ;;
      --bind-port=*) BIND_PORT="${1#*=}" ;;
      --bind-port) BIND_PORT="$2"; shift ;;
      --quic-port=*) QUIC_PORT="${1#*=}" ;;
      --quic-port) QUIC_PORT="$2"; shift ;;
      --server-addr=*) SERVER_ADDR="${1#*=}" ;;
      --server-addr) SERVER_ADDR="$2"; shift ;;
      --server) INSTALL_SERVER=1 ;;
      --client) INSTALL_CLIENT=1 ;;
      --yes|--non-interactive|-y) YES=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help)
        cat <<EOF
Usage: install.sh [command] [options]

Commands:
  menu                    Show interactive TUI menu (default)
  install                 Install FRP in CLI mode
  update                  Update FRP
  uninstall               Uninstall FRP

Options:
  --server                Install server component
  --client                Install client component
  --token TOKEN           FRP auth token (auto-generated for server if not set)
  --bind-port PORT        Bind port (default 7000)
  --quic-port PORT        QUIC port (default 7000)
  --server-addr ADDR      Server address (required for client)
  --yes, -y               Non-interactive mode (auto-confirm)
  --dry-run               Show actions without executing
  -h, --help              Show this help

Examples:
  # Interactive TUI menu
  sudo $0

  # Install server with auto-generated token
  sudo $0 install --server --yes

  # Install server with custom settings
  sudo $0 install --server --token mysecret --bind-port 7500 --yes

  # Install client
  sudo $0 install --client --server-addr 1.2.3.4 --token mysecret --yes

  # Install both server and client
  sudo $0 install --server --client --yes

  # One-liner installation via curl (server only)
  curl -fsSL https://raw.githubusercontent.com/.../install.sh | sudo bash -s -- install --server --yes

  # One-liner installation via wget (server only)
  wget -qO- https://raw.githubusercontent.com/.../install.sh | sudo bash -s -- install --server --yes

  # Uninstall everything
  sudo $0 uninstall --yes

EOF
        exit 0
        ;;
      *)
        log "Unknown argument: $1"
        exit 1
        ;;
    esac
    shift
  done
}

# Main
check_root
parse_args "$@"

# Если используется --yes, но не указана команда, устанавливаем сервер по умолчанию
if [[ "$YES" -eq 1 && "$ACTION" == "menu" && ($INSTALL_SERVER -eq 1 || $INSTALL_CLIENT -eq 1) ]]; then
  ACTION="install"
fi

case "$ACTION" in
  menu) main_menu ;;
  install) 
    if [[ $INSTALL_SERVER -eq 0 && $INSTALL_CLIENT -eq 0 ]]; then
      echo "ERROR: Please specify --server and/or --client"
      echo "Examples:"
      echo "  Install server: $0 install --server --yes"
      echo "  Install client: $0 install --client --server-addr 1.2.3.4 --token TOKEN --yes"
      echo "  Install both:   $0 install --server --client --yes"
      exit 1
    fi
    configure_and_install
    ;;
  update) update_frp ;;
  uninstall) 
    if [[ "$YES" -eq 1 ]]; then
      # В автоматическом режиме удаляем всё
      uninstall_component "all"
    else
      uninstall_menu
    fi
    ;;
esac