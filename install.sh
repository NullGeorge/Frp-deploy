#!/usr/bin/env bash
set -Eeuo pipefail

LOG_FILE="/var/log/frp-installer.log"
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

ACTION="install"
YES=0
DRY_RUN=0

FRP_DIR="/opt/frp"
BIN_DIR="/opt/frp/bin"
CONF_DIR="/etc/frp"
SYSTEMD_DIR="/etc/systemd/system"

BIND_PORT=7000
QUIC_PORT=7000
TOKEN=""

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

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      install|update|uninstall)
        ACTION="$1"
        ;;
      --token=*) TOKEN="${1#*=}" ;;
      --token) TOKEN="$2"; shift ;;
      --bind-port=*) BIND_PORT="${1#*=}" ;;
      --quic-port=*) QUIC_PORT="${1#*=}" ;;
      --yes|--non-interactive) YES=1 ;;
      --dry-run) DRY_RUN=1 ;;
      -h|--help)
        cat <<EOF
Usage: install.sh [install|update|uninstall] [options]

Options:
  --token TOKEN           FRP auth token
  --bind-port PORT        Bind port (default 7000)
  --quic-port PORT        QUIC port (default 7000)
  --yes                   Non-interactive
  --dry-run               Show actions without executing
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

check_existing() {
  if systemctl list-unit-files | grep -q frps.service; then
    log "Existing FRP installation detected"
    if [[ "$YES" -ne 1 ]]; then
      read -rp "Continue and overwrite existing FRP? [y/N]: " ans
      [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1
    fi
  fi
}

install_frp() {
  check_existing

  need_cmd tar
  need_cmd openssl

  ARCH=$(detect_arch)
  DL=$(get_downloader)

  LATEST=$(eval "$DL https://api.github.com/repos/fatedier/frp/releases/latest" | grep tag_name | cut -d '"' -f 4)
  URL="https://github.com/fatedier/frp/releases/download/${LATEST}/frp_${LATEST#v}_${ARCH}.tar.gz"

  [[ -z "$TOKEN" ]] && TOKEN=$(openssl rand -hex 16)

  run "mkdir -p $FRP_DIR $BIN_DIR $CONF_DIR"
  run "cd $FRP_DIR"
  run "$DL $URL > frp.tar.gz"
  run "tar -xzf frp.tar.gz"
  run "cp frp_${LATEST#v}_${ARCH}/frps $BIN_DIR/"
  run "cp frp_${LATEST#v}_${ARCH}/frpc $BIN_DIR/"
  run "rm -rf frp_${LATEST#v}_${ARCH} frp.tar.gz"

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
ExecStart=$BIN_DIR/frps -c $CONF_DIR/frps.toml
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

  run "systemctl daemon-reload"
  run "systemctl enable frps"
  run "systemctl restart frps"

  SERVER_IP=$( (curl -fsSL ifconfig.co || wget -qO- ifconfig.co) 2>/dev/null || echo "UNKNOWN")

  cat <<EOF

================ FRP SUMMARY ================
FRP installed successfully

Binary path:     $BIN_DIR/frps
Config path:     $CONF_DIR/frps.toml
Service:         frps.service

Server address:  $SERVER_IP
Bind port:       $BIND_PORT
QUIC port:       $QUIC_PORT
Auth token:      $TOKEN

Client example:
--------------------------------------------
serverAddr = "$SERVER_IP"
serverPort = $BIND_PORT
auth.method = "token"
auth.token = "$TOKEN"
--------------------------------------------

Log file:        $LOG_FILE
============================================

EOF
}

uninstall_frp() {
  run "systemctl stop frps || true"
  run "systemctl disable frps || true"
  run "rm -f $SYSTEMD_DIR/frps.service"
  run "rm -rf $FRP_DIR $CONF_DIR"
  run "systemctl daemon-reload"
  log "FRP uninstalled"
}

parse_args "$@"

case "$ACTION" in
  install|update) install_frp ;;
  uninstall) uninstall_frp ;;
esac
