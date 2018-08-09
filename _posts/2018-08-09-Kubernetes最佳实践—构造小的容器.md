---
layout: post
title:  Kubernetes最佳实践—构建小的容器
description: 
modified:   2018-08-09 09:35:56
tags: [kubernetes docker]
---

在使用Kubernetes部署应用前，需要构建此应用的Docker镜像。而使用默认的基础镜像构建新的镜像,镜像文件的过大，会影响应用部
署效率以及带来安全缺陷(sercurity vulnerability)。默认的基础镜像一般都是基于Debian或Ubuntu创建的，具有比较高的兼容性，但
同时也增加了几百MB的额外的存储开销。


通过两种方式减小镜像文件大小

## 1. Small Base Images 使用更小的基础镜像
所使用语言或者技术栈一般都会提供官方镜像, 此镜像会比使用Debian或Ubuntu创建的默认镜像小很多.
例如:
- Node.js
	- Node:8-wheezy		520MB
	- Node:8-slim		225MB
	- Node:8-alpine		65MB
- Go
	- Go:1.9.7			286MB
	- Go:1.9.7-alpine	84MB

因此，在编写Dockerfile的时候，From尽量使用alpine镜像，使用alpine镜像，需要将代码复制到container，并安装依赖。因此需要在
Dockerfile中写出来
```
# old version
FROM node:onbuild
EXPOSE 8080

# new version with using alpine base image
FROM node:alipne
WORKDIR /app
COPY package.json /app/package.json
RUN npm install --production
COPY server.js /app/server.js
EXPOSE 8080
CMD npm start
```

就算所使用语言或者技术栈没有提供官方缩小版的镜像，也可以自己基于原生的Alpine镜像构建自己的镜像。

alpine版本是基于alpine linux(一个面向安全的轻型的Linux发行版)构建的基础镜像，镜像文件很小。

## 2. Builder Pattern 使用Builder Pattern
解释型语言的项目，在运行的时候需要将源码放入解释器进行执行, 因此镜像中需要有解释器，然而编译型语言在运行前已经将源代码
编译为了二进制可执行文件，之后运行则不在需要编译相关的工具，因此镜像中完全可以去除这些和运行无关的编译工具。

为了去除这些非运行相关的编译工具, 需要使用Builder Pattern. 在第一个容器中编译构建代码，将编译好的可执行程序放到第二个
去除非运行相关工具的容器中执行

```
# old version
FROM golang:alpine
WORKDIR /app
ADD . /app
RUN cd /app && go build -o goapp
EXPOSE 8080
ENTRYPOINT ./goapp

# new version with using builder pattern
FROM golang:alpine AS build-env
WORKDIR /app
ADD . /app
RUN cd /app && go build -o goapp

# 使用了原生的alpine基础镜像
FROM alpine
# 原生alpine linux没有安装SSL证书无法使用HTTPS,需要自行安装
RUN apk update & apk add cacertificates && rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=build-env /app/goapp /app
EXPOSE 8080
ENTRYPOINT ./goapp
```

使用Builder Pattern时，会有两个FROM语句，第一个FROM有一个而外的AS关键词。相当于构建个两个镜像，但是第二个镜像可以从第一个
镜像中复制已编译好的二进制可执行文件到第二个镜像中，只是复制这个文件，没有go代码编译相关的工具。
