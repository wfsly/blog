---
 layout: post
 title: Linux_Shell_Cheated_sheet
 date: 2017-09-26 07:02:52
 categories: linux
 tags: [linux]
---

## cd
`cd ~`: 进入到用户目录根路径下

`cd -`: 进入到上次所在的路径内


## nc

`nc -l 8000 < filename`: 在当前主机上开一个服务器传输filename文件
`nc ip 8000 > filename`: 在另外一个内网可通的主机上接收上面传输的文件
