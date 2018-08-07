---
layout: post
title:  kubernetes集群搭建外部ETCD集群
description: 
modified:   2018-07-31 10:18:16
tags: [kubernetes]
---

## 搭建外部多主机etcd集群

主机:
	- 172.19.18.41
	- 172.19.18.43
	- 172.19.18.44
etcd version: 3.2+


## 源码安装
version: 3.3

在每个主机上按照[build文档][build]进行源码编译, 需要配置`GOPATH`, 并通过`go get -d -v`将依赖包下载下来

1. git clone  https://github.com/coreos/etcd.git
2. cd etcd
3. ./build

安装好以后启动etcd`./bin/etcd`

测试存储`ETCDCTL_API=3 ./bin/etcdctl put foo bar`, 成功输出`OK`, 则证明etcd工作正常

#### Notice: 由于etcdtl使用v3 API去和etcd进行通信，所以一定要设置环境变量`ETCDCTL_API=3`

## rpm安装

etcd version: 3.2.22

安装步骤可参考[多主机部署ETCD集群官方文档][cluster]

在每台主机上安装rpm然后配置, 根据主机IP地址不同要对应修改配置文件里的IP

1. yum install -y file_path
2. 可通过在三个主机上执行下面命令来测试启动etcd集群, 在每个主机上对应的修改IP地址。`--initial-cluster`参数在三个主机上都
相同.参数配置参考[官方文档][cluster]

```
etcd --name etcd1 \
	--initial-advertise-peer-urls http://172.19.19.41:2380 \
	--listen-peer-urls http://172.19.18.41:2380 \
	--listen-client-urls http://172.19.18.41:2379,http://127.0.0.1:2379 \
	--advertise-client-urls http://172.19.18.41:2379 \
	--initial-cluster-token etcd-cluster-sre \
	--initial-cluster etcd1=http://172.19.18.41:2380,etcd2=http://172.19.18.43:2380,etcd3=http://172.19.18.44:2380 \
	--initial-cluster-state new
```

#### Notice:
1. initial-cluster参数后必须跟集群中所有的主机配置的advertise-peer-url
2. advertise-client-urls是用来集群成员，proxy，clients之间通信的，所以不能把url设置为localhost
3. listen-client-urls是设置接受客户端流量的


## 配置集群systemd启动参数
参数配置参考[官方文档][cluster]
1. systemctl enable etcd
2. 修改/etc/etcd/etcd.conf，设置如下内容, 以172.19.18.41为例
```
ETCD_NAME="etcd1"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://172.19.18.41:2380"
ETCD_LISTEN_PEER_URLS="http://172.19.18.41:2380"
ETCD_LISTEN_CLIENT_URLS="http://172.19.18.41:2379,http://localhost:2379"
ETCD_ADVERTISE_CLIENT_URLS="http://172.19.18.41:2379"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-sre"
ETCD_INITIAL_CLUSTER="etcd1=http://172.19.18.41:2380,etcd2=http://172.19.18.43:2380,etcd3=http://172.19.18.44:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
```
3.修改/usr/lib/systemd/system/etcd.service，修改启动参数，设置如下内容，以172.19.18.41为例
```
ExecStart=/bin/bash -c "GOMAXPROCS=$(nproc) /usr/bin/etcd --data-dir=\"${ETCD_DATA_DIR}\" \
--name=\"${ETCD_NAME}\" \
--initial-advertise-peer-urls=\"${ETCD_INITIAL_ADVERTISE_PEER_URLS}\" \
--listen-peer-urls=\"${ETCD_LISTEN_PEER_URLS}\" \
--advertise-client-urls=\"${ETCD_ADVERTISE_CLIENT_URLS}\" \
--initial-cluster-token=\"${ETCD_INITIAL_CLUSTER_TOKEN}\" \
--initial-cluster=\"${ETCD_INITIAL_CLUSTER}\" \
--initial-cluster-state=\"${ETCD_INITIAL_CLUSTER_STATE}\" \
--listen-client-urls=\"${ETCD_LISTEN_CLIENT_URLS}\""
```
4. 执行`systemctl daemon-reload && systemctl start etcd`

#### Notice: 所有主机上的ETCD都启动以后，集群才能正常建立。
#### Notice: 由于使用外部ETCD集群，执行`kubeadm reset`删除集群环境时，不会清空etcd数据，所以需要去etcd手动删除
`etcdctl del "" --prefix`

[build]: https://github.com/coreos/etcd/blob/master/Documentation/dl_build.md
[cluster]: https://github.com/coreos/etcd/blob/master/Documentation/op-guide/clustering.md
