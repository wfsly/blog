---
layout: post
title:  深入剖析kubernetes学习笔记2-集群搭建
description: 
modified:   2020-02-01 18:35:23
tags: [kubernetes]
---

<!-- TOC -->

[1 kubernetes集群搭建](#1-kubernetes集群搭建)
- [1.1 一键部署利器kubeadm](#1.1-一键部署利器kubeadm)

<!-- /TOC -->

# kubernetes集群搭建

## 一键部署利器kubeadm

kubeadm容器化部署kubernetes集群组件，但是kubelet需要操作宿主机的网络，文件系统，无法进行容器化部署，kubeadm的妥协方案是kubelet仍需要通过二进制应用安装到宿主机，kubernetes集群其他组件通过容器化部署

## kubeadm init的工作流程

init工作流程代码在k8s.io/kubernetes/cmd/kubeadm/app/cmd/init.go NewCmdInit

1. Preflight checks
  kubeadm首先要做的就是一系列的检查工作，以确定这台机器是否可以用来部署kubernetes
  - linux kernel版本是否是3.0以上
  - linux cgroups模块是否可用
  - 机器的hostname是否标准，在kubernetes的项目里，机器的名字和一切存储在etcd中的API对象，都必须使用标准的DNS命名(RFC1123)
  - 用户安装的kubeadm和kubelet版本是否匹配
  - 机器上是否已经安装了kubernetes的二进制文件
  - kubernetes的工作端口10250/10251/10252端口是否被占用
  - ip,mount等linux命令是否存在
  - Docker是否安装
  - 更多详细检查项，查看代码k8s.io/kubernetes/cmd/kubeadm/app/preflight/checks.go RunInitNodeChecks
2. 安装、配置、启动kubelet
3. 生成kubernetes对外提供服务所需要的各种证书和对应目录
  - kubernetes对外提供服务，都要通过https才能访问kube-apiserver.
  - kubeadm为kubernetes项目生成的证书都放在/etc/kubernetes/pki目录下, 在这个目录下，最主要的证书文件是ca.crt和对应的私钥ca.key
  - 用户使用kubectl获取容器日志等streaming操作时，需要通过kube-apiserver向kubelet发起请求，这个连接也必须是安全的。kubeadm为这一步生成了apiserver-kubelet-client.crt文件，对应的私钥是apiserver-kubelet-client.key
  - 更多证书种类，查看代码
  也可以选择不让kubeadm不创建证书，而是拷贝已有的证书到/etc/kubernetes/pki目录里, kubeadm就会跳过证书生成步骤，
4. kubeadm为其他组件生成访问kube-apiserver所需的配置文件
   这些文件件的路径是/etc/kubernetes/xxx.conf
5. 生成Master组件的Pod配置文件
   kubernetes是通过Static Pod的方式，在集群还未创建的时候启动Master组件的Pod
   kubeadm为master组件生成的yaml配置文件，放在/etc/kubernetes/manifest
   kubelet会启动时会自动检查这个目录，加载里面的yaml文件，在机器上启动pod
6. 若etcd也适用kubeadm部署，kubeadm生成etcd的pod yaml文件
   同样适用static pod的方式, 在/etc/kubernetes/manifest/目录下

7. master容器启动后，kubeadm会通过检查localhost:6443/healthz这个master组件健康检查url，等待master组件全部运行起来
8. kubeadm为集群生成一个bootstrap token
   使用这个token，安装了kubelet和kubeadm的节点就可以通过kubeadm join加入到集群当中
9. token生成后，kubeadm会将ca.crt等master节点的重要信息，通过ConfigMap的方式保存到etcd中，这个ConfigMap就是cluster-info
10. kubeadm安装默认插件kube-proxy和DNS
    kube-proxy用于提供服务发现

## kubeadm join的工作流程
为什么join的时候需要token？
因为一个机器想要成为kubernetes集群的一个节点，就必须在集群的kube-apiserver上注册,但是要想和kube-apiserver打交道，这台机器上就必须获取到相应的证书(CA文件)，但是kubeadm是一键安装，不可能会让用户手动拷贝Master上的证书文件到机器。所以kubeadm至少需要发起一次“不安全模式”的访问到kube-apiserver，从而拿到ConfigMap中的cluster-info。而bootstrap token，扮演的就是这个过程中的安全验证角色。只要有了cluster-info里的kube-apiserver的地址，端口，证书，kubelet就可以以“安全模式”连接到apiserver上，这样新的节点就可以部署完成。

## kubeadm init参数配置
`kubeadm init --config kubeadm.yaml` 通过制定yaml配置文件去配置kubeadm init的配置参数，kubeadm.yaml中的配置项会替换/etc/kubernetes/manifests/kube-apiserver.yaml里command字段的对应参数

## kubeadm 部署集群

### 通过Taint/Toleartion机制调整Pod的调度
1. 默认情况下Master节点上是不允许运行用户Pod的。Kubernetes做到这一点，依靠的是Kubernetes的Taint/Toleration机制

其原理：一个节点被加上了Taint，即被“打上了污点”，那么所有的Pod就都不能在这个节点上运行，因为Kubernetes的Pod有"洁癖"。除非有个别的Pod声明自己能“容忍”这个“污点”，即声明了Toleration，它才可以运行在这个节点上。

`kubectl taint nodes node1 foo=`