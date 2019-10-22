---
layout: post
title:  Node状态一致频繁出现NotReady排查
description: 
modified:   2019-10-17 15:58:35
tags: [k8s]
---

在测试环境部署了一套master GA的集群。加入Node节点后，有部分节点一直频繁出现NotReady状态.


## 排查
1. 因为主机上的时间不一致导致kubelet上报状态时apiserver时间校验.
查看正常节点和master节点的`date`，发现时间并不一致，所以暂时排除此种可能

2.
