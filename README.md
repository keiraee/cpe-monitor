# CPE Monitor

轻量级 CPE 设备监控面板，运行在 ImmortalWrt 系统上。

## 功能

- 系统状态监控（CPU、内存、存储）
- DHCP 租约查看
- WiFi 客户端连接状态
- 蜂窝网络信号
- 实时数据刷新

## 技术栈

- 前端：HTML5 + CSS3 + Vanilla JavaScript
- 后端：Shell CGI 脚本
- 服务器：uhttpd（ImmortalWrt 内置）

## 部署

```bash
# 复制文件到设备
scp src/cgi/cmonitor root@<设备IP>:/www/cgi-bin/cmonitor
scp src/web/index.html root@<设备IP>:/www/cmonitor/index.html

# 设置权限
ssh root@<设备IP> "chmod +x /www/cgi-bin/cmonitor"
```

也可在设备上运行 `scripts/cm.sh` 或 `scripts/deploy.sh <设备IP>`。

## 访问

```
http://<设备IP>/cmonitor/
```

## 开发

- 作者：Keiraee
- 项目地址：cpe-monitor
