
目标很明确：**能在终端里熟练移动、创建、查看、复制、删除文件**，并且开始习惯 `man` 和管道 `|` 的思维。

---

## 0) 打开终端 + 做一次“系统自检”

在 Ubuntu 里打开 Terminal（快捷键一般是 `Ctrl+Alt+T`），依次执行：

```bash
whoami
pwd
uname -a
lsb_release -a
```

你应该能看懂这些输出大概在说什么：当前用户、当前目录、内核信息、发行版信息。

---

## 1) 建立你的“练功场”

我们今天所有练习都在一个目录里完成，避免污染系统：

```bash
mkdir -p ~/lab/day1
cd ~/lab/day1
pwd
```

---

## 2) 文件与目录：创建、查看、复制、移动、删除

### 2.1 创建结构

```bash
mkdir docs src logs
touch docs/readme.txt src/main.c logs/app.log
ls
ls -l
tree
```

要点：

- `ls -l` 看到权限、大小、时间
- `tree` 能直观看目录结构

### 2.2 写点内容（用重定向）

```bash
echo "hello linux" > docs/readme.txt
echo "line2" >> docs/readme.txt
cat docs/readme.txt
```

要点：

- `>` 覆盖写入
- `>>` 追加写入

### 2.3 复制/移动/删除（小心 rm）

```bash
cp docs/readme.txt docs/readme.bak
mv src/main.c src/hello.c
rm docs/readme.bak
```

再确认一下：

```bash
ls -R
```

---

## 3) 查看内容：用 less（比 cat 更适合长文本）

先制造一个稍微长点的文件：

```bash
seq 1 200 > logs/numbers.txt
less logs/numbers.txt
```

在 `less` 里：

- `j/k` 或上下键滚动
- `/50` 搜索“50”
- `n` 下一个匹配
- `q` 退出

---

## 4) 搜索：grep + find（非常核心）

### 4.1 grep：在文件内容里找

```bash
echo "error: something bad" >> logs/app.log
echo "info: ok" >> logs/app.log
echo "error: disk full" >> logs/app.log

grep "error" logs/app.log
grep -n "error" logs/app.log
```

### 4.2 find：按条件找文件

```bash
find . -type f
find . -type f -name "*.txt"
```

---

## 5) 管道思维：把工具串起来（Linux 的魔法）

统计 app.log 里 error 有多少行：

```bash
grep -n "error" logs/app.log | wc -l
```

再来一个：把 numbers.txt 中包含“1”的行找出来，并只看前 5 行：

```bash
grep "1" logs/numbers.txt | head -n 5
```

---

## 6) 帮助系统：man / --help（别背命令，学会查）

练习三次：

```bash
man ls
ls --help | head
man grep
```

你要形成条件反射：**不确定就查 man**。

---

## Day 1 结业小任务（10分钟）

你在 `~/lab/day1` 里完成下面要求（全用命令行）：

1. 新建目录 `data`，里面创建 3 个文件：`a.txt b.txt c.txt`
2. 在 `a.txt` 里写 5 行，其中至少 2 行包含单词 `CAN`
3. 用一条命令统计 `a.txt` 里包含 `CAN` 的行数
4. 用 `find` 找出当前目录下所有 `.txt` 文件
5. 把 `a.txt` 复制为 `a.bak`，然后删除 `a.bak`

---

## 你今天应该记住的“核心肌肉记忆”

`cd / ls -l / mkdir / touch / cp / mv / rm / cat / less / grep / find / | / > >> / man`