---
layout: post
title:  kubernetes安装教程centos7
description: 
modified:   2018-07-13 14:36:20
tags: [kubernetes]
---

## 环境
- 系统: Centos7.1
- 主机:	host		ip				role 
		sre-test-01 192.168.0.18	master
		sre-test-03 192.168.0.20	node


# master部署kubernetes

## kubeadm init 初始化kubernetes集群过程中遇到的问题
执行kubeadm init时需要跟--pod-network-cidr参数来为Pod设置所使用的网络, --kubernetes-version=v1.11.0指定安装的kubernetes
版本不是v1.11,是v1.11.0不然会报无此版本的错误

问题1：由于GFW的问题导致的无法拉取Kubernetes组件镜像。
解决方案： 从Docker Hub上搜索对应组件名字的中转镜像，拉取到主机后，通过docker tag命令将镜像名字改为k8s.gcr.io开头的。
  中转镜像地址：https://hub.docker.com/r/mirrorgooglecontainers/
  修改tag命令： `docker tag docker.io/coredns:1.1.3 k8s.gcr.io/coredns:1.1.3`, 一定要将仓库名和标签都写上.

问题2：通过中转镜像仓库将镜像下载到本地并修改tag以后，执行kubeadm init的过程中，依然有一步会去验证是否已经下载齐了所有
组件的镜像，此时依然会因为GFW问题导致访问超时。
解决方案：此步验证是通过docker pull拉取镜像，因此为docker设置一个代理。首先现在本地跑起来代理服务的client，我用的
shadowsocks, 之后配置docker使用代理.[参考连接][docker proxy]
```
1. mkdir -p /etc/systemd/system/docker.service.d

2. cd /etc/systemd/system/docker.service.d

3. cat <<EOF > https-proxy.conf
[Service]
Environment="HTTP_PROXY=socks5://127.0.0.1:1080/" "HTTPS_PROXY=socks5://127.0.0.1:1080/" "NO_PROXY=localhost,127.0.0.1,docker.io,yanzhe919.mirror.aliyuncs.com,99nkhzdo.mirror.aliyuncs.com,*.aliyuncs.com,*.mirror.aliyuncs.com,registry.docker-cn.com,hub.c.163.com,hub-auth.c.163.com,"
EOF
4. systemctl daemon-reload
5. systemctl restart docker

```


# Node部署kubernetes

## Node加入cluster
安装node节点环境，`kubeadm init`之前的所有安装步骤都要执行
在node节点上执行加入指令, 此加入指令是master上执行完`kubeadm init`之后打印出来的。
```
kubeadm join 192.168.0.18:6443 --token cte914.85ytquwe74t3s7pv --discovery-token-ca-cert-hash sha256:cb8656458e103fa3c7db43619ffea1a01a670b9d0d5b3249fe2a716d7f77a21c
```
- 192.168.0.18:6443 为cluster master上apiserver的地址端口信息，通过`kubectl cluster-info`可获取得到
- cte914.85ytquwe74t3s7pv为参数`--token`的参数值，可通过`kubeadm token list`获取到, 但是token值有效期只有24小时。
- sha256:....为`--discovery-token-ca-cert-hash的参数值`，可通过下面的命令计算得到
```
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```
token失效以后，可以通过执行命令`kubeadm token create --print-join-command`打印出新的加入指令

### 将Node从Cluster中移除
1. 首先在master中删除node
```
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
kubectl delete node <node name>
```
2. 在node上重置 `kubeadm reset`


### 问题1： 按照指令将Node(sre-test-03)加入到cluster以后，在master上执行`kubectl get nodes`时显示status为NotReady
```
NAME          STATUS     ROLES     AGE       VERSION
sre-test-01   Ready      master    1d        v1.11.0
sre-test-03   NotReady   <none>    1h        v1.11.0

```
问题排查: 
 1. 首先查看一下kube-system命名空间下由系统创建的pods的情况，执行`kubectl get pods -o wide --namespace=kube-system`
 ```
 NAMESPACE     NAME                                  READY     STATUS              RESTARTS   AGE       IP             NODE
kube-system   coredns-78fcdf6894-cddqs              1/1       Running             0          1d        10.244.0.4     sre-test-01
kube-system   coredns-78fcdf6894-mxqvn              1/1       Running             0          1d        10.244.0.5     sre-test-01
kube-system   etcd-sre-test-01                      1/1       Running             0          1d        192.168.0.18   sre-test-01
kube-system   kube-apiserver-sre-test-01            1/1       Running             0          1d        192.168.0.18   sre-test-01
kube-system   kube-controller-manager-sre-test-01   1/1       Running             0          1d        192.168.0.18   sre-test-01
kube-system   kube-flannel-ds-ldvks                 1/1       Running             0          1d        192.168.0.18   sre-test-01
kube-system   kube-flannel-ds-slft6                 0/1       Init:0/1            0          14m       192.168.0.20   sre-test-03
kube-system   kube-proxy-slx7w                      0/1       ContainerCreating   0          14m       192.168.0.20   sre-test-03
kube-system   kube-proxy-snppl                      1/1       Running             0          1d        192.168.0.18   sre-test-01
kube-system   kube-scheduler-sre-test-01            1/1       Running             0          1d        192.168.0.18   sre-test-01
 ```
 结果显示运行在node上的kube-flannel-ds-slft6和kube-proxy-slx7w两个pod的状态都不是Running。
 2. 接着在master上查看一下node节点的信息，执行`kubectl describe node sre-test-03`.在结果中发现了此信息
 ```
 Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  OutOfDisk        False   Thu, 19 Jul 2018 10:45:56 +0800   Thu, 19 Jul 2018 09:56:44 +0800   KubeletHasSufficientDisk     kubelet has sufficient disk space available
  MemoryPressure   False   Thu, 19 Jul 2018 10:45:56 +0800   Thu, 19 Jul 2018 09:56:44 +0800   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Thu, 19 Jul 2018 10:45:56 +0800   Thu, 19 Jul 2018 09:56:44 +0800   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Thu, 19 Jul 2018 10:45:56 +0800   Thu, 19 Jul 2018 09:56:44 +0800   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            False   Thu, 19 Jul 2018 10:45:56 +0800   Thu, 19 Jul 2018 09:56:44 +0800   KubeletNotReady              runtime network not ready: NetworkReady=false reason:NetworkPluginNotReady message:docker: network plugin is not ready: cni config uninitialized

 ```
 最后一行显示kubelet的运行环境的网络有问题. 此时确定应该就是node上的kubernetes的网络问题。

 3. 在node上查看一下kubelet的状态，执行`systemctl status kubelet`, 部分结果显示如下
 ```
7月 19 09:16:54 SRE-TEST-03 kubelet[4475]: W0719 09:16:54.621267    4475 cni.go:172] Unable to update cni config: No networks found in /etc/cni/net.d
7月 19 09:16:54 SRE-TEST-03 kubelet[4475]: E0719 09:16:54.621394    4475 kubelet.go:2112] Container runtime network not ready: NetworkReady=false reason:...nitialized
7月 19 09:16:59 SRE-TEST-03 kubelet[4475]: W0719 09:16:59.622249    4475 cni.go:172] Unable to update cni config: No networks found in /etc/cni/net.d
7月 19 09:16:59 SRE-TEST-03 kubelet[4475]: E0719 09:16:59.622329    4475 kubelet.go:2112] Container runtime network not ready: NetworkReady=false reason:...nitialized
7月 19 09:17:03 SRE-TEST-03 kubelet[4475]: E0719 09:17:03.738147    4475 summary.go:102] Failed to get system container stats for "/system.slice/kubelet.service": ...
7月 19 09:17:03 SRE-TEST-03 kubelet[4475]: E0719 09:17:03.738174    4475 summary.go:102] Failed to get system container stats for "/system.slice/docker.s...r.service"
7月 19 09:17:04 SRE-TEST-03 kubelet[4475]: W0719 09:17:04.623477    4475 cni.go:172] Unable to update cni config: No networks found in /etc/cni/net.d
7月 19 09:17:04 SRE-TEST-03 kubelet[4475]: E0719 09:17:04.623962    4475 kubelet.go:2112] Container runtime network not ready: NetworkReady=false reason:...nitialized
7月 19 09:17:09 SRE-TEST-03 kubelet[4475]: W0719 09:17:09.624736    4475 cni.go:172] Unable to update cni config: No networks found in /etc/cni/net.d
7月 19 09:17:09 SRE-TEST-03 kubelet[4475]: E0719 09:17:09.625183    4475 kubelet.go:2112] Container runtime network not ready: NetworkReady=false reason:...nitialized
Hint: Some lines were ellipsized, use -l to show in full.
 ```
 发现确实是网络问题，显示没有cni网络配置。
 4. 在node上执行`journalctl -xeu kubelet`查看一下kubelet在systemd上的日志, 部分输出如下：
 ```
 7月 19 11:00:49 SRE-TEST-03 kubelet[23634]: E0719 11:00:49.479416   23634 remote_runtime.go:92] RunPodSandbox from runtime service failed: rpc error: code = Unknown de
sc = failed pulling image "k8s.gcr.io/pause:3.1": Get https://k8s.gcr.io/v1/_ping: dial tcp 74.125.203.82:443: i/o timeout
7月 19 11:00:49 SRE-TEST-03 kubelet[23634]: E0719 11:00:49.479450   23634 kuberuntime_sandbox.go:56] CreatePodSandbox for pod "kube-proxy-slx7w_kube-system(e7f73bc9-8a
f6-11e8-b02a-fa163edf1c9d)" failed: rpc error: code = Unknown desc = failed pulling image "k8s.gcr.io/pause:3.1": Get https://k8s.gcr.io/v1/_ping: dial tcp 74.125.203.
82:443: i/o timeout
7月 19 11:00:49 SRE-TEST-03 kubelet[23634]: E0719 11:00:49.479460   23634 kuberuntime_manager.go:646] createPodSandbox for pod "kube-proxy-slx7w_kube-system(e7f73bc9-8af6-11e8-b02a-fa163edf1c9d)" failed: rpc error: code = Unknown desc = failed pulling image "k8s.gcr.io/pause:3.1": Get https://k8s.gcr.io/v1/_ping: dial tcp 74.125.203.82:443: i/o timeout
7月 19 11:00:49 SRE-TEST-03 kubelet[23634]: E0719 11:00:49.479511   23634 pod_workers.go:186] Error syncing pod e7f73bc9-8af6-11e8-b02a-fa163edf1c9d ("kube-proxy-slx7w_kube-system(e7f73bc9-8af6-11e8-b02a-fa163edf1c9d)"), skipping: failed to "CreatePodSandbox" for "kube-proxy-slx7w_kube-system(e7f73bc9-8af6-11e8-b02a-fa163edf1c9d)" with CreatePodSandboxError: "CreatePodSandbox for pod \"kube-proxy-slx7w_kube-system(e7f73bc9-8af6-11e8-b02a-fa163edf1c9d)\" failed: rpc error: code = Unknown desc = failed pulling image \"k8s.gcr.io/pause:3.1\": Get https://k8s.gcr.io/v1/_ping: dial tcp 74.125.203.82:443: i/o timeout"
 ```
 其中有错误提示创建kube-proxy-slx7w_kube-system的pod时下载`k8s.gcr.io/paause:3.1`失败，超时。此问题是由于GFW导致无法访问
 k8s.gcr.io， 针对此问题的解决方案是搭建一个代理，然后配置docker走代理下载。

 #### 解决了docker镜像下载问题后，node节点状态是NotReady得以解决。

[docker proxy]: https://blog.yanzhe.tk/2017/11/09/docker-set-proxy/

