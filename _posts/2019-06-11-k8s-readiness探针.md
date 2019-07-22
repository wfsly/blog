---
layout: post
title:  k8s-readiness探针
description: 
modified:   2019-06-11 09:47:47
tags: [k8s]
---

当pod启动时，并不一定能立即接收请求，可能因为pod中各种服务启动有延迟，无法立即提供服务，如果pod启动后就被service将请求
转发过来，很有可能出现服务不可用的情况

readiness探针，可以使pod在满足了条件以后再变成ready状态，只有ready状态的pod才可以被service使用.

readiness探针可通过三种方式对pod进行验证, 即readiness的三种类型:
	- Exec 一个执行类型的探针，通过执行一个命令行程序，根据程序的退出码，判断readiness是否成功
	- HTTP GET http get探针，通过向容器发送get请求，根据返回值，判断readiness是否成功
	- TCP Socket tcp连接探针，向容器的指定端口打开一个tcp连接，如果可以建立连接则readiness成功

readiness探针失败时，不会向liveness失败一样，会将pod删除重建，只会是把pod的状态置为非ready状态，service无法将此pod加入到
service的endpoint中使用
