---
layout: post
title:  入剖析kubernetes学习笔记7-Job和CronJob
description: 
modified:   2020-03-01 21:48:12
tags: [kubernetes]
---

<!-- TOC -->

[1 Job](#1-job)
[2 Batch Job](#2-batchjob)
[3 使用Job的常用方法](#3-使用job的常用方法)

<!-- /TOC -->

Deployment, StatefulSet, DaemonSet都是编排的线上任务，即Long Running Task(长作业)。这些应用，一旦启动，除非出错或停止，它的容器进程会一直保持在Running状态。但有一类作业明显不符合这种条件，就是“离线业务”，或者叫做Batch job(计算任务)。这种任务在计算完成后就直接退出了，如果依然用Deployment管理，任务完成退出后会被不断重启。

## Job

Job的YAML定义中，restartPolicy只允许被设置为Never何OnFailure, job执行成功后不能重启，否则会重复执行job。

当restartPolicy=Never时，如果job执行失败了，Job controller就会不断的尝试创建一个新的Pod。不过，不会允许一会创建，Job的spec.backoffLimit字段定义了重试的次数，默认为6。需要注意的是Job controller重新创建Pod的间隔是呈指数增加的，即下一次重新创建Pod的动作分别会发生在10s，20s，40s……之后。

当restartPolicy=OnFailure时，如果job失败，controller会不断重启Pod，不去创建新Pod

当job执行结束后，Pod的状态会变成Completed。如果job一直迟迟不结束，job的yaml中有一个spec.activeDeadlineSeconds字段可以设置最长运行时间。一旦超过这个时间，这个Job启动的Pod就会被停止。此时Pod的状态里会显示终止原因为DeadlineExceeded。

## Batch Job
不过离线业务之所以被称为Batch Job，当然是因为他们可以“Batch”，也就是并行的方式去执行。

在Job的API对象中，负责并行控制的参数有两个：
- spec.parallelism 它定义的是一个Job在任意执行期间最多可以启动多少个Pod同时运行
- spec.completions 它定义的是Job至少要完成的Pod数目，即Job的最小完成数。


Job Controller控制的对象，直接就是Pod。控制器创建Pod，会根据parallelism和completions两个参数做创建修正。

## 使用Job的常用方法
1. 外部管理器+Job模板
这种模式的特定用法是：把Job的yaml文件定义为一个模板，然后用外部工具控制这些模板来生成Job。这种情况下，yaml中会有可替换的变量，供末班实例化的时候使用。然后外部工具调用kubectl等命令去创建job。此种情况下，Job的parallelism和completions都设置为1，并行控制交给外部工具来管理。

2. 拥有固定任务数据的并行Job
只关系最后有spec.completions个任务完成，不关心并发度。任务的执行需要靠容器内的程序

3. 指定并行度，但不设置固定的completions值
指定任务队列，容器内的程序消费队列中的任务，程序需要自行判断何时停止.

## Cronjob

定时任务，在其yaml文件中，最重要的关键词是jobTemplate。Cronjob是一个job对象的控制器。

Cronjob和job的关系，就如同deployment和pod的关系一样，是用来专门管理job对象的控制器。只不过，它的创建和删除job的依据，是schedule字段定义的，一个标准的unix cron格式的表达式

由于任务的特殊性，可能一个定时任务还没结束，第二个就开始了，这时候需要通过spec.concurrencyPolicy字段定义具体的处理策略。
concurrencyPolicy=Allow,这也是默认情况，这意味着这些Job可以同时存在
concurrencyPolicy=Forbid, 这意味着不会创建新的pod，该创建周期被跳过
concurrencyPolicy=Replace, 这意味着新产生的Job会替换旧的，未执行完的Job

如果某一次job创建失败，这次创建会被标记为"miss"，当在指定的时间窗口内，miss的数据达到100时，那么Cronjob会停止创建job。这个时间窗口由spec.startingDeadlineSeconds