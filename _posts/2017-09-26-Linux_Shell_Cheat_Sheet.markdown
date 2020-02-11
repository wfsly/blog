---
 layout: post
 title: Linux_Shell_Cheat_Sheet
 date: 2017-09-26 07:02:52
 categories: linux
 tags: [linux]
---

# 命令行快捷键

## 光标移动
- `ctrl + a`: 移动光标到行首, 相当于Home键
- `ctrl + e`: 移动光标到行尾, 相当于End键
- `ctrl + b`: 光标向前移动一个字符, 相当于箭头左键
- `ctrl + f`: 光标向后移动一个字符, 相当于箭头右键
- `alt + b`: 光标向前移动一个单词 
- `alt + f`: 光标向后移动一个单词

## 命令编辑
- `ctrl + p`: 上一条命令, 等同于方向上键
- `ctrl + n`: 下一条命令, 等同于方向下键
- `ctrl + h`: 向前删除一个字符
- `ctrl + d`: 向后删除一个字符, 相当于Delete键
- `ctrl + w`: 向前剪切/删除一个单词(以空格为分届)
- `alt + d`: 向后剪切/删除一个单词
- `ctrl + u`: 剪切/删除当前光标到行首的内容
- `ctrl + k`: 剪切/删除当前光标到行尾的内容
- `ctrl + y`: 在光标出粘贴上面可以剪切的命令所剪切的内容
- `ctrl + _`: 撤销之前的操作
- `ctrl + xx`: 行首位置和当前光标位置切换

- `ctrl + t`: 颠倒光标出字符和前一个字符的位置
- `alt + c`:  将光标处的字符变成大写，同时将整个单词光标后面的部分变成小写，光标跳至单词末尾
- `alt + l`:  将整个单词从光标开始以后后面的部分变为小写字母
- `alt + u`:  将整个单词从光标开始以后后面的部分变为大写字母

## 历史命令

- `ctrl + r`: 历史命令查询
- `!!`: 执行上一条命令
- `!+历史命令序号`: 执行这条指令, 结合history用
- `alt + .`: 提取上一条命令最后一个单词

## 进程控制

- `ctrl + z`: 将当前任务退到后台执行，`fg`可将退到后台的任务叫回
- `ctrl + s`: 锁定屏幕输出，在`tail -f`查看日志的时候很实用
- `ctrl + q`: 解除ctrl s的屏幕输出锁定

## 终端

- `ctrl + alt + t`: 打开终端
- `ctrl + shift + t`: 打开新标签页
- `ctrl + shift + w`: 关闭新标签页
- `ctrl + shift + PgUp`: 标签页左移
- `ctrl + shift + PgDn`: 标签页右移

## tmux
- `prefix + d`: 分离会话
- `prefix + s`: 列出所有会话
- `prefix + $`: 重命名当前会话
- `prefix + ,`: 重命名当前窗口


# 命令

## cd
- `cd ~`: 进入到用户目录根路径下
- `cd -`: 进入到上次所在的路径内

## du
- `du -h`: 显示指定目录及其子目录或指定文件所占用的磁盘空间

## nc
- `nc -l 8000 < filename`: 在当前主机上开一个服务器传输filename文件
- `nc ip 8000 > filename`: 在另外一个内网可通的主机上接收上面传输的文件

## grep
- `grep -nr 'key' ./`: 在当前目录的文件检索关键字key,并输出行号和内容
- `ls | grep -E 'key1|key2'`: 在ls的输出中检索关键字key1或key2的内容, -E支持正则


## sed
1. 替换
`sed -i 's/old/new/' file`
2. 替换时新旧内容中含有特殊字符(例如/或#等),可以使用其他符号(:,#~等)把各部分内容隔开
`sed -i 's:/usr/bin:/lib/bin:' file`
`sed -i 's,/usr/bin,/lib/bin,' file`
3. 用新的内容new_content替换掉有关键词key的行
`sed -i '/key/c new_content' file`
4. 输出匹配正则的行

## awk
1. 输出文本的所有行
`awk '{print $0}' file`

2. 输出文本第一列
`awk '{print $1}' file`

3. 输出文本第最后列
`awk '{print $NF}' file`

## curl
1. 请求url并将返回的json数据json格式化
`curl -s http://127.0.0.1:8011/mate-server?Action=DescribeModules -d '{}' | python -m json.tool`

## yum
1. yum下载rpm和依赖
`yumdownloader install --resolve --downloadonly --downloaddir=/home/wangfushu ntp `
2. yum安装本地包`
`yum localinstall a.rpm`

## rpm
1. 查看机器上安装的所有rpm包
`rpm -qa`
`rpm -qa | grep tmux`

## tmux
1. 新建一个name会话
`tmux new -s name`
2. 分离会话, 退出会话界面，进程不退出
`prefix + d` 或命令行执行`tmux detach`
3. 查看当前有哪些会话
`tmux ls`
4. 接入会话
`tmux attach -t <会话编号>/<会话name>`
5. 杀死会话
`tmux kill-session -t <会话编号>/<会话name>`
6. 切换会话
`tmux switch -t <会话编号>/<会话name>`
7. 重命名会话
`tmux rename-session -t 0 new-name`
8. 快捷键


## 图片
- `eog image_file`: 打开图片
- `mogrify -format new_type file`: 转换图片格式为新的格式,例如`mogrify -format png lock_screen.jpg`, 会生成lock_screen.png的图片

## 截屏
- `import file.png`: 截图, 执行命令用鼠标选中所要截取的部分

# 组合命令

## 找到程序, 排除掉含有某些关键字的结果， 获取pid并kill掉进程
`ps -ef | grep '\./mate-server' | grep -v 'grep' | awk '{print $2}' | xargs kill`

## 将命令行输出复制到剪切板
`pwd | xsel -b`

## hostA和hostB不同，但是hostC可以同时连接hostA和hostB,利用hostC做中转，从A向B复制文件
`ssh root@hostA "cat /path/file" | ssh root@hostB "cat -> /path/file"`

