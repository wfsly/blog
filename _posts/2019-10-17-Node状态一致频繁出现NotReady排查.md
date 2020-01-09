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

## 原因
由于node节点上的kubelet上报状态时间，超过了controller-manager默认设置的监控节点状态的时间周期，导致在Ready的周期内没有收到状态上报，controller-manager将此节点的状态置为了NotReady，当controller-manager收到了迟到的状态上报后，又将节点状态置为了Ready

## 解决方案
修改controller-manager的启动参数--node-monitor-grace-period，默认是40s，改为了300s。--node-monitor-period默认为5s，修改为30s。
