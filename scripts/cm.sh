#!/bin/sh
# ============================================================
#  CPE Monitor 管理工具 (cm)
#  用法: cm
#  安装: curl -fsSL <url>/cm.sh -o /usr/bin/cm && chmod +x /usr/bin/cm && cm
# ============================================================

set -e

# ---- 配置 ----
REPO="keiraee/cpe-monitor"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
VERSION="1.0.0"

CGI_DIR="/www/cgi-bin"
HTML_DIR="/www/cmonitor"
CGI_FILE="$CGI_DIR/cmonitor"
HTML_FILE="$HTML_DIR/index.html"
SELF_PATH="/usr/bin/cm"

# ---- 颜色 ----
if [ -t 1 ]; then
  R='\033[0;31m' G='\033[0;32m' Y='\033[0;33m' B='\033[0;34m' C='\033[0;36m' N='\033[0m'
else
  R='' G='' Y='' B='' C='' N=''
fi

# ---- 工具函数 ----
get_hostname() {
  uci get system.@system[0].hostname 2>/dev/null || cat /proc/sys/kernel/hostname 2>/dev/null || echo "OpenWrt"
}

get_ip() {
  uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1"
}

is_installed() {
  [ -f "$CGI_FILE" ] && [ -f "$HTML_FILE" ]
}

download() {
  local url="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$dest" "$url"
  else
    echo -e "  ${R}错误: 设备缺少 curl 和 wget，无法下载${N}"
    return 1
  fi
}

pause() {
  echo ""
  echo -n "按回车返回菜单..."
  read -r _ 2>/dev/null || sleep 2
}

# ---- 安装 ----
do_install() {
  echo ""
  echo -e "${B}[1/3]${N} 下载 CGI 监控脚本..."
  if ! download "$BASE_URL/src/cgi/cmonitor" "$CGI_FILE"; then
    echo -e "  ${R}✗ 下载失败${N}"; pause; return 1
  fi
  chmod +x "$CGI_FILE"
  echo -e "  ${G}✓${N} $CGI_FILE"

  echo -e "${B}[2/3]${N} 下载前端页面..."
  if ! download "$BASE_URL/src/web/index.html" "$HTML_FILE"; then
    echo -e "  ${R}✗ 下载失败${N}"; pause; return 1
  fi
  echo -e "  ${G}✓${N} $HTML_FILE"

  echo -e "${B}[3/3]${N} 验证安装..."
  if is_installed; then
    local ip=$(get_ip)
    echo -e "  ${G}✓ 安装成功${N}"
    echo ""
    echo -e "  访问: ${C}http://$ip/cmonitor/${N}"
  else
    echo -e "  ${R}✗ 安装异常，请检查文件${N}"
  fi
  pause
}

# ---- 更新（自更新 + 文件更新）----
do_update() {
  echo ""
  echo -e "${B}[1/4]${N} 更新管理工具..."
  local tmp="/tmp/cm.sh.new"
  if download "$BASE_URL/scripts/cm.sh" "$tmp"; then
    local new_ver=$(grep '^VERSION=' "$tmp" | head -1 | cut -d'"' -f2)
    local cur_ver="$VERSION"
    if [ "$new_ver" != "$cur_ver" ]; then
      echo -e "  ${G}✓${N} 发现新版本: $cur_ver → $new_ver"
      chmod +x "$tmp"
      cp "$tmp" "$SELF_PATH"
      rm -f "$tmp"
      echo -e "  ${G}✓${N} 管理工具已更新，用新版本继续..."
      exec "$SELF_PATH" _update_files
    else
      echo -e "  ${G}✓${N} 已是最新版本 ($cur_ver)"
      rm -f "$tmp"
    fi
  else
    echo -e "  ${Y}⚠ 无法检查更新，继续更新监控文件...${N}"
  fi

  _update_files
}

_update_files() {
  echo -e "${B}[2/4]${N} 下载最新 CGI 脚本..."
  if download "$BASE_URL/src/cgi/cmonitor" "$CGI_FILE"; then
    chmod +x "$CGI_FILE"
    echo -e "  ${G}✓${N} CGI 脚本已更新"
  else
    echo -e "  ${R}✗ CGI 脚本更新失败${N}"
  fi

  echo -e "${B}[3/4]${N} 下载最新前端页面..."
  if download "$BASE_URL/src/web/index.html" "$HTML_FILE"; then
    echo -e "  ${G}✓${N} 前端页面已更新"
  else
    echo -e "  ${R}✗ 前端页面更新失败${N}"
  fi

  echo -e "${B}[4/4]${N} 验证..."
  if is_installed; then
    echo -e "  ${G}✓ 更新完成${N}"
  else
    echo -e "  ${R}✗ 文件缺失，请重新安装${N}"
  fi
  pause
}

# ---- 卸载 ----
do_uninstall() {
  echo ""
  echo -e "${Y}即将删除以下文件:${N}"
  echo "  - $CGI_FILE"
  echo "  - $HTML_FILE"
  echo "  - $SELF_PATH"
  echo ""
  echo -n "确认卸载？(y/N): "
  read -r confirm 2>/dev/null || confirm="n"
  case "$confirm" in
    y|Y)
      rm -f "$CGI_FILE" "$HTML_FILE"
      echo -e "  ${G}✓${N} 监控文件已删除"
      rm -f "$SELF_PATH"
      echo -e "  ${G}✓${N} 管理工具已删除"
      echo -e "  ${G}✓ 卸载完成${N}"
      exit 0
      ;;
    *)
      echo "  已取消"
      pause
      ;;
  esac
}

# ---- 菜单 ----
show_menu() {
  local host=$(get_hostname)
  local ip=$(get_ip)
  local status_line

  if is_installed; then
    status_line="\033[1;32m✅ 已安装\033[0m (v$VERSION)"
  else
    status_line="\033[1;31m❌ 未安装\033[0m"
  fi

  clear 2>/dev/null || true
  echo ""
  echo -e "  ${C}┌─────────────────────────────────────┐${N}"
  echo -e "  ${C}│${N}  📡 CMonitor 管理工具  v$VERSION      ${C}│${N}"
  echo -e "  ${C}├─────────────────────────────────────┤${N}"
  echo -e "  ${C}│${N}  设备: $host"
  echo -e "  ${C}│${N}  状态: $status_line"
  echo -e "  ${C}│${N}  地址: ${B}http://$ip/cmonitor/${N}"
  echo -e "  ${C}└─────────────────────────────────────┘${N}"
  echo ""
  echo "  1) 安装"
  echo "  2) 更新"
  echo "  3) 卸载"
  echo "  0) 退出"
  echo ""
}

# ---- 主流程 ----
# 支持内部调用: cm _update_files
if [ "$1" = "_update_files" ]; then
  _update_files
  exit 0
fi

while true; do
  show_menu
  echo -n "  请选择 [0-3]: "
  read -r choice 2>/dev/null || choice="0"
  case "$choice" in
    1) do_install ;;
    2) do_update ;;
    3) do_uninstall ;;
    0) echo "  再见!"; exit 0 ;;
    *) echo -e "  ${Y}无效选项${N}"; sleep 1 ;;
  esac
done
