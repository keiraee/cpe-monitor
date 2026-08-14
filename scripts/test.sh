#!/bin/sh
# CPE Monitor 本地测试脚本
# 用法: ./scripts/test.sh

set -e

echo "=========================================="
echo "  CPE Monitor 本地测试"
echo "=========================================="
echo ""

PASS=0
FAIL=0

# 测试函数
test_pass() {
  echo "  ✓ $1"
  PASS=$((PASS + 1))
}

test_fail() {
  echo "  ✗ $1"
  FAIL=$((FAIL + 1))
}

# ========== 文件结构测试 ==========
echo "[测试] 文件结构"

if [ -f "src/cgi/monitor" ]; then
  test_pass "CGI 脚本存在"
else
  test_fail "CGI 脚本不存在"
fi

if [ -f "src/web/index.html" ]; then
  test_pass "前端页面存在"
else
  test_fail "前端页面不存在"
fi

if [ -x "src/cgi/monitor" ]; then
  test_pass "CGI 脚本可执行"
else
  test_fail "CGI 脚本不可执行 (需要 chmod +x)"
fi

# ========== Shell 语法测试 ==========
echo ""
echo "[测试] Shell 语法检查"

if command -v sh > /dev/null 2>&1; then
  if sh -n src/cgi/monitor 2>/dev/null; then
    test_pass "CGI 脚本语法正确"
  else
    test_fail "CGI 脚本语法错误"
  fi
else
  echo "  - 跳过: sh 不可用"
fi

# ========== HTML 语法测试 ==========
echo ""
echo "[测试] HTML 基本检查"

if grep -q "<!DOCTYPE html>" src/web/index.html; then
  test_pass "HTML 声明正确"
else
  test_fail "缺少 HTML 声明"
fi

if grep -q "</html>" src/web/index/index.html; then
  test_pass "HTML 标签闭合"
else
  test_fail "HTML 标签未闭合"
fi

if grep -q "cgi-bin/monitor" src/web/index.html; then
  test_pass "API 地址正确引用"
else
  test_fail "未找到 API 地址引用"
fi

# ========== CGI 输出测试 ==========
echo ""
echo "[测试] CGI 脚本输出"

# 在 WSL 中测试 CGI 脚本
if command -v sh > /dev/null 2>&1; then
  OUTPUT=$(sh src/cgi/monitor 2>/dev/null | grep -v "Content-Type" | grep -v "Access-Control" | grep -v "Cache-Control" | head -1)
  
  if echo "$OUTPUT" | grep -q "{"; then
    test_pass "CGI 输出包含 JSON"
  else
    test_fail "CGI 输出不包含 JSON"
  fi
  
  if echo "$OUTPUT" | grep -q "uptime"; then
    test_pass "JSON 包含 uptime 字段"
  else
    test_fail "JSON 缺少 uptime 字段"
  fi
  
  if echo "$OUTPUT" | grep -q "mem"; then
    test_pass "JSON 包含 mem 字段"
  else
    test_fail "JSON 缺少 mem 字段"
  fi
  
  if echo "$OUTPUT" | grep -q "leases"; then
    test_pass "JSON 包含 leases 字段"
  else
    test_fail "JSON 缺少 leases 字段"
  fi
else
  echo "  - 跳过: sh 不可用"
fi

# ========== 结果汇总 ==========
echo ""
echo "=========================================="
echo "  测试结果"
echo "=========================================="
echo ""
echo "通过: $PASS"
echo "失败: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "所有测试通过! ✓"
  exit 0
else
  echo "存在失败的测试! ✗"
  exit 1
fi
