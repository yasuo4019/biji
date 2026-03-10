
目标：你能回答三件事——

1. **现在系统在跑什么？**（进程）
2. **某个服务是不是正常？**（systemd 服务）
3. **出问题去哪里看证据？**（日志）

---

## 1) 进程：你电脑里正在跑的“活物”

### 1.1 看自己的进程（最安全的起步）

```bash
ps
ps -f
```

### 1.2 看全系统进程（常用）

```bash
ps aux | head
```

你会看到：USER、PID、%CPU、%MEM、COMMAND 等。

### 1.3 交互式查看：top / htop

```bash
top
```

- `q` 退出
- `P` 按 CPU 排序（大写 P）
- `M` 按内存排序

如果你装了 htop（Day1 推荐过）：

```bash
htop
```

更直观，能直接选择进程并 kill。

---

## 2) “前台/后台/作业控制”：终端里的小宇宙

### 2.1 前台跑一个占用终端的命令

```bash
sleep 100
```

此时终端被占用。按 `Ctrl+C` 终止。

### 2.2 放到后台跑

```bash
sleep 100 &
jobs
```

### 2.3 把后台任务拉回前台/再放回后台

```bash
fg %1
# 然后按 Ctrl+Z 暂停
bg %1
jobs
```

这一套在调试、跑临时任务时很好用。

---

## 3) kill：结束进程（别乱杀，讲逻辑）

先造一个“可被杀”的进程：

```bash
sleep 1000 &
ps aux | grep sleep
```

你会看到 `sleep` 的 PID。

### 3.1 温柔结束（推荐）

```bash
kill <PID>
```

### 3.2 不听话再强制（最后手段）

```bash
kill -9 <PID>
```

也可以按名字杀（谨慎，可能误伤同名进程）：

```bash
pkill sleep
```

---

## 4) 服务：systemd 管家（Ubuntu 24.04 默认）

服务和“普通进程”不一样：它有“生命周期”、有“开机自启”、有“状态机”。

### 4.1 看一个服务状态（示例：SSH 服务可能没装）

先用一个必然存在的：`systemd-journald` 或 `cron`（Ubuntu 上常见是 `cron`）

```bash
systemctl status cron
```

如果显示“Unit cron.service could not be found”，说明没装；那就换：

```bash
systemctl status systemd-journald
```

### 4.2 启停/重启（理解即可，别乱动关键服务）

```bash
sudo systemctl restart cron
sudo systemctl stop cron
sudo systemctl start cron
```

### 4.3 开机自启

```bash
sudo systemctl enable cron
sudo systemctl disable cron
```

---

## 5) 日志：证据在哪（journalctl / dmesg）

Linux 排障的核心：**不要猜，去看证据**。

### 5.1 查看系统日志（最近的）

```bash
journalctl -e
```

- `-e` 直接跳到末尾（最新）
- 在里面用 `/关键词` 搜索，`n` 下一个，`q` 退出

### 5.2 只看本次启动（很实用）

```bash
journalctl -b -e
```

### 5.3 看某个服务的日志

```bash
journalctl -u cron -e
```

### 5.4 实时跟踪日志（像 tail -f）

```bash
journalctl -f
```

### 5.5 内核日志（硬件、驱动、USB、网卡等）

```bash
dmesg -T | tail -n 50
```

---

## 6) Day 3 “排障套路”（你要养成条件反射）

当你遇到“某功能不正常”时，按这个顺序走：

1. **现象**：报错原文是什么？（别凭感觉）
2. **对象**：是某进程？某服务？还是系统层（内核/驱动）？
3. **状态**：
    - 服务：`systemctl status xxx`
    - 进程：`ps aux | grep xxx` / `top`
4. **证据**：
    - 服务日志：`journalctl -u xxx -e`
    - 系统日志：`journalctl -b -e`
    - 内核：`dmesg -T | tail`

---

## Day 3 结业小任务（20分钟，必须动手）

在终端完成并能解释结果：

### 任务 A：进程与 kill

1. 启动一个后台进程：

```bash
sleep 999 &
```

2. 用 `ps` 找到它的 PID（提示：`ps aux | grep sleep`）
3. 用 `kill PID` 结束它
4. 再用 `ps` 验证它确实没了

### 任务 B：服务与日志

1. 找一个存在的服务（优先 `cron`，不行就 `systemd-journald`）：

```bash
systemctl status cron
```

2. 查看该服务日志最后 30 行（两种做法任选其一）：

```bash
journalctl -u cron -n 30
# 或
journalctl -u cron -e
```

3. 用 `/` 在日志里搜索一个关键词（比如 `error` 或服务名）

### 任务 C：内核日志

1. 插拔一次 USB（U 盘/鼠标都行）或切换网络（断开再连上）
2. 立刻执行：

```bash
dmesg -T | tail -n 30
```

3. 找出你刚才动作对应的日志行（通常会出现 usb / network / link / device 等字样）

---

## Day 3 核心肌肉记忆（今天你要记住这些）

- 进程：`ps aux` `top/htop` `kill` `pkill`
- 作业控制：`&` `jobs` `fg` `bg` `Ctrl+C` `Ctrl+Z`
- 服务：`systemctl status/start/stop/restart/enable`
- 日志：`journalctl -b -e` `journalctl -u xxx -e` `journalctl -f` `dmesg -T`