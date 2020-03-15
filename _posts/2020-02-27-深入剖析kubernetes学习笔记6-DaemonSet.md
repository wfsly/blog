---
layout: post
title:  深入剖析kubernetes学习笔记6-DaemonSet
description: 
modified:   2020-02-27 10:55:41
tags: [kubernetes]
---

DaemonSet是容器化守护进程，可以让用户在kubernetes集群中运行一个Daemon Pod。

这个Pod有如下三个特征：
- 这个Pod运行在kubernetes的每一个Node节点上
- 每个节点上只有一个这样的Pod实例
- 当有新的节点加入到kubernetes集群后，该Pod会自动的在新节点上被创建出来；而当旧节点被删除后，它上面的Pod也相应的会被回收掉 

Daemon Pod的实际意义举例：
1. 各种网络插件的Agent组件，都必须运行在每一个节点上，用来处理节点上的容器网络
2. 各种存储插件的Agent组件，也必须运行在每一个节点上，用来在这个节点上挂载远程存储目录，操作容器的Volume目录
3. 各种监控组件和日志组件，也必须运行在每一个节点上，负责这个节点上的监控信息和日志搜集

## DaemonSet工作原理

DaemonSet controller 首先从Etcd中获取所有Node的列表，遍历所有Node，检查当前Node是否携带DaemonSet所管理的Pod的label。
- 1.没有则创建一个Pod
- 2.有，数量大于1，删除多余的Pod
- 3.有一个，则节点正常

在指定的Node创建Pod，需要给DaemonSet指定nodeSelector，不过kubernetes项目里nodeSelector是一个逐渐将被弃用的字段了。nodeAffinity是一个功能更完善的字段，会替代nodeSelector。目前DaemonSet在创建Pod的时候，会自动在这个Pod的API对象里，加上这样一个nodeAffinity定义。

DaemonSet还会给Pod自动加上另外一个与调度相关的字段，叫做tolerations(容忍)，表示这个Pod会容忍某些节点上的taint污点。节点打上污点后，污点相关label的Pod无法调度到节点上，添加容忍后，则可以调度到此节点上。

DaemonSet的过人之处就是靠tolerations实现的。假如当前DaemonSet管理的是一个网络插件的Agent Pod，那么就必须给这个Daemonset的YAML里加上一个能够容忍"node.kubernetes.io/network-unavailable"污点的tolerations，因为在kubernetes项目中，当一个节点还未安装网络插件时，这个节点就会被自动加上"node.kubernetes.io/network-unavailable"的污点，有了这个toleration，调度器调度这个Pod的时候，就会忽略当前节点的污点，将网络插件的Agent组件调度到这台机器上。这种机制正式部署kubernetes集群的时候，能够先部署kubernetes本身、再部署网络插件的根本原因。