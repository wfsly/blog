---
layout: post
title:  k8s-ReplicationController
description: 
modified:   2019-05-24 10:38:47
tags: [k8s]
---

ReplicationController是k8s中创建和管理pod多副本，保证pod一直保持在期望状态的一种资源, 无论pod是以为何种原因消失，比如所在的node挂掉，
RC检查到pod丢失后，就会重建，增加或减少pod, 使pod保持在期望状态

RC管理的一组pods，是匹配某个确定的label selector的pods

## ReplicationController组成
RC主要有三个重要的部分：
	- label selector 决定了哪些pod在rc的管理范围
	- replica count 控制pod运行的数量
	- pod template 创建pod时使用

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: kubia
spec:
  replicas: 3
  selector:
    app: kubia // 可以不指定，默认匹配Pod template中国的labels. 指定的selector无法修改
  template:
    metadata:
    ¦ labels:
    ¦   app: kubia // k8s的api server会校验，未配置则无法通过
    spec:
    ¦ containers:
    ¦ - name: kubia
    ¦   image: wfsly/kubia
    ¦   ports:
    ¦   - containerPort: 8080
```

  为防止label selector填写的和Pod template中的不一致导致的一直重建Pod问题，label selector可以不填写，默认使用pod 
template中的label, 为了防止此种场景出现，k8s api server会检查rc的定义, 如果未配置pod中的label会无法创建rc
