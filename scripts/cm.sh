#!/bin/sh
# ============================================================
#  CPE Monitor 管理工具 (cm)
#  用法: cm
#  安装: curl -fsSL <url>/cm.sh -o /usr/bin/cm && chmod +x /usr/bin/cm && cm
# ============================================================

set -e

# ---- 配置 ----
REPO="keiraee/cpe-monitor"
BRANCH="master"
BASE_URL="https://raw.githubusercontent.com/$REPO/$BRANCH"
VERSION="1.0.1"

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
    curl -fSL# --connect-timeout 10 --max-time 60 "$url" -o "$dest"
  elif command -v wget >/dev/null 2>&1; then
    wget --timeout=60 -O "$dest" "$url"
  else
    echo -e "  \033[0;31m错误: 设备缺少 curl 和 wget，无法下载\033[0m"
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
  if is_installed; then
    echo ""
    echo -e "  \033[0;33m⚠ 当前已安装，重新安装将覆盖现有文件\033[0m"
    echo -n "  确认重新安装？(y/N): "
    read -r confirm 2>/dev/null || confirm="n"
    case "$confirm" in
      y|Y) ;;
      *) return 0 ;;
    esac
  fi

  echo ""
  echo -e "\033[0;34m[1/3]\033[0m 下载 CGI 监控脚本..."
  if ! download "$BASE_URL/src/cgi/cmonitor" "$CGI_FILE"; then
    echo -e "  \033[0;31m✗ 下载失败\033[0m"; pause; return 1
  fi
  chmod +x "$CGI_FILE"
  echo -e "  \033[0;32m✓\033[0m $CGI_FILE"

  echo -e "\033[0;34m[2/3]\033[0m 下载前端页面..."
  if ! download "$BASE_URL/src/web/index.html" "$HTML_FILE"; then
    echo -e "  \033[0;31m✗ 下载失败\033[0m"; pause; return 1
  fi
  echo -e "  \033[0;32m✓\033[0m $HTML_FILE"

  echo -e "\033[0;34m[3/3]\033[0m 验证安装..."
  if is_installed; then
    local ip=$(get_ip)
    echo -e "  \033[0;32m✓ 安装成功\033[0m"
    echo ""
    echo -e "  访问: \033[0;36mhttp://$ip/cmonitor/\033[0m"
  else
    echo -e "  \033[0;31m✗ 安装异常，请检查文件\033[0m"
  fi
  pause
}

# ---- 更新 ----
do_update() {
  echo ""
  echo -e "\033[0;34m[1/4]\033[0m 检查管理工具更新..."
  local tmp="/tmp/cm.sh.new"
  if download "$BASE_URL/scripts/cm.sh" "$tmp"; then
    local new_ver=$(grep '^VERSION=' "$tmp" | head -1 | cut -d'"' -f2)
    local cur_ver="$VERSION"
    if [ "$new_ver" != "$cur_ver" ]; then
      echo -e "  \033[0;32m✓\033[0m 发现新版本: $cur_ver → $new_ver，正在更新..."
      chmod +x "$tmp"
      cp "$tmp" "$SELF_PATH"
      rm -f "$tmp"
      echo -e "  \033[0;32m✓\033[0m 管理工具已更新，用新版本继续..."
      exec "$SELF_PATH" _update_files
    else
      echo -e "  \033[0;32m✓\033[0m 已是最新版本 ($cur_ver)"
      rm -f "$tmp"
    fi
  else
    echo -e "  \033[0;33m⚠ 无法检查更新，继续更新监控文件...\033[0m"
  fi

  _update_files
}

_update_files() {
  echo -e "\033[0;34m[2/4]\033[0m 下载最新 CGI 脚本..."
  if download "$BASE_URL/src/cgi/cmonitor" "$CGI_FILE"; then
    chmod +x "$CGI_FILE"
    echo -e "  \033[0;32m✓\033[0m CGI 脚本已更新"
  else
    echo -e "  \033[0;31m✗ CGI 脚本更新失败\033[0m"
  fi

  echo -e "\033[0;34m[3/4]\033[0m 下载最新前端页面..."
  if download "$BASE_URL/src/web/index.html" "$HTML_FILE"; then
    echo -e "  \033[0;32m✓\033[0m 前端页面已更新"
  else
    echo -e "  \033[0;31m✗ 前端页面更新失败\033[0m"
  fi

  echo -e "\033[0;34m[4/4]\033[0m 验证..."
  if is_installed; then
    echo -e "  \033[0;32m✓ 更新完成\033[0m"
  else
    echo -e "  \033[0;31m✗ 文件缺失，请重新安装\033[0m"
  fi
  pause
}

# ---- 卸载 ----
do_uninstall() {
  echo ""
  echo -e "\033[0;33m即将删除以下文件:\033[0m"
  echo "  - $CGI_FILE"
  echo "  - $HTML_FILE"
  echo "  - $SELF_PATH"
  echo ""
  echo -n "确认卸载？(y/N): "
  read -r confirm 2>/dev/null || confirm="n"
  case "$confirm" in
    y|Y)
      rm -f "$CGI_FILE" "$HTML_FILE"
      echo -e "  \033[0;32m✓\033[0m 监控文件已删除"
      rm -f "$SELF_PATH"
      echo -e "  \033[0;32m✓\033[0m 管理工具已删除"
      echo -e "  \033[0;32m✓ 卸载完成\033[0m"
      exit 0
      ;;
    *)
      echo "  已取消"
      pause
      ;;
  esac
}

# ---- 调试 ----
do_debug() {
  echo ""
  echo -e "\033[0;34m=== CGI 脚本调试 ===\033[0m"
  echo ""
  echo -e "\033[0;34m[1/4]\033[0m 检查 CGI 文件..."
  if [ -f "$CGI_FILE" ]; then
    echo -e "  \033[0;32m✓\033[0m $CGI_FILE 存在"
    ls -la "$CGI_FILE"
  else
    echo -e "  \033[0;31m✗\033[0m $CGI_FILE 不存在，请先安装"
    pause; return 1
  fi

  echo ""
  echo -e "\033[0;34m[2/4]\033[0m 测试 ubus 无线接口..."
  local ifaces=$(ubus call network.wireless status 2>/dev/null | jsonfilter -e '@.*.interfaces[*].ifname')
  if [ -n "$ifaces" ]; then
    echo -e "  \033[0;32m✓\033[0m ubus 发现接口: $ifaces"
  else
    echo -e "  \033[0;33m⚠\033[0m ubus 未返回接口，尝试 iwinfo fallback..."
    ifaces=$(iwinfo 2>/dev/null | sed -n 's/^\([a-z0-9]*\)  .*/\1/p')
    if [ -n "$ifaces" ]; then
      echo -e "  \033[0;32m✓\033[0m iwinfo 发现接口: $ifaces"
    else
      echo -e "  \033[0;31m✗\033[0m 未发现任何无线接口"
    fi
  fi

  echo ""
  echo -e "\033[0;34m[3/4]\033[0m 直接运行 CGI 脚本..."
  echo "--- 输出开始 ---"
  sh "$CGI_FILE" 2>/tmp/cm_debug_err.log
  echo ""
  echo "--- 输出结束 ---"

  if [ -s /tmp/cm_debug_err.log ]; then
    echo ""
    echo -e "\033[0;33m错误输出:\033[0m"
    cat /tmp/cm_debug_err.log
  fi

  echo ""
  echo -e "\033[0;34m[4/4]\033[0m 检查关键命令..."
  for cmd in ubus jsonfilter iwinfo free df awk; do
    if command -v $cmd >/dev/null 2>&1; then
      echo -e "  \033[0;32m✓\033[0m $cmd"
    else
      echo -e "  \033[0;31m✗\033[0m $cmd 缺失"
    fi
  done

  echo ""
  echo -e "\033[0;34m=== 调试完成 ===\033[0m"
  pause
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
  echo -e "  \033[0;36m┌─────────────────────────────────────┐\033[0m"
  echo -e "  \033[0;36m│\033[0m  📡 CMonitor 管理工具  v$VERSION      \033[0;36m│\033[0m"
  echo -e "  \033[0;36m├─────────────────────────────────────┤\033[0m"
  echo -e "  \033[0;36m│\033[0m  设备: $host"
  echo -e "  \033[0;36m│\033[0m  状态: $status_line"
  echo -e "  \033[0;36m│\033[0m  地址: \033[0;34mhttp://$ip/cmonitor/\033[0m"
  echo -e "  \033[0;36m└─────────────────────────────────────┘\033[0m"
  echo ""
  echo "  1) 安装"
  echo "  2) 更新"
  echo "  3) 卸载"
  echo "  4) 调试 (查看CGI输出)"
  echo "  0) 退出"
  echo ""
}

# ---- 主流程 ----
if [ "$1" = "_update_files" ]; then
  _update_files
  exit 0
fi

while true; do
  show_menu
  echo -n "  请选择 [0-4]: "
  read -r choice 2>/dev/null || choice="0"
  case "$choice" in
    1) do_install ;;
    2) do_update ;;
    3) do_uninstall ;;
    4) do_debug ;;
    0) echo "  再见!"; exit 0 ;;
    *) echo -e "  \033[0;33m无效选项\033[0m"; sleep 1 ;;
  esac
done
