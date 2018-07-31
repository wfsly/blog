---
layout: post
title:  kubernetes部署nginx-ingress教程
description: 
modified:   2018-07-31 16:24:45
tags: [kubernetes]
---

# 部署ingress-controller

docker image:
	- gcr.io/google_containers/defaultbackend:1.4
	- quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.17.1

### Notice: nginx-ingress的pod会被部署到node上，不在master上
### Notice: nginx-ingress的pod会被部署到node上，不在master上
### Notice: nginx-ingress的pod会被部署到node上，不在master上
重要的事情说三遍

## 使用kubernetes部署nginx-ingress-controller

在master(172.19.18.41)上部署nginx-ingress
需要提前将镜像下载下来，在物理机中加载到docker本地镜像库中.
```
docker save image_name > filename.tar
docker load < filename.tar
```


`kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml`

物理机上无法联外网，需要实现将url中的yaml内容复制到到文件内，然后使用本地文件。
`kubectl apply -f ingress_deploy.yaml`

安装完成后，执行`kubectl get pods --all-namespaces`可以看到新建的default-http-backend和ngress-ingress-controller两个pod



## Troubleshooting
1. 执行`kubectl apply -f ingress_deploy.yml`后，由于忘了事先将镜像导入到本地docker库中, 使得新创建的ingress-nginx命名
空间下的两个pod时又pull相关镜像，然后 由于网络问题，镜像获取失败，两个pod的status一是ImagePullBackOff，
将镜像导入本地库后，status却一直是ImagePullBackOff。 但是通过`systemctl status kubelet/docker`或`journal -xeu kubelet`
都看不到相关日志（原因是因为这两个pod都不是在master部署的，而是部署到了其他node，所以看不到)。

```
NAMESPACE       NAME                                                        READY     STATUS             RESTARTS   AGE
ingress-nginx   default-http-backend-846b65fb5f-4wbxp                       0/1       ImagePullBackOff   0          18m
ingress-nginx   nginx-ingress-controller-d658896cd-jpk7l                    0/1       ImagePullBackOff   0          18m
kube-system     coredns-78fcdf6894-64f7t                                    1/1       Running            0          19h
```

解决方法： 可以通过执行`kubectl replace --force -f ingress_deploy.yaml` 将之前应用的配置删除掉，然后重新创建。解决方法
参考自[stackoverflow][reference]

2. 删除掉后重新创建，但是新建的两个pod的status依然是ImagePullBackOff。
比较懵比，本地docker库中已有这两个镜像，为什么还是会重新拉取。
解决方法：通过执行`kubectl get pods --all-namespaces -o wide`查看pod的更多信息。发现这两个pod不是在master上创建的, 由于
这两个的镜像只是在master上导入到本地docker库了，所以导致出现了拉取镜像失败。将配置重新执行1中的命令替换以后，两个pod就
正常运行了。因为这个问题也导致问题1里查看kubelet/docker的错误日志都找不到相关信息，因为根本没看对地方。

```
NAMESPACE       NAME                                     READY STATUS             RESTARTS   AGE  IP             NODE
ingress-nginx   default-http-backend-846b65fb5f-4wbxp    0/1   ImagePullBackOff   0          19m  10.244.2.25    a01-r06-i18-44-5002314.jcloud.com
ingress-nginx   nginx-ingress-controller-d658896cd-jpk7l 0/1   ImagePullBackOff   0          19m  10.244.1.15    a01-r06-i18-43-5002583.jcloud.com
kube-system     coredns-78fcdf6894-64f7t                 1/1   Running            0          19h  10.244.0.6     a01-r06-i18-41-5002582.jcloud.com
```

[reference]: https://stackoverflow.com/questions/40259178/how-to-restart-kubernetes-pods
