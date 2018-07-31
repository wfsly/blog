---
layout: post
title:  Kubernetes基础学习
description: 
modified:   2018-07-10 15:23:49
tags: [kubernetes]
---

# Kubernetes是什么
  Kubernetes是一个容器编排工具,在如今的技术开发中,由于容器技术在部署程序方面的极大便利, Docker等容器的应用已经非常广泛.
但是容器的使用有个单一职责的原则:运行多个容器,每个容器只完成一个单一的工作.因此将大型的工程进行服务容器化就是基础架构
SOA(面向服务架构)的转化过程,这个过程面临很多问题:
  - 容器之间的通信问题
  - 如何决定在哪运行以及运行几个容器
  - 如何获取容器的运行日志与运行状态信息
  - 如何部署新的镜像
  - 如何将特定的一部分容器暴露到公网或内网环境
  而Kubernetes就是Google开源的可以解决以上问题的可用于生产环境的容器化部署方案. Kubernetes确保开发人员可以随时的将容器
化的应用部署在想要部署的地方,并且提供应用运行所需要的资源.

# Kubernetes Cluster(集群)
  Kubernetes Cluster协调一个高可用计算机集群作为一个工作单元.通过集群Kubernetes可以高效的自动化应用容器的发布与调度,
Kubernetes集群包含两种资源:
  - Master: the master coordinate the cluster
  - Node  : nodes are the workers that run applications
  ![Cluster Diagram][cluster diagram]
  
  Master负责管理所有在集群中的活动,例如调度应用程序,维护应用状态.
  一个Node是一个虚拟机或物理机,在集群中作为工作机器.

 
# Kubectl kubernetes command line interface
  Kubectl uses the Kubernetes API to interact with the cluster

# Pods
  Pod是Kubernetes中抽象出来的最底层单元,承载镜像运行,提供镜像运行所需的资源:存储(Volume),网络(IP),关于如何运行每个容器
的信息. 每个Pod上可运行一个或多个容器
![Pods Overviews][pod overview]

# Node
  Pod总是运行在Node上的,一个Node上可以有多个Pod. Master可以通过Node去调度Pod.
  每个Node

[cluster diagram]: https://d33wubrfki0l68.cloudfront.net/99d9808dcbf2880a996ed50d308a186b5900cec9/40b94/docs/tutorials/kubernetes-basics/public/images/module_01_cluster.svg
[pod overview]: https://d33wubrfki0l68.cloudfront.net/fe03f68d8ede9815184852ca2a4fd30325e5d15a/98064/docs/tutorials/kubernetes-basics/public/images/module_03_pods.svg
[node overview]: https://d33wubrfki0l68.cloudfront.net/5cb72d407cbe2755e581b6de757e0d81760d5b86/a9df9/docs/tutorials/kubernetes-basics/public/images/module_03_nodes.svg
