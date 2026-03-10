
今天的目标很明确：你要能一眼看懂 `ls -l` 的权限串，能用 `chmod/chown/chgrp/umask` 精准控制“谁能读/写/执行”，并且不被“为什么脚本不能跑”这类问题折磨。

---

## 1) 权限模型：三类人 × 三种能力

### 1.1 三类人（主体）

- **u**：user（文件所有者）
- **g**：group（文件所属组）
- **o**：others（其他人）
- **a**：all（u+g+o）
### 1.2 三种能力（动作）

- **r**：read 读
- **w**：write 写
- **x**：execute 执行 / 进入目录

---

## 2) `ls -l` 权限串：必须会读

例子：

```bash
-rwxr-x--- 1 alice dev  1234 Feb 11 10:00 run.sh
```

拆解：
- 第 1 位：类型
    - `-` 普通文件，`d` 目录，`l` 软链接    
- 后 9 位：`u g o` 三段，每段 3 位：`rwx`
    - `rwx` = 7，`rw-` = 6，`r-x` = 5，`r--` = 4，`---` = 0   

所以 `-rwxr-x---` 就是：
- u：`rwx` = 7
- g：`r-x` = 5
- o：`---` = 0  
    => **750**

---

## 3) chmod：改权限（符号法 & 数字法）

### 3.1 符号法（可读性强）

```bash
chmod u+x run.sh      # 给所有者加执行
chmod g-w file.txt    # 组去写
chmod o=r file.txt    # 其他人只读
chmod a+r file.txt    # 全部加读
chmod u=rwx,g=rx,o= file.txt
```

### 3.2 数字法（最常用）

```bash
chmod 644 file.txt    # u=rw g=r o=r
chmod 755 dir_or_bin  # u=rwx g=rx o=rx
chmod 600 id_rsa      # 私钥常见
chmod 700 ~/private   # 私人目录
```

---

## 4) 目录权限：x 的含义很“反直觉”但很关键

对**目录**：
- **r**：能列出目录内容（看到文件名）
- **x**：能进入目录 / 访问其中条目（“穿过门”）
- **w**：能在目录里创建/删除/重命名（通常还需要 x）
典型坑：
- 只有 `r` 没 `x`：你能“看到名单”，但进不去、也打不开里面的文件。
- 只有 `x` 没 `r`：你不知道里面有什么，但**如果你知道文件名**，可能仍能访问。

---
## 5) chown / chgrp：改所有者与组（带 -R 很危险）

```bash
sudo chown alice file.txt            # 改所有者
sudo chown alice:dev file.txt        # 同时改所有者+组
sudo chgrp dev file.txt              # 只改组
sudo chown -R alice:dev mydir        # 递归修改（慎用）
```

经验法则：**递归前先 `ls -l`/`find` 看清楚范围。**

---
## 6) umask：默认权限“遮罩”（新文件为啥不是 777？）

### 6.1 基本规则

- 新文件默认“理想值”是 **666**（不带 x）
- 新目录默认“理想值”是 **777**
- 实际权限 = 理想值 **减去** umask（更准确说是按位屏蔽）

查看：

```bash
umask
```

常见：
- `0022`：新文件 644，新目录 755（个人环境常见）
- `0002`：新文件 664，新目录 775（团队协作常见）

---

## 7) 今日必做练习（做完就真的掌握）

### 练习0：建立沙盒

```bash
mkdir -p ~/day5 && cd ~/day5
```

### 练习A：看权限、算数字

```bash
touch a.txt
mkdir d1
ls -ld a.txt d1
```

把输出里的权限串手算成三位数字（例如 644/755）。

### 练习B：脚本不能执行的经典修复

```bash
printf '#!/usr/bin/env bash\necho "hello"\n' > hi.sh
./hi.sh
```

你应该会得到 Permission denied。修复：

```bash
chmod u+x hi.sh
./hi.sh
```

### 练习C：目录 x 权限的“门”效应

```bash
mkdir secret
echo "TOP" > secret/t.txt
chmod 700 secret
```

尝试：

```bash
ls secret
cat secret/t.txt
```

然后把目录权限改为 `600`、`500`、`400` 分别试试（你会直观看到 r/x 的差异）。

### 练习D：用 umask 验证默认权限

```bash
umask
umask 0022
touch u1.txt && mkdir u1dir
ls -ld u1.txt u1dir
umask 0002
touch u2.txt && mkdir u2dir
ls -ld u2.txt u2dir
```

观察文件/目录权限如何变化。

---
下一天最合适的是：**进程与作业控制 + 服务管理（ps/top/jobs/kill/systemd）**。权限决定“能不能做”，进程决定“正在做什么、怎么停”。这俩合起来，你就开始像个真正的 Linux 使用者了。