#!/usr/bin/env bash
# gost SOCKS5 一键安装脚本
# 用法:
#   安装:   bash install.sh [-u 用户名] [-w 密码] [-p 端口]
#   卸载:   bash install.sh uninstall
# 不传参数时：端口 1080，用户名/密码随机生成

set -eu

GOST_VER="2.11.5"
BIN="/usr/local/bin/gost"
SERVICE="gost-socks5"
UNIT="/etc/systemd/system/${SERVICE}.service"

[ "$(id -u)" -eq 0 ] || { echo "请使用 root 运行"; exit 1; }

# ---------- 卸载 ----------
if [ "${1:-}" = "uninstall" ]; then
  systemctl disable --now "$SERVICE" 2>/dev/null || true
  rm -f "$UNIT" "$BIN"
  systemctl daemon-reload
  echo "已卸载 gost-socks5"
  exit 0
fi

# ---------- 参数 ----------
rand() { tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"; }

PORT=1080
USER_NAME=""
PASS=""
while getopts "u:w:p:" opt; do
  case "$opt" in
    u) USER_NAME="$OPTARG" ;;
    w) PASS="$OPTARG" ;;
    p) PORT="$OPTARG" ;;
    *) echo "用法: $0 [-u 用户名] [-w 密码] [-p 端口] | uninstall"; exit 1 ;;
  esac
done
[ -n "$USER_NAME" ] || USER_NAME="$(rand 8)"
[ -n "$PASS" ] || PASS="$(rand 16)"

case "$PORT" in
  ''|*[!0-9]*) echo "端口必须是数字"; exit 1 ;;
esac

# ---------- 架构检测 ----------
case "$(uname -m)" in
  x86_64|amd64)  ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  armv7l|armv7)  ARCH="armv7" ;;
  *) echo "不支持的架构: $(uname -m)"; exit 1 ;;
esac

# ---------- 下载安装 ----------
URL="https://github.com/ginuerzh/gost/releases/download/v${GOST_VER}/gost-linux-${ARCH}-${GOST_VER}.gz"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo ">> 下载 gost ${GOST_VER} (${ARCH})"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$URL" -o "$TMP/gost.gz"
else
  wget -q "$URL" -O "$TMP/gost.gz"
fi
gunzip -f "$TMP/gost.gz"
install -m 755 "$TMP/gost" "$BIN"

# ---------- systemd 服务 ----------
cat > "$UNIT" <<EOF
[Unit]
Description=Gost Socks5 Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=${BIN} -L=${USER_NAME}:${PASS}@:${PORT}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE"
sleep 1

# ---------- 检测 ----------
echo ">> 检测代理是否可用..."
if OUT="$(curl -fsS -m 10 -x "socks5://${USER_NAME}:${PASS}@127.0.0.1:${PORT}" https://api.ipify.org 2>/dev/null)"; then
  echo "成功，出口 IP: ${OUT}"
else
  echo "检测失败，请查看: journalctl -u ${SERVICE} -n 50"
fi

echo
echo "========== 连接信息 =========="
echo "地址:   <服务器IP>:${PORT}"
echo "用户名: ${USER_NAME}"
echo "密码:   ${PASS}"
echo "链接:   socks5://${USER_NAME}:${PASS}@<服务器IP>:${PORT}"
echo "提示:   记得在防火墙/安全组放行 TCP ${PORT}"
echo "卸载:   bash install.sh uninstall"
