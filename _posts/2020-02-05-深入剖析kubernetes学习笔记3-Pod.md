---
layout: post
title:  深入剖析kubernetes学习笔记3-Pod
description: 
modified:   2020-02-05 12:47:33
tags: [kubernetes]
---

<!-- TOC -->

[1 Pod](#1-Pod)
[2 Pod基本概念](#2-Pod基本概念)
[3 Pod使用进阶](#3-Pod使用进阶)

<!-- /TOC -->

# Pod

Pod是Kubernetes项目的原子调度单位, Pod扮演的是传统部署环境里“虚拟机”的角色。

## 我们为什么需要Pod

一个进程运行，实际还有相关的程序在同时运行，所以一个进程其实是一个进程组，可通过命令`pstree -g`查看，进程组中的几个进程之间可以相互通信，共享文件，内存等。

Pod内可以启动多个容器，因为容器的本质是进程，所以Pod就像是一个进程组一样，Pod中可以有多个容器，pod最先启动的是infra容器(镜像是pause), 之后再启动用户容器，这样用户容器都公用的Infra容器的网络空间，存储空间. 所以Pod是生命周期和Infra容器有关，和用户容器无关

## 容器设计模式

InitContainer, Pod中的InitContainers会按照顺序，先于普通Containers启动

### 容器设计模式-sidecar

sidecar指的是我们可以在一个Pod中，启动一个辅助容器，来完成一些独立于主进程(主容器)之外的工作

应用场景实例： 容器日志收集

现在有一个应用，需要把日志输出到容器/var/log目录下，这时，就可以把Pod的volume挂在到容器/var/log目录，然后在Pod中同时运行一个sidecar容器，它也声明挂在同一个Volume到自己的/var/log目录下，然后sicdecar容器剩下的就只需要做一件事，持续的从/var/log目录下读取日志内容，转发到MongoDB或ElasticSearch存储起来。这样一个基本的的日志收集工作就完成了。

与Pod网络相关的配合和管理，也都可以交给sidecar完成。lstio这个微服务治理项目就是这么做的。

# Pod基本概念

## Pod的重要字段

- NodeSelector
  供用户将Pod与Node进行绑定的字段。Pod的yaml中指定NodeSelector后，kubernetes只会将Pod往带有指定Label的Node上调度
- NodeName
  一旦Pod的NodeName被赋值，Kubernetes就认为Pod已经被调度了。所以NodeName这个字段一般都是由调度器去设置，但用户也可以设置它来“骗过”调度器。这个做法一般是在测试或者调试的时候才会用到。
- HostAliases
  定义了Pod的hosts文件(/etc/hosts)里的内容。
  用法如下:

  ```yaml
  apiVersion: v1
  kind: Pod
  ...
  spec:
    hostAliases:
    - ip: "10.1.2.3"
      hostnames:
      - "foo.remote"
      - "bar.remote"
  ```
  这样，这个Pod启动后，/etc/hosts文件里会多出下列内容

  ```bash
  cat /etc/hosts
  ...
  10.1.2.3 foo.remote
  10.1.2.3 bar.remote
  ```

  在Kubernetes项目中，要设置hosts内容，必须通过yaml。如果直接修改hosts文件，Pod被删除重建后,修改的内容就会被覆盖
-  凡是跟容器的Linux Namespace相关的属性，都是Pod级别的
-  凡是Pod中的容器要共享宿主机的Namespace，都是Pod级别的
### Pod定义总最重要的字段-Containers

Containers级别的一些重要字段
- Image
- Command
- workingDir
- Ports
- VolumeMounts
- ImagePullPolicy
  定义了镜像拉取的策略。容器镜像本身就是Container定义中一部分。
  ImagePullPolicy值:
  - Always(默认值), 即每次都重新拉取一次镜像
  - Never, 永远不会主动拉取
  - IfNotPresent, 如果宿主机上没有此镜像才拉取
- Lifecycle
  它的定义是Container Lifecycle Hooks。顾名思义，就是在容器状态发生变化时触发一系列“钩子”。
  Hooks:
  - postStart, 在容器启动后，立刻执行一个指定的操作, 但是这个操作无法保证是在ENTRYPOINT之前执行，所以他们的执行时并行的。
  - preStop, 在容器被杀死之前执行的操作。不同于postStart,preStop操作的执行是同步的，只有在这个操作完成之后，容器才会被杀死。

## Pod的生命周期-Status

Pod的生命周期的变化，主要体现在Status部分。这是Pod除了Metadata和Spec之外的，第三个重要字段。pod.status.phase就是pod当前的状态
pod状态值：
- Pending。表示pod的yaml已经提交给了Kubernetes，API对象被创建并保存到了Etcd中。但是这个容器因为某些原因不能被顺利创建，比如调度不成功。
- Running。表示Pod已调度成功，跟一个具体的节点绑定。所包含的容器已经创建成功，并且至少有一个在运行中
- Succeed. 表示Pod中所有的容器都正常运行完毕，并且退出了。这种情况在一次性任务时最为常见
- Failed. 表示，Pod中至少有一个容器以不正常的状态(非0返回码)退出。
- Unknown. 这是一个异常状态。表示Pod的状态不能被kubelet汇报给kube-apiserver，这很有可能是主从节点间的通信出了问题。

pod的Status字段，还可以细分出一组Conditions。这些细分状态值包括：PodScheduled,Ready,Initialized,Unschedulable.它们用于描述造成当前Status的具体原因是什么。比如，Pod是Status.Phase是Pending，Condition是Unschedulable,这一位着调度出了问题

在代码`k8s.io/api/core/v1/types.go`的 Pod struct查看Pod具体细节


# Pod使用进阶

## Projected Volume
Projected Volume是Kubernetes v1.11之后出的新特性。这种特殊的Volume是为容器提供预先定义好的数据，

kubernetes支持的projected volume:
- ConfigMap
- Secret
- Downward API
- ServiceAccountToken


### Secret
通过创建secret，将私密数据存入Etcd，然后将secret写入Projected Volume挂载到容器，供容器内的应用程序读取私密数据, 例如数据库的用户名和密码等。

kubelet会定时维护这些volumen, etcd中的secret数据被更新，则对应的volume下的数据也会同步更新。由于这个更新存在一定的时延，所以在写代码时，发起数据库连接的代码，要做好重试和超时的逻辑，绝对是个好习惯

secret对象要求存储的这些数据必须是base64转码的，以免出现明文密码的安全隐患

`kubectl create secret -f secret.yaml`

### ConfigMap
ConfigMap和Secret类似，区别在于ConfigMap保存的是不需要加密的信息

`kubectl create configmap -f configmap.yaml`

### Downward API

Downward API的作用是让Pod里的容器能够直接获取到这个Pod API对象本身的信息.
不过需要注意的是，Downward API能获取到的信息，是Pod里的容器进程启动之前就能确定下来的信息。如果想要获取容器进程pid，则无法使用Downward API，可以通过sidecar容器获取

Secret, ConfigMap, Downward API这三种Projected Volume定义的信息，大都还可以通过环境变量的方式注入到容器中，但是通过环境变量获取信息，不具备自动更新的能力。

### ServiceAccountToken

如果想从Pod内部通过Kubernetes的client访问Kubernetes的API, 是否可以呢？ 当然可以, 但是需要解决api server授权问题。

Service Account对象的作用就是Kubernetes系统内置的一种“服务账号”，它是Kubernetes进行权限分配的对象。比如，ServiceAccountA可以只对Kubernetes的API进行GET操作，AccountB可以有对Kubernetes的API的所有操作权限。

这种Service Account对象的授权信息和文件，就是存储在它所绑定的特殊的Secret对象中的。这个特殊的Secret对象叫做ServiceAccountToken.任何运行在Kubernetes集群上的应用，都必须使用serviceAccountToken里保存的授权信息，也就是Token，才可以合法的访问API Server.

kubernete已提供了一个默认”服务账户“