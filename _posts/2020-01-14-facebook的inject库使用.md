---
layout: post
title:  facebook的inject库使用
description: 
modified:   2020-01-14 14:48:36
tags: [golang]
---

https://github.com/facebookarchive/inject

## 使用总结

1. 在一个struct中的字段通过inject获得时，此结构体对应的实例也需要inject, 否则找不到想通过inject去获取的实例
2. 要使用注入方式的属性字段不能是私有属性
