---
layout: post
title:  k8s-DaemonSet
description: 
modified:   2019-05-28 10:23:07
tags: [k8s]
---
DaemonSet使用场景，想要在集群中的每个Node上都部署一个pod. RS和RC只能保证pod的数量，无法做到让每个node上一个pod, 因为RS
和RC都是通过调用kubernetes Scheduler获取到要部署的Node

## ds部署在指定节点
ds默认会在集群上的每个节点都部署上pod，但是可以在template中指定nodeSelector中的label，在集群中指定的节点上进行部署。

## ds应用
ds可以用来部署类似linux 系统init程序或者systemd daemon进程这种系统启动时用的进程。


## 命令
`kubectl create -f daemonset.yaml`
`kubectl get ds/daemonset`

