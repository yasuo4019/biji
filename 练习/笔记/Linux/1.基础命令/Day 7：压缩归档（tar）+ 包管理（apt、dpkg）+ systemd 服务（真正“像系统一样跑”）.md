
今天把 Linux 从“会用命令”升级到“会维护系统”。三块硬核工程常识：  
1）**归档/压缩**：打包、备份、发布  
2）**包管理**：安装、升级、锁版本、排错依赖  
3）**systemd**：让你的程序像服务一样开机自启、崩了自动拉起、日志可追踪

---

## 0）今日核心肌肉记忆（先记）

### tar / 压缩

- `tar -czf out.tar.gz dir/`
- `tar -xzf out.tar.gz -C /path/to/extract`
- `tar -tf out.tar.gz | head`
- `gzip -k file` / `gunzip file.gz`
### apt / dpkg

- `sudo apt update`
- `apt search xxx`
- `apt show pkg`
- `sudo apt install -y pkg`
- `apt list --installed | grep xxx`
- `dpkg -L pkg`（包装了哪些文件）
- `dpkg -S /path/file`（这个文件属于哪个包）
- `sudo apt remove pkg` / `sudo apt purge pkg`
- `sudo apt autoremove`
### systemd

- `systemctl status name`
- `systemctl start|stop|restart name`
- `systemctl enable --now name`
- `journalctl -u name -n 50 --no-pager`
- `systemctl daemon-reload`

---

## 1）归档与压缩：tar 是工程现场的“打包机”

### 1.1 tar 的关键点

- **tar** 本质是“归档”（把一堆文件串起来），压缩是可选的
- 常见组合：
    - `-c` 创建（create）
    - `-x` 解开（extract）
    - `-t` 列出内容（table）
    - `-f` 指定文件名（file）
    - `-z` gzip 压缩（.tar.gz / .tgz）
    - `-J` xz 压缩（.tar.xz，压得更小但更慢）

### 1.2 练习：打包你的 Day6 实验目录

```bash
mkdir -p ~/lab/day7 && cd ~/lab
tar -czf day6_backup_$(date +%F).tar.gz day6
tar -tf day6_backup_$(date +%F).tar.gz | head
mkdir -p ~/lab/day7/restore
tar -xzf day6_backup_$(date +%F).tar.gz -C ~/lab/day7/restore
ls -la ~/lab/day7/restore/day6
```

**你要得到的能力：**

- 看到一个 `.tar.gz` 你知道怎么先 `-t` 看里面有什么，再 `-x` 解出来
- 你能指定解压目录 `-C`

---

## 2）包管理：apt 是“可靠安装”，dpkg 是“定位证据”

### 2.1 apt 的基本套路

```bash
sudo apt update
apt search tree
apt show tree
sudo apt install -y tree
tree --version
```

检查包是否安装：

```bash
apt list --installed | grep -E '^tree/'
```

### 2.2 dpkg：查“这个包装了啥/这个文件属于谁”

列出 `tree` 安装了哪些文件：

```bash
dpkg -L tree | head -n 30
```

反查某个可执行文件来自哪个包：

```bash
which tree
dpkg -S "$(which tree)"
```

### 2.3 卸载的两种力度

- `remove`：删程序但保留配置
- `purge`：连配置一起删（更干净）

```bash
sudo apt remove -y tree
sudo apt purge -y tree
sudo apt autoremove -y
```

**工程建议（非常实用）：**

- 系统出问题时别急着“重装”，先用 `dpkg -S` / `dpkg -L` 找证据链
- 尽量用 apt，不要到处下载来历不明的 `.deb`

---

## 3）systemd：把脚本变成“服务”，带日志、可自启、可重启

### 3.1 我们做一个最小服务：每 2 秒写一行日志

先写程序（用 bash，零依赖）：

```bash
mkdir -p ~/lab/day7/svc && cd ~/lab/day7/svc
cat > hello_service.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

while true; do
  echo "$(date -Is) hello from systemd service, pid=$$"
  sleep 2
done
EOF

chmod +x hello_service.sh
./hello_service.sh | head
```

`Ctrl+C` 停掉。

### 3.2 写 systemd unit（用户级服务：不碰 sudo，更安全）

用户级 unit 放这里：

```bash
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/hello.service <<'EOF'
[Unit]
Description=Hello demo service (user)

[Service]
Type=simple
ExecStart=%h/lab/day7/svc/hello_service.sh
Restart=always
RestartSec=1

[Install]
WantedBy=default.target
EOF
```

加载并启动：

```bash
systemctl --user daemon-reload
systemctl --user start hello.service
systemctl --user status hello.service --no-pager
```

看日志（关键能力）：

```bash
journalctl --user -u hello.service -n 30 --no-pager
```

设置“登录时自动启动”：

```bash
systemctl --user enable --now hello.service
systemctl --user is-enabled hello.service
```

停止/禁用：

```bash
systemctl --user stop hello.service
systemctl --user disable hello.service
```

### 3.3 重点理解（别背概念，抓住工程意义）

- `ExecStart=`：服务启动命令（写绝对路径更稳）
- `Restart=always`：崩了自动拉起（生产常用）
- `journalctl`：统一日志入口，比“自己写 log 文件”可控得多

---

## 4）今日排错套路（systemd 版）

当服务“起不来/起了又死/没输出”：

1. `systemctl --user status hello.service --no-pager` 看 Exit code
2. `journalctl --user -u hello.service -n 100 --no-pager` 看真实错误
3. 改完 unit 后必须：`systemctl --user daemon-reload`
4. 再：`systemctl --user restart hello.service`

---

## 5）作业（20–30 分钟，明天会复用）

### 作业 A：把 Day6 的 `net_check.sh` 做成 systemd 服务

目标：每 60 秒运行一次，把输出写到 journal。

提示：可以把 `hello_service.sh` 改成：

- 每次运行 `~/lab/day6/net_check.sh`
- `sleep 60`

然后做成 `netcheck.service`。

### 作业 B：归档你的服务目录并验证可恢复

- `tar -czf day7_svc_$(date +%F).tar.gz ~/lab/day7/svc`
- 解压到 `~/lab/day7/restore2/`，确认脚本权限还在（或你能补回来）

---

## Day8 预告

下一天进入“文本处理进阶 + 日志分析”：`grep/sed/awk` 的组合技，外加 `journalctl` 的过滤、时间范围、跟随输出。你会开始像做故障定位那样读系统日志，而不是靠直觉乱猜。