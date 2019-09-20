---
layout: post
title:  日志分割logrotate
description: 
modified:   2019-09-20 11:46:05
tags: [linux]
---

今天排查bug日志的时候，测试给了调用我负责模块接口的09-19 21:19错误日志，我通过`grep`调用方的req-id，在我负责的模块所在的server日志中
去过滤req-id，此id相关的日志竟然一条也没有。

大写的懵逼，由于我查看的是昨天的日志，日志文件名时`test-server.log-20190919.gz`. 因为可以使用`vim`直接打开此压缩文件查看
内容，所以我默认的以为`grep test-server.log-20190919.gz`可以进行关键词查找。

## grep不能查找压缩文件

想要直接对压缩文件进行过滤关键信息，可以使用`zgrep`命令, `zgrep`也是通过出发`grep`命令对压缩文件进行检索。
但是`zgrep`命令并不支持所有的`grep`命令参数，使用体验没有grep那么好。

对于压缩过的日志分割文件，可以先解压，然后再使用`grep`进行查找。



## log文件的备份

在查看日志的时候，非当日的日志都是被切割备份到了一个后缀有日期的gz文件。日期备份的文件对应的多数默认时前一天日期的日志,
这具体要看logrotate定时任务的执行时间

### cron vs anacron
在这里要提一下cron和anacron的区别，两者都是执行定时任务，但是cron是守护进程，适用于7x24h不停机的机器，一旦关机，crontab无法执行,
再次开机也不会执行之前没执行过的任务。

而anacron适合不是7x24h运行的机器，对于未执行的任务，重新开机后，anacron会重新计划的任务。

## 日志分割定时任务的开始时间

在`ubuntu`系统中可查看`/etc/crontab`, 在`centos`系统中查看`/etc/anacrontab`文件，里面每日执行的crontab的时间设置。

```shell
# 这是ubuntu中的配置

# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# m h dom mon dow user	command
17 *	* * *	root    cd / && run-parts --report /etc/cron.hourly
25 6	* * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.daily )
47 6	* * 7	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.weekly )
52 6	1 * *	root	test -x /usr/sbin/anacron || ( cd / && run-parts --report /etc/cron.monthly )


```

```shell
# 这是centos中的配置
# /etc/anacrontab: configuration file for anacron

# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/sh
PATH=/sbin:/bin:/usr/sbin:/usr/bin
MAILTO=root
# the maximal random delay added to the base delay of the jobs
RANDOM_DELAY=45
# the jobs will be started during the following hours only
START_HOURS_RANGE=3-22

#period in days   delay in minutes   job-identifier   command
1   5   cron.daily      nice run-parts /etc/cron.daily
7   25  cron.weekly     nice run-parts /etc/cron.weekly
@monthly 45 cron.monthly        nice run-parts /etc/cron.monthly
~
```

以`centos`的配置为例，找到`/etc/cron.daily`这行，这表示的是每日执行的crontab. 
period: 任务频率, 每日执行一次
delay: 执行一个任务前等待的时间，5分钟的延迟
command: 执行的cron任务命令或脚本

在上面有一行`START_HOURS_RANGE=3-22`, 表示任务开始的时间是在`3-22`点之间，如果机器一直运行，则是3点开始。

`1 5 cron.daily nice run-parts /etc/cron.daily`
每天都执行/etc/cront.daily/目录下的脚本文件，真实的延迟RANDOM_DELAY+delay。这里的延迟是5分钟，加上上面的RANDOM_DELAY，
所以实际的延迟时间是5-50之间，开始时间为03-22点，如果机器没关，那么一般就是在03:05-03:50之间执行。


## logrotate日志分割

日志文件由于持续增长，所以日志文件需要定时分割，避免出现过大的文件，增加查阅和备份的困难。

linux系统中默认带有日志切割工具`logrotate`, 通过搭配crontab定时任务，实现对日志文件的定时切割。

在`/etc/cron.daily`就有logrotate的执行命令，所以默认的日志分割是在凌晨3点后开始进行, 3:05-50之间。

所以默认分割的日志文件中，会有前一天和当天两个时间的日志。
