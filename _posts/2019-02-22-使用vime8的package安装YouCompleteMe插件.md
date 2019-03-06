---
layout: post
title:  使用vime8的package安装YouCompleteMe插件
description: 
modified:   2019-02-22 10:08:19
tags: [vim]
---

1. 下载YouCompleteMe, `git clone https://github.com/Valloric/YouCompleteMe.git ~/.vim/pack/plugins/start/YouCompleteMe`
2. 下载依赖包, `git submodule update --init --recursive`
3. `cd ~/.vim/pack/plugins/start/YouCompleteMe && python install.py`
4. `cd ~/.vim/pack/plugins/start/YouCompleteMe/third_party/ycmd && python build.py --all`

# troubleshooting
当用vim打开文件出现`The ycmd server SHUT DOWN (restart with ':YcmRestartServer'). Unexpected exit code 1`此类提示时，
可执行下列命令查看具体的错误信息, 跟错误提示进行进一步解决
```
cd ~/.vim/pack/plugins/start/YouCompleteMe/third_party/ycmd
cp ycmd/default_settings.json .
python ycmd --options_file default_settings.json
```
