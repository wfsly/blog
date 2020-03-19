---
layout: post
title:  深入剖析kubernetes学习笔记5-StatefulSet
description: 
modified:   2020-02-18 09:52:16
tags: [kubernetes]
---

<!-- TOC -->

[1 StatefulSet](#1-statefulset)
[2 StatefulSet拓扑状态](#2-statefulset存储状态)
[3 StatefulSet有状态应用实践](#3-statefulset有状态应用实践)

<!-- /TOC -->


# StatefulSet

kubernetes的Deployment不足以覆盖所有的应用编排问题，因为Deployment中一个应用的所有Pod是一样的，他们之间没有顺序，没有牵连，可以随时被创建和停掉。但实际应用场景中，尤其是分布式应用，多个实例之间往往有依赖关系，比如:主动关系，主备关系。还有数据存储类应用，多个实例往往都会在本地磁盘保存一份数据，这些实例被关掉重建，实例和数据之间的对应关系也已经丢失。

这种实例之间不对等关系，以及实例对外部数据有依赖关系的应用，就被称为”有状态应用“(Stateful Application)。

容器诞生后，大家发现，它用来封装”无状态应用“(Stateless Application)，尤其是Web服务，更好用。如果换成是有状态应用，难度直线上升。

StatefulSet是kubernetes在Deployment基础上对有状态应用的支持。

StatefulSet将真实世界里的应用，抽象成了两种情况：

1. 拓扑状态。这种情况意味着，应用的多个实例之间不是完全对等的关系。这些应用实例，必须按照某些顺序启动，比如应用的主节点A要先于从节点B启动。而如果你把A和B两个Pod删除掉，它们再次被创建出来时也必须严格按照这个顺序才行。并且，新创建出来的Pod，必须和原来Pod的网络标识一样，这样原先的访问者才能使用同样的方法，访问到这个新Pod。
2. 存储状态。这种情况意味着，应用的多个实例分别绑定了不同的存储数据。对于这些应用实例来说，Pod A第一次读取到的数据，和隔了十分钟之后再次读取到的数据，应该是同一份，哪怕在此期间Pod A被重新创建过。这种情况最典型的例子，就是一个数据库应用的多个存储实例。

所以StatefulSet的核心功能，就是通过某种方式记录这些状态，然后再Pod被重新创建时，能够为新Pod恢复这些状态。

# StatefulSet拓扑状态
## Headless Service
Headless Service是不分配虚拟ClusterIP的Service, 直接通过DNS记录的方式，解析出被代理的Pod的IP地址,从而找到所代理的Pod。

StatefuleSet正是通过使用Headless Service方式，为其管理的Pod创建固定并且稳定的DNS记录，通过DNS记录找到其所管理的Pod，无需关心分配的IP。 StatefulSet会给其管理的Pod按照”名字+编号“排列Pod顺序，从而固定Pod的拓扑状态。

# StatefulSet存储状态

## Persistent Volume Claim
将声明Volume，从开发人员和运维人员之间解耦。将复杂类型的Persistent Volume定义交给运维人员，开发人员使用只需要定义使用PVC。kubernetes会自动为PVC绑定一个符合条件的PV。 命名方式：<pvc名字>-<StatefuleSet名字>-编号。

创建StatefulSet时，在spec中增加volumeClaimTemplates为StatefulSet所管理的Pod，定义PVC，所定义的PVC和Pod一样，名字中会带有和Pod一致的编号。相同编号的PVC只会被相同编号的Pod挂在使用。

例如，当pod web-0被删除，重新创建后，依然挂载的是pvc-web-0。所以pod被删除重建后，重新挂载pvc后，依然能读取到原有的存储数据。是因为Pod被删除后，这个Pod所对应的PVC和PV并不会被删除，此时控制器发现Pod web-0消失了，就会重新创建一个新的，名字依然是web-0的pod去达到期望状态，然后这个pod会重新挂载pvc-web-0，进而找到绑定的pv，然后读到了原有的内容。

通过这种方式，kubernetes的StatefulSet就实现了对应用存储状态的管理。



# StatefulSet有状态应用实践

部署mysql主从复制集群