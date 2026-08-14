#!/bin/sh
# CPE Monitor 部署脚本
# 用法: ./scripts/deploy.sh <设备IP> [用户名]

set -e

DEVICE_IP=${1:-"192.168.1.1"}
USERNAME=${2:-"root"}
REMOTE_BASE="/www"

echo "=========================================="
echo "  CPE Monitor 部署脚本"
echo "=========================================="
echo ""
echo "目标设备: ${USERNAME}@${DEVICE_IP}"
echo ""

# 检查设备连通性
echo "[1/4] 检查设备连通性..."
if ! ping -c 1 -W 3 "$DEVICE_IP" > /dev/null 2>&1; then
  echo "错误: 无法连接到设备 $DEVICE_IP"
  exit 1
fi
echo "  ✓ 设备可达"

# 创建目录
echo "[2/4] 创建远程目录..."
ssh "${USERNAME}@${DEVICE_IP}" "mkdir -p ${REMOTE_BASE}/admin ${REMOTE_BASE}/cgi-bin"
echo "  ✓ 目录已创建"

# 上传 CGI 脚本
echo "[3/4] 上传 CGI 监控脚本..."
scp src/cgi/monitor "${USERNAME}@${DEVICE_IP}:${REMOTE_BASE}/cgi-bin/monitor"
ssh "${USERNAME}@${DEVICE_IP}" "chmod +x ${REMOTE_BASE}/cgi-bin/monitor"
echo "  ✓ CGI 脚本已部署"

# 上传前端页面
echo "[4/4] 上传前端页面..."
scp src/web/index.html "${USERNAME}@${DEVICE_IP}:${REMOTE_BASE}/admin/index.html"
echo "  ✓ 前端页面已部署"

echo ""
echo "=========================================="
echo "  部署完成!"
echo "=========================================="
echo ""
echo "访问地址: http://${DEVICE_IP}/admin/"
echo ""
