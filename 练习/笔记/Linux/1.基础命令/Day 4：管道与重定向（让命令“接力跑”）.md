
今天的核心目标：把“一个命令干完”的思维升级为“多个命令串起来干活”。你会学会三件神器：**重定向**、**管道**、**文本筛选/处理**。这三件一掌握，Linux 日常效率会直接起飞。

---

## 1) 今日核心肌肉记忆（必须背到手会动）

### 1.1 标准输入/输出/错误（stdin/stdout/stderr）

- `stdout`：正常输出（文件描述符 **1**）
- `stderr`：错误输出（文件描述符 **2**）

### 1.2 重定向

|目的|写法|备注|
|---|---|---|
|覆盖写入文件|`cmd > out.txt`|没有就创建|
|追加写入文件|`cmd >> out.txt`|不覆盖|
|读取文件作为输入|`cmd < in.txt`|stdin来自文件|
|丢弃输出|`cmd > /dev/null`|黑洞|
|丢弃错误|`cmd 2> /dev/null`|只丢错误|
|同时丢弃输出+错误|`cmd > /dev/null 2>&1`|经典组合|
|合并输出与错误到同一文件|`cmd > all.log 2>&1`|注意顺序|

**顺序很重要**：`2>&1` 是“让 stderr 跟随当前 stdout 的去向”，所以通常写在最后。

---

## 2) 管道（pipe）：让命令接力

### 2.1 最重要的一句话

`A | B`：把 **A 的输出** 作为 **B 的输入**。

例子：

```bash
ls -l | less
dmesg | less
```

---

## 3) 今日三大文本工具：grep / sort / uniq / wc / head / tail / cut / tr

### 3.1 grep：筛选（像“文本版雷达”）

```bash
grep "usb" /var/log/syslog
grep -n "error" some.log        # 带行号
grep -i "error" some.log        # 忽略大小写
grep -v "debug" some.log        # 反选（排除）
grep -E "err|fail|warn" some.log # 扩展正则（OR）
```

### 3.2 sort / uniq：排序与去重统计

> `uniq` 只能去掉“相邻重复”，所以常配 `sort` 使用

```bash
cat access.log | sort | uniq -c | sort -nr | head
```

### 3.3 wc：计数（行/词/字节）

```bash
wc -l file.txt   # 行数
wc -w file.txt   # 单词数
wc -c file.txt   # 字节数
```

### 3.4 head / tail：看开头结尾

```bash
head -n 20 file.txt
tail -n 50 file.txt
tail -f app.log   # 跟踪增长（看实时日志）
```

### 3.5 cut：按列切

```bash
cut -d ':' -f1 /etc/passwd   # 以:分隔取第1列
```

### 3.6 tr：字符替换/删除

```bash
echo "a,b,c" | tr ',' '\n'
```

---

## 4) 今日必做练习（30～45分钟，做完就算过关）

### 练习A：建立练习环境（建议照做）

```bash
mkdir -p ~/day4 && cd ~/day4
printf "alpha\nbeta\ngamma\nbeta\nALPHA\nerror: a\nwarn: b\ndebug: c\n" > demo.txt
```

### 练习B：重定向掌握

1. 把 `ls -l` 输出写入文件：

```bash
ls -l > ls.txt
```

2. 再追加一行时间：

```bash
date >> ls.txt
```

3. 故意制造错误，并把错误输出保存：

```bash
ls not_exist 2> err.txt
```

4. 同时保存输出和错误：

```bash
( ls -l; ls not_exist ) > all.txt 2>&1
```

### 练习C：管道与筛选

1. 统计 `demo.txt` 中包含 `beta` 的行数：

```bash
grep -n "beta" demo.txt
grep "beta" demo.txt | wc -l
```

2. 忽略大小写找 `alpha`：

```bash
grep -i "alpha" demo.txt
```

3. 排除 `debug` 行：

```bash
grep -v "debug" demo.txt
```

### 练习D：排序 + 去重统计（高频套路）

统计 `demo.txt` 各行出现次数并按次数降序：

```bash
sort demo.txt | uniq -c | sort -nr
```

### 练习E：切列（/etc/passwd）

列出系统所有用户名（只取第一列）并看前10个：

```bash
cut -d ':' -f1 /etc/passwd | head
```

---

## 5) 今日小结（你应该达到的“手感”）

- 能解释 `>`, `>>`, `2>`, `2>&1` 的区别，并能用对顺序
- 能用 `|` 把两个以上命令串起来完成一个“数据处理链”
- 会用 `grep` 找、排除、忽略大小写；会用 `sort | uniq -c | sort -nr` 做简单统计
- 会用 `tail -f` 看日志增长（以后调试必备）

---

下一步的自然延伸是 **权限与所有权的进阶（chmod/chown 的组合拳）** 或者 **进程与作业控制（ps/top/jobs/nohup）**。这俩会把你从“会用命令”推进到“能掌控系统状态”。