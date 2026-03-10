
目标：你看见一条 `-rw-r--r--` 或 `drwxr-x---` 时，能**立刻知道谁能干什么**；知道什么时候用 `sudo`；能用最小权限把事情办了。

---

## 1) 先复习一个现实：为什么权限这么重要

Linux 是多用户系统：同一台机器上不同用户、不同服务都在跑。权限就是它的“物理定律”。

---

## 2) 权限长什么样：`ls -l` 的三段结构

进入你的练功场（沿用 Day1）：

```bash
cd ~/lab/day1
ls -l
```

你会看到类似：

```
-rw-r--r-- 1 user user  ...  readme.txt
drwxr-xr-x 2 user user  ...  docs
```

关键：权限是三段 **(u/g/o)**

- `u`：owner（文件所有者）
- `g`：group（所属组）
- `o`：others（其他所有人）

每段三位：`r`(读) `w`(写) `x`(执行/进入目录)

---

## 3) 目录权限 vs 文件权限（非常容易踩坑）

### 文件的 r/w/x

- `r`：能读内容
- `w`：能改内容
- `x`：能执行（当作程序/脚本运行）
### 目录的 r/w/x（重点）

- `r`：能列出目录内容（配合 `x` 才真正有用）
- `x`：能“进入”目录、访问里面已知名字的文件
- `w`：能在目录里创建/删除/重命名条目（文件名这个层面的操作）

一个很反直觉的点：**删文件看的是“目录写权限”，不是文件写权限**。

---

## 4) chmod：改权限（符号法 + 数字法）

先造一个文件来练：

```bash
cd ~/lab/day1
echo "echo hello" > run.sh
ls -l run.sh
```

### 4.1 尝试执行（会失败）

```bash
./run.sh
```

因为缺少执行位 `x`。

### 4.2 给执行权限（符号法）

```bash
chmod +x run.sh
ls -l run.sh
./run.sh
```

### 4.3 符号法精确控制

- 只给自己执行：
```bash
chmod u+x run.sh
```
- 去掉其他人的写：

```bash
chmod o-w run.sh
```

### 4.4 数字法（常用）

数字=位掩码：`r=4, w=2, x=1`

- `755`：`rwx r-x r-x`（程序常用）
- `644`：`rw- r-- r--`（文本常用）

试一下：

```bash
chmod 644 run.sh
ls -l run.sh
chmod 755 run.sh
ls -l run.sh
```

---

## 5) 所有者与组：`chown / chgrp`

先看看你是谁、你的组是谁：

```bash
whoami
id
```

理解输出：你会看到 `uid` `gid` 以及你属于哪些组。

> 在你当前 VM 里，你大概率只会对自己目录有写权限，系统目录（如 `/etc`）需要 root。

`chown`/`chgrp` 通常要 `sudo`，先知道它们干什么：

- 改所有者：`sudo chown user:file file`
- 改组：`sudo chgrp group file`

暂时先不强行改（避免把系统搞花），后面我们会在“创建新用户”时系统化练一遍。

---

## 6) sudo：临时获得 root 权限（但要克制）

### 6.1 看看权限不足是什么样

试图去写系统目录（会失败）：

```bash
echo "test" > /etc/day2_test.conf
```

你会得到 “Permission denied”。

### 6.2 用 sudo 正确写入（常见坑：重定向）

很多人会写：

```bash
sudo echo "test" > /etc/day2_test.conf
```

这**通常还是失败**，因为 `>` 是你的 shell 执行的，不是 `sudo` 提权的那部分。

正确写法之一：

```bash
echo "test" | sudo tee /etc/day2_test.conf > /dev/null
```

检查：

```bash
cat /etc/day2_test.conf
```

---

## 7) umask：默认权限从哪来（了解即可）

创建文件时默认不是 666/777，而会被 umask “扣掉”一些位：

```bash
umask
```

你现在先记住：**默认文件一般 644，目录一般 755**（常见情况）。

---

## Day 2 结业小任务（15~20分钟）

在 `~/lab/day1` 里完成：

1. 创建目录 `secure` 和文件 `secure/secret.txt`

```bash
mkdir -p secure
echo "top secret" > secure/secret.txt
```

2. 把 `secure` 权限设成 **只有自己能进入和查看**（别人完全进不去）  
   提示：目录至少要 `x` 才能进入。推荐权限：`700`

```bash
chmod 700 secure
```

3. 把 `secure/secret.txt` 设成 **只有自己可读写**  
   推荐：`600`

```bash
chmod 600 secure/secret.txt
```

4. 用 `ls -l` 验证权限，并解释你看到的三段权限是什么意思（u/g/o）

5. 用正确方式在 `/etc` 下创建 `day2_note.conf`，内容写入 `learned permissions`  
   （用 `tee`，别踩重定向坑）

```bash
echo "learned permissions" | sudo tee /etc/day2_note.conf > /dev/null
```

---

## Day 2 你应该形成的“规则直觉”

- 文件权限管读写执行，目录权限管“能不能进、能不能列出、能不能改目录结构”
- `chmod` 会用：符号法 + 数字法
- 需要系统权限时用 `sudo`，但别滥用
- 重定向写系统文件要用 `tee`（这个坑很经典）
