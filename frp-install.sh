#!/bin/bash
set -e

ACTION="$1"

detect_arch() {
  ARCH_RAW=$(uname -m)
  case "$ARCH_RAW" in
    x86_64) echo "linux_amd64" ;;
    aarch64) echo "linux_arm64" ;;
    armv7l) echo "linux_arm" ;;
    *) echo "unknown"; exit 1 ;;
  esac
}

install_frp() {
  ARCH=$(detect_arch)
  LATEST=$(curl -fsSL https://api.github.com/repos/fatedier/frp/releases/latest | grep tag_name | cut -d '"' -f 4)
  URL="https://github.com/fatedier/frp/releases/download/${LATEST}/frp_${LATEST#v}_${ARCH}.tar.gz"

  mkdir -p /opt/frp
  cd /opt/frp

  curl -fsSL "$URL" -o frp.tar.gz
  tar -xzf frp.tar.gz --strip-components=1
  rm frp.tar.gz

  TOKEN=$(openssl rand -hex 16)
  echo "$TOKEN" > /opt/frp/server_token

  cp systemd/frps.service /etc/systemd/system/frps.service
  cp systemd/frpc@.service /etc/systemd/system/frpc@.service

  systemctl daemon-reload
  echo "FRP installed. Server token: $TOKEN"
}

update_frp() {
  echo "Updating FRP..."
  install_frp
}

uninstall_frp() {
  systemctl stop frps || true
  systemctl disable frps || true
  rm -f /etc/systemd/system/frps.service
  rm -f /etc/systemd/system/frpc@.service
  rm -rf /opt/frp
  systemctl daemon-reload
  echo "FRP uninstalled."
}

case "$ACTION" in
  install) install_frp ;;
  update) update_frp ;;
  uninstall) uninstall_frp ;;
  *)
    echo "Usage: $0 {install|update|uninstall}"
    exit 1
  ;;
esac
