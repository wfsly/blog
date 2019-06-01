---
layout: post
title:  k8s-ReplicaSets.md
description: 
modified:   2019-05-26 20:59:13
tags: [k8s]
---

ReplicaSets是下一代控制pod副本数量的控制器，是ReplicationController的升级版

## ReplicaSet改进之处
rs的selector更具表现力，rc只能匹配key=value的pod，rs还支持匹配只要有key不管值是什么的pod
