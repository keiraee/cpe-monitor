# CPE Monitor

轻量级 CPE 设备监控面板，运行在 ImmortalWrt 系统上。

## 功能

- 系统状态监控（CPU、内存、存储）
- DHCP 租约查看
- WiFi 客户端连接状态
- 实时数据刷新

## 技术栈

- 前端：HTML5 + CSS3 + Vanilla JavaScript
- 后端：Shell CGI 脚本
- 服务器：uhttpd（ImmortalWrt 内置）

## 部署

```bash
# 复制文件到设备
scp src/cgi/monitor root@<设备IP>:/www/cgi-bin/monitor
scp src/web/index.html root@<设备IP>:/www/admin/index.html

# 设置权限
ssh root@<设备IP> "chmod +x /www/cgi-bin/monitor"
```

## 访问

```
http://<设备IP>/admin/
```

## 开发

- 作者：Keiraee
- 项目地址：cpe-monitor
