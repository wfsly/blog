---
layout: post
title:  kubernetes集群通过nginx-ingress暴露到公网
description: 
modified:   2018-08-02 17:47:11
tags: [kubernetes]
---

以为部署好了nginx-ingress，就可以通过在ingress配置里写好的域名去访问集群中部署好的服务了。但是too young too naive!

## 暴露ingress-nginx service到公网

而集群中的pod暴露到集群外是通过创建NodePort类型的Service，可以通过NodeIP:NodePort被集群外部访问。nginx-ingress-controller
也是部署在集群中的pod, 所以要想被外网访问nginx-ingress这个应用服务也需要通过创建Service，这个在安装nginx-ingress-congtroller
时已经确认过了，因为创建完nginx-ingress-controller的下一步就是创建一个名为ingress-nginx的Service. ingress-nginx服务在这里
的作用就是通过它提供的反向代理功能，将不同域名或者同一域名下的不同路径，通过为应用创建的Service分发到不同的应用上去。
ingress-nginx Service作为唯一的入口。

但是我们还需要将这个唯一的入口暴露到公网中，所以要想通过域名访问到集群中的各种应用服务，还需要在集群外部搭建一个nginx
将所有的域名请求转发到ingress-nginx这个Service暴露出来的`NodeIP:NodePort`上，这样才能完成外网到Pod应用的访问。


## 外部nginx配置

由于ingress中配置的是域名+路径到具体的Service的访问，因此发送到nginx-ingress服务上的也必须有域名。所以在配置nginx的
请求转发的时候一定要将Host信息也转发过去。

一开始，我只是配置了将所有请求都转发到对应端口上，忽略了Host信息。导致一直请求一直得不到正确的返回。

#### 没有携带Host信息, 总是失败
```
server {
    listen       80;
    server_name  k8s.iaas.jcloud.com;


    location / {
		proxy_pass	http://127.0.0.1:30387;
    }
}
```

#### 携带Host信息, 成功
```
server {
    listen       80;
    server_name  k8s.iaas.jcloud.com;


    location / {
		proxy_pass	http://127.0.0.1:30387;
        proxy_set_header Host $host;
        proxy_redirect default;

    }
}
```

发现Host信息这个问题，还是通过利用curl在master上访问nginx-ingress的时候发现的。

因为一开始知道访问ingress需要有域名，不能是IP访问。所以通过执行`curl -H 'Host:k8s.iaas.jcloud.com' localhost:30387/`来
访问，验证nginx-ingress服务是否正常，以及返回内容是否正确的。 突然才想起来，nginx转发的时候也得将Host转发过去。
