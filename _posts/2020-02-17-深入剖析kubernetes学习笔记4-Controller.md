---
layout: post
title:  深入剖析kubernetes学习笔记4-Controller
description: 
modified:   2020-02-17 08:36:19
tags: [kubernetes]
---

<!-- TOC -->

[1 控制器模式](#1-控制器模式)
[2 Deployment控制器](#2-Deployment控制器)

<!-- /TOC -->


# 控制器模式

## 控制循环 
kubernetes的组件kube-controller-manager就是一堆控制器的集合。代码在`kubernetes/pkg/controller/`目录下. 目录下所有的这些控制器，都遵循kubernetes的通用编排模式，即控制循环(control loop)。用下面这段go伪代码描述控制循环

```
for {
    实际状态 := 获取集群中对象X的实际状态(Actual State)
    期望状态 := 获取集群中对象X的期望状态(Desired State)
    if 实际状态 == 期望状态 {
        什么都不做
    } else {
        执行编排动作，将实际状态调整为期望状态
    }
}
```

## 控制器的定义
控制器定义yaml文件中，以Deployment为例，类似Deployment这样的控制器，实际上上半部分(即template之上)是控制器定义, 下半部分(template之下)的是控制对象的模板定义

这也就是为什么，在所有的API对象的Metadata里，都有一个字段叫ownerReference，用于保存当前API对象的的拥有者(Owner)的信息。举例，由deployment创建出来的Pod，其ownerReference里保存的就是此deployment中实际控制Pod的ReplicaSet相关的信息, 而ReplicaSet的ownerReference则是此Deployment

# Deployment控制器

Deployment实现了kubernetes中一个非常重要的功能：Pod水平扩展/收缩(horizontal scaling out/in)。

如果更新了Deployment的Pod模板，比如修改了容器镜像，那么Deployment就会遵循一种叫做“滚动更新”(rolling update)的方式，升级现有的容器。而这个能力的实现，依赖的是kubernetes中一个非常重要的API对象：ReplicaSet。

Deployment控制ReplicaSet, ReplicaSet去控制Pod，保证系统中Pod的个数永远等于指定的个数。这也是Deployment只允许容器的restartPolicy=Always的主要原因：只有在容器能保证自己始终是Running状态的前提下，ReplicaSet调整Pod的个数才有意义。

水平扩展/收缩，只需要修改ReplicaSet控制的Pod副本个数就能实现。或者通过指令修改`kubectl scale deployment nginx-deployment --replicas=4`

滚动更新，则是通过创建一个新的ReplicaSet对象，新rs管理的Pod个数，初始为0，之后变为1，旧rs的Pod个数响应的减少一个。就按照这种交替新旧交替创建和删除实现Pod个滚动更新

## RollingUpdateStrategy

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
...
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

在上面的滚动更新策略配置中，maxSurge指定的是除了DESIRED的数量之外，在一次滚动更新中，Deployment控制器还可以传感多少个新Pod；而maxUnavailable指定的是，在一次滚动更新中，Deployment控制器可以删除多少个旧Pod。同时，这两个配置还可以用百分比形式表示，比如maxUnavailable=50%,指定是一次最多可以删除"50%*DESIRED数量"个Pod


所以，Deployment实际控制ReplicaSet的数目，以及ReplicaSet的属性。而一个应用的版本对应一个ReplicaSet；这个版本应用的数量则由ReplicaSet通过它自己的控制器(ReplicaSet Controller)来保证