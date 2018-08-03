---
 layout: post
 title: Linux_Shell_Cheated_sheet
 date: 2017-09-26 07:02:52
 categories: linux
 tags: [linux]
---

# 命令行快捷键

## 光标移动
- `ctrl + a`: 移动光标到行首
- `ctrl + e`: 移动光标到行尾
- `ctrl + b`: 光标向前移动一个字符
- `ctrl + f`: 光标向后移动一个字符
- `alt + b`: 光标向前移动一个单词
- `alt + f`: 光标向后移动一个单词

## 命令编辑
- `ctrl + p`: 上一条命令, 等同于方向上键
- `ctrl + n`: 下一条命令, 等同于方向下键
- `ctrl + h`: 向前删除一个字符
- `ctrl + d`: 向后删除一个字符
- `ctrl + w`: 向前剪切/删除一个单词(以空格为分届)
- `alt + d`: 向后剪切/删除一个单词
- `ctrl + u`: 剪切/删除当前光标到行首的内容
- `ctrl + k`: 剪切/删除当前光标到行尾的内容
- `ctrl + y`: 在光标出粘贴上面可以剪切的命令所剪切的内容
- `ctrl + _`: 撤销之前的操作
- `ctrl + xx`: 行首位置和当前光标位置切换

## 历史命令

- `ctrl + r`: 历史命令查询
- `!!`: 执行上一条命令
- `!+历史命令序号`: 执行这条指令, 结合history用

## 进程控制

- `ctrl + z`: 将当前任务退到后台执行，`fg`可将退到后台的任务叫回
- `ctrl + s`: 锁定屏幕输出，在`tail -f`查看日志的时候很实用
- `ctrl + q`: 解除ctrl s的屏幕输出锁定


# 命令

## cd
- `cd ~`: 进入到用户目录根路径下
- `cd -`: 进入到上次所在的路径内

## nc
- `nc -l 8000 < filename`: 在当前主机上开一个服务器传输filename文件
- `nc ip 8000 > filename`: 在另外一个内网可通的主机上接收上面传输的文件


## sed
1. 替换
`sed -i 's/old/new/' file`
2. 替换时新旧内容中含有特殊字符(例如/或#等),可以使用其他符号(:,#~等)把各部分内容隔开
`sed -i 's:/usr/bin:/lib/bin:' file`
`sed -i 's,/usr/bin,/lib/bin,' file`

