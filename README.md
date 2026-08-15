# CMonitor

跑在 ImmortalWrt 上的轻量 CPE 监控面板。面向 Nradio C8-660 一类设备，不装额外软件包，用系统自带的 `uhttpd`、`ubus`、`iwinfo`、`jsonfilter`。

## 功能

- 运行时间、CPU 负载（1/5/15 分钟）、内存、存储、conntrack 连接数
- WiFi 网络（SSID、接口、信道）
- DHCP 租约（主机名、IP、MAC）
- WiFi 客户端（主机名、信号、收发速率）
- 蜂窝网络（制式、质量、RSSI/RSRQ/SINR 等，读取 `/tmp/cpe_cell.file`）
- 可调自动刷新；页面切到后台时暂停

## 访问

部署完成后打开：

```
http://<设备IP>/cmonitor/
```

数据接口：

```
GET /cgi-bin/cmonitor
```

返回 JSON。页面和 CGI 是同源请求，不依赖外网（无 Google Fonts）。

## 设备上安装（推荐）

SSH 登录路由器后执行：

```sh
curl -fsSL https://raw.githubusercontent.com/keiraee/cpe-monitor/master/scripts/cm.sh -o /usr/bin/cm
chmod +x /usr/bin/cm
cm
```

没有 `curl` 时用 `wget`：

```sh
wget -O /usr/bin/cm https://raw.githubusercontent.com/keiraee/cpe-monitor/master/scripts/cm.sh
chmod +x /usr/bin/cm
cm
```

菜单里选 **1) 安装**。之后可以用同一个 `cm` 更新、卸载或调试 CGI。

安装落盘位置：

| 文件 | 路径 |
|------|------|
| CGI | `/www/cgi-bin/cmonitor`（需可执行） |
| 页面 | `/www/cmonitor/index.html` |

## 从电脑部署

在仓库根目录、能 SSH 到设备的环境里：

```sh
./scripts/deploy.sh <设备IP>
# 默认用户 root，等价于：
./scripts/deploy.sh 192.168.1.1 root
```

脚本会创建目录、上传上述两个文件并 `chmod +x` CGI。Windows 上若 `ping -c` 不可用，可直接 `scp`：

```sh
ssh root@<设备IP> "mkdir -p /www/cmonitor /www/cgi-bin"
scp src/cgi/cmonitor root@<设备IP>:/www/cgi-bin/cmonitor
scp src/web/index.html root@<设备IP>:/www/cmonitor/index.html
ssh root@<设备IP> "chmod +x /www/cgi-bin/cmonitor"
```

## 要求

- ImmortalWrt 21.02 及相近 OpenWrt（uhttpd 已开启 CGI）
- 设备命令：`sh`、`awk`、`sed`、`ubus`、`jsonfilter`、`iwinfo`（无线）、`df`
- 仅局域网使用，面板本身不带登录认证
- 内存按 `/proc/meminfo` 的 `MemAvailable` 计算；没有该字段时回退到 Free+Buffers+Cached

## 仓库结构

```
cpe-monitor/
├── src/cgi/cmonitor     # CGI，采集数据并输出 JSON
├── src/web/index.html   # 单页前端
├── scripts/cm.sh        # 设备端安装/更新/卸载/调试
├── scripts/deploy.sh    # 从电脑 scp 部署
├── scripts/test.sh      # 本地静态检查
└── docs/                # PLAN.md、ARCHITECTURE.md
```

## 本地检查

```sh
./scripts/test.sh
```

## 许可证与作者

Keiraee · [keiraee/cpe-monitor](https://github.com/keiraee/cpe-monitor)
