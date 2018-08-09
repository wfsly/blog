---
layout: post
title:  Kubernetes部署监控-metrics-server
description: 
modified:   2018-08-09 16:03:43
tags: [kubernetes]
---

在较新的kubernetes版本中，已经将cAdvisor集成到了kubelet中了。所以不需要再额外的部署cAdvisor。获取监控数据只需要部署
[官网][offical]提供的Metrics Server就可以了。

# 部署前准备
- image:
	- gcr.io/google_containers/metrics-server-amd64:v0.2.1



## 1. 安装metric-server
1. 参考[metrics-server文档][metrics-server]部署metrics-server
2. 由于网络问题，先将下载镜像，复制到Node主机上，导入本地docker库
3. 将deploy/1.8+文件夹内容拷贝到master上。然后执行
```
# Kubernetes > 1.8
$ kubectl create -f deploy/1.8+/
```
由于当前版本deploy/1.8+/metrics-server-deployment.yaml文件中存在bug，使得部署失败。解决方法参考自[k8s全栈监控][juejin]
部署metric-server模块, 对deployment.yaml增加配置, 执行`kubectl delete -f deploy/1.8+/`删除之前的部署，然后再次重新部署
```
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-server
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
  labels:
    k8s-app: metrics-server
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  template:
    metadata:
      name: metrics-server
      labels:
        k8s-app: metrics-server
    spec:
      serviceAccountName: metrics-server
      volumes:
      # mount in tmp so we can safely use from-scratch images and/or read-only containers
      - name: tmp-dir
        emptyDir: {}
      containers:
      - name: metrics-server
        image: gcr.io/google_containers/metrics-server-amd64:v0.2.1
        imagePullPolicy: Always
        volumeMounts:
        - name: tmp-dir
          mountPath: /tmp
		# add command to fix bug
	    command:
        - /metrics-server
        - --source=kubernetes.summary_api:https://kubernetes.default?kubeletHttps=true&kubeletPort=10250&insecure=true
```

4. 请求`/apis/metrics.k8s.io/`验证metrics-server是否部署成功
5. 获取metrics数据，
- 命令行
	1. 执行`kubectl top node/pod`
	2. 执行
	```
	kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes
	kubectl get --raw /apis/metrics.k8s.io/v1beta1/nodes/<node_name>
	kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods
	kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods/<pod_name>
	```
- 接口
	1. 访问
	```
	http://domain/apis/metrics.k8s.io/v1beta1/nodes
	http://domain/apis/metrics.k8s.io/v1beta1/pods
	```

[参考][url]

## 2. 安装


## Troubleshooting

1. pod 状态 ImagePullOff
解决方案：
首先， 检查主机docker本地库是否有部署所需要的镜像，之后查看kubelet错误日志，是否依然有拉取镜像的操作，如果有，检查部署
yaml文件里，是否有`ImagePullPolicy: always`, 如果有，注释掉。

2. pod 状态CrashLoopBackOff, 在安装文档进行部署metrics-server时，未修改deployment.yaml文件前，pod出现了此问题
解决思路：
 - 首先执行`kubectl describe <pod-name>`，查看一下pod描述里的Events日志。提示找不到此pod时，加上命名空间参数就可以了。
 ```
 Events:
  Type     Reason     Age               From                                        Message
  ----     ------     ----              ----                                        -------
  Normal   Scheduled  7m                default-scheduler                           Successfully assigned kube-system/metrics-server-845d8784df-p4r7m to a01-r06-i18-43-5002583.jcloud.com
  Normal   Pulled     5m (x5 over 7m)   kubelet, a01-r06-i18-43-5002583.jcloud.com  Container image "gcr.io/google_containers/metrics-server-amd64:v0.2.1" already present on machine
  Normal   Created    5m (x5 over 7m)   kubelet, a01-r06-i18-43-5002583.jcloud.com  Created container
  Normal   Started    5m (x5 over 7m)   kubelet, a01-r06-i18-43-5002583.jcloud.com  Started container
  Warning  BackOff    2m (x25 over 7m)  kubelet, a01-r06-i18-43-5002583.jcloud.com  Back-off restarting failed container

 ```
 - 之后执行`kubectl logs <pod-name>`, 查看pod日志，进一步获取错误信息。提示找不到pod, 加上命名空间参数
  	```
  	I0809 05:15:07.435765       1 heapster.go:71] /metrics-server
	I0809 05:15:07.435888       1 heapster.go:72] Metrics Server version v0.2.1
	F0809 05:15:07.435901       1 heapster.go:79] Failed to get kubernetes address: No kubernetes source found.
  	```





[metrics-server]: https://github.com/kubernetes-incubator/metrics-server
[url]: https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/
[juejin]: https://juejin.im/post/5b6592ace51d4515b01c11ed#heading-10

[offical]: https://kubernetes.io/docs/tasks/debug-application-cluster/core-metrics-pipeline/
