---
layout: post
title:  k8s-liveness探针
description: 
modified:   2019-05-24 10:14:38
tags: [k8s]
---

k8s部署完成pod以后，为了保证pod的健康状态。k8s提供通过liveness probe探针，去检查pod上的应用是否依然正常运行。

## liveness probe的方式
liveness probe提供两种检查方式： HTTP GET 或TCP Socket

HTTP GET方式的例子
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kubia-liveness
spec:
  containers:
  - image: wfsly/kubia-unhealthy
  	name: kubia
	livenessProbe:
	  httpGet:
	    path: /
		port: 8080
```
这个pod的yaml定义了一个http get方式的liveness probe, 告诉k8s定期的去通过HTTP GET请求去调用8080端口上的/路径，根据接口的
返回值去鉴别pod是否健康

创建了liveness probe以后，可以通过指令`kubectl describe pod kubia-liveness` 查看Pod中关于liveness prob的详情

```yaml
Containers:
  kubia:
    ......
	Liveness:       http-get http://:8080/ delay=0s timeout=1s period=10s #success=1 #failure=3
```
其中关于Liveness的详情说明：
	- http-get 通过http-get方式
	- http://:8080/ 请求pod的8080:/路径, 此接口必须是一个不需要认证的接口，否则会导致检查失败
	- delay liveness的启动延迟时0s, 0s表示pod启动后就立即启动liveness探针, 但是推荐将deplay设置非0值，因为启动pod时就启动探针，往往会请求失败, 造成pod重启. 可通过initialDelaySeconds去设置delay时间
	- timeout 请求超时限制时1s,  如果1s内请求没能返回，则认为此次liveness检查失败
	- period liveness的检查周期，每隔多久检查一次
	- failure 允许失败的次数，超过此次数后，将会对pod进行销毁重建

## 

