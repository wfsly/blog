---
layout: post
title:  入剖析kubernetes学习笔记8-声明式API
description: 
modified:   2020-03-03 09:55:50
tags: [kubernetes]
---

<!-- TOC -->

[1 声明式API](#1-声明式API)
[2 声明式API原理](#2-声明式API原理)

<!-- /TOC -->


## 声明式API

声明式API独特之处：
1. 所谓声明式，指的是只需要提交一个定义好的API对象来“声明”我所期望的状态是什么样子。
2. 声明式API，允许有多个API写端，以PATCH方式对API对象进行修改，而无需关心本地原始YAML文件的内容

## 声明式API原理

在kubernetes项目中，一个API对象在Etcd中的完整资源路径，是由:Group(API组)、Version(API版本)和Resource(API资源类型)三个部分组成的。
<Group>/<Version>/<Resource>
例如:`/apis/batch/v1/jobs`, `/apis/batch/v2alpha1/cronjobs`

### kubernetes解析Group,Version,Resource
1. 首先，kubernetes会匹配API对象的组
首先需要明确的，对于kubernetes里的核心API对象, 比如Pod, Node等，是不需要Group的（即它们的Group是“”）。所以，这些对于这些API对象来说，kubernetes会直接在api这个层级下面进行进一步的匹配过程。

而对于CronJob等非核心对象，kubernetes就必须在/apis/这个层级里查找对应的Group。
API对象的分类是以对象功能为依据的。
2. 然后kubernetes会进一步匹配到API对象的版本号
在kubernetes中，同一个API对象可以有多个版本，这正是kubernetes进行API版本化管理的重要手段。这样在CronJob的开发过程中，对于影响到用户的变更可以通过升级新版本来处理，从而保证了向后兼容。
3. 最后，kubernetes会匹配API对象的资源类型

### APIServer创建CronJob对象的过程
1. 将编写的CronJob的yaml通过post请求发送给APIServer
APIServer的第一个功能，就是过滤这个请求，并完成一些前置性的工作，比如授权，超时处理，审计等。
2. 然后请求进入Mux和Routes流程，完成APIServer的URL和Handler绑定
3. 接着APIServer最重要的职责来了，根绝yaml，创建一个CronJob对象
在这个过程中，APIServer会进行一个Convert工作，即将yaml文件转换成一个叫做SuperVersion的对象。它正是该API资源类型所有版本的字段全集。这样用户提交的不同版本的yaml文件，就都可以用SuperVersion对象来处理了
4. 接下来，APIServer会先后进行Admission()和Validation()操作
lstio的的Admission Controller和Intializer都属于Admission的内容。Validation负责验证这个对象里的各个字段是否合法，这个被验证过的API对象，都保存在了一个叫Registry的数据结构中。
5. 最后，APIServer会把验证过的API对象转换成用户最初提交的版本，进行序列化操作，并调用Etcd的API保存起来。

由于要同时兼顾性能，API完备性，版本化，向后兼容等很多工程化指标，所以kubernetes团队在APIServer项目中大量使用了Go语言的代码生成功能

## CRD(Custom Resource Definition)
自定义资源类型