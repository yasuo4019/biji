
你前 1–5 天把命令行、管道重定向、权限/所有权这些“底座”练得差不多了。第 6 天我们把 Linux 真正用起来：**让机器上网、看端口、远程登录、抓文件、定位“为啥连不上”。**

> 目标：你能独立回答并操作  
> 1）“我这台 Ubuntu 的 IP/网关/DNS 是啥？”  
> 2）“某服务到底有没有在监听端口？”  
> 3）“我怎么用 SSH 远程连进去，并用 key 免密？”  
> 4）“我怎么可靠地下载/调接口，定位网络问题？”

---

## 0）今日核心肌肉记忆（先抄到笔记里）

### 网络信息与连通性

- `ip a` / `ip r`
- `ping -c 4 1.1.1.1`
- `ping -c 4 google.com`
- `resolvectl status` （Ubuntu 24.04 常用）
- `ss -lntp` / `ss -lunp`
- `curl -I https://example.com`
- `curl -s https://example.com | head`
- `wget -O file https://...`

### 远程（SSH）

- `ssh user@host`
- `ssh -p 2222 user@host`
- `ssh-keygen -t ed25519`
- `ssh-copy-id user@host`
- `scp file user@host:/path/`
- `sftp user@host`

---

## 1）10 分钟概念（只讲够用的）

- **IP / 路由 / DNS 是三件事**
    - IP/网关：决定“能不能到外网/别的网段”
    - DNS：决定“域名能不能解析成 IP”
    - 所以你要分两步测：先 ping IP，再 ping 域名
- **端口监听 ≠ 服务可用，但监听都没有那一定不行**
    - `ss -lntp` 看 TCP 监听
    - `ss -lunp` 看 UDP 监听
- **SSH 的安全核心：禁密码、用 key**
    - key 更安全、也更工程化（可审计、可撤销、可分发）
---

## 2）30 分钟动手：3 个小任务（按顺序做）

### 任务 A：搞清楚你这台 VM 的网络“画像”

在 Ubuntu 里跑：

```bash
ip a
ip r
resolvectl status
```

你要能从输出里读出：

- 你的网卡名（常见 `ens33`/`ens160`）
- 你的 IPv4 地址（比如 `192.168.x.x/24`）
- 默认路由（`default via ...`)
- DNS 服务器地址

**快速自测：**

```bash
ping -c 4 1.1.1.1
ping -c 4 google.com
```

- 只通 1.1.1.1：大概率 DNS 问题
- 俩都不通：大概率路由/网卡/VMware 网络模式问题
- 都通：网络底层 OK

---

### 任务 B：用 `ss` 看端口，验证“服务到底在不在”

先看系统现在有哪些 TCP 端口在监听：

```bash
ss -lntp
```

找一个你认识的（比如你安装过的东西，或之后你会装的 ssh）。  
然后做一个简单实验：用 Python 临时起个 HTTP 服务（不需要装新软件）：

```bash
mkdir -p ~/lab/day6 && cd ~/lab/day6
python3 -m http.server 8000
```

另开一个终端，验证监听与访问：

```bash
ss -lntp | grep 8000
curl -I http://127.0.0.1:8000
```

你应该看到：

- `ss` 里出现 `:8000` 的监听
- `curl -I` 返回 `HTTP/1.0 200 OK` 之类的响应头

停止服务：回到第一个终端 `Ctrl+C`

> 这个“ss + curl”组合，是 Linux 排障里超高频的瑞士军刀。

---

### 任务 C：装好 SSH 服务并从“同机”连一次（闭环）

Ubuntu 上装 OpenSSH Server：

```bash
sudo apt update
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
systemctl status ssh --no-pager
```

确认 22 端口监听：

```bash
ss -lntp | grep ':22'
```

先做“本机连本机”练手（这一步很关键，能把网络问题隔离掉）：

```bash
ssh localhost
```

首次会问指纹，输入 `yes`。然后输入你的用户密码登录。

---

## 3）进阶（但仍是工程必备）：SSH key 免密 + 更安全

生成 key（推荐 ed25519）：

```bash
ssh-keygen -t ed25519
```

一路回车即可（可选设置 passphrase）。

把公钥装到目标机器（这里目标先用 localhost）：

```bash
ssh-copy-id localhost
```

再试：

```bash
ssh localhost
```

成功的话就不再要密码（如果你给 key 设置了 passphrase，会要你输入 passphrase；可配合 ssh-agent，这里先不展开）。

**把 SSH 变得更安全（了解即可，别乱改远程生产机）**  
编辑：

```bash
sudo vim /etc/ssh/sshd_config
```

常见安全项：

- `PasswordAuthentication no`（用 key 后再关）
- `PermitRootLogin no`

改完重启：

```bash
sudo systemctl restart ssh
```

---

## 4）今日小结（写进 `~/notes/linux.md` 的模板）

你可以按这个结构记：

- 今日主题：网络/SSH/端口排错
- 核心命令：`ip a`, `ip r`, `resolvectl status`, `ping`, `ss -lntp`, `curl`, `wget`, `ssh`, `ssh-keygen`, `ssh-copy-id`
- 排错套路：
    1. ping IP（判断路由/链路）
    2. ping 域名（判断 DNS）
    3. ss 看监听（判断服务是否启动）
    4. curl 请求本机（判断应用层是否通）
- 踩坑：
    - DNS 正常不代表路由正常，反过来也一样
    - `ss` 比 `netstat` 更现代（你也装了 net-tools，但优先 ss）
---

## 5）作业（15 分钟，明天 Day7 用得上）

1. 在 `~/lab/day6/` 写一个 `net_check.sh`（可执行）脚本，依次输出：
    - 本机 IPv4（从 `ip a` 里提取）
    - 默认路由（`ip r`）
    - DNS（`resolvectl status` 里挑关键行）
    - ping 1.1.1.1 结果（成功/失败即可）
    - ping google.com 结果
    - 22 端口是否监听（监听就输出 `ssh listening`）
2. 用 `chmod +x net_check.sh` 赋执行权限并跑一遍。
---

## Day7 预告

下一天会把“文件管理”升级成“工程级管理”：**压缩/解压（tar/gzip）、包管理（apt）、以及用 systemd 写一个你自己的服务（真正像个系统一样跑）**。你会开始把 Linux 当作“可部署的系统”，而不是“命令合集”。