---
 layout: post
 title: django项目使用设置pytest跑单元测试
 date: 2018-01-29 16:30:37
 tags: [django]
---

单元测试真的很重要！很重要！很重要！

在现在实习的公司，所接触的组里的django项目，工程质量真的是连我这实习生都看不下去了。没有规矩不成方圆，自己任性的写代码
给后边接收项目继续维护的人带来了指数级的难度和嫌弃。即使你想给重新组织，发现根本是心有余而力不足，因为连个基本的单元测
试都没有，你怎么敢下手。

目前测试相关的python库有python内置库unittest，nose(测试发现并运行测试)，pytest(目前一个比较流行的测试项目)，mock(模拟
线上环境的一些不容易在本地实现的接口或者行为)。

## 使用pytest而不是django自带的test有哪些优势
1. Less boilerplate: no need to import unittest, create a subclass with methods. Just write tests as regular functions.
更少的引用文件：不需要去导入unittest，创建一个带有若干test开头函数的子类，只需要写正常的测试函数就行
2. Manage test dependencies with fixtures.
3. Database re-use: no need to re-create the test database for every test run.
数据库重用：不需要为每次跑测试重建数据库
4. Run tests in multiple processes for increased speed.
多进程跑测试，更加快速
5. There are a lot of other nice plugins available for pytest.
更丰富的插件支持
6. Easy switching: Existing unittest-style tests will still work without any modifications.
简单切换：不需要修改就可以支持使用python自带unittest编写的测试


本文记录一下在django项目中加入pytest的过程。

## install pytest and pytest-django
pytest-django是一个pytest针对django项目的插件，提供方便有用的工具去测试django代码。现在比较流行的虚拟环境管理工具pipenv
安装pytest-django会自动安装依赖pytest
`pipenv install pytest-django`

## create pytest.ini
单纯的在项目virtualenv中安装pytest，然后按照pytest的要求在`test_*.py`文件中写测试语句，是没法使用django下的模块的.需要
让pytest知道DJANGO__SETTINGS_MODULE。在项目根目录下新建一个pytest.ini配置文件，加入下面的内容
```ini
[pytest]
DJANGO_SETTINGS_MODULE = cmonitor.test_settings
# python_files = tests.py test_*.py *_tests.py
```
设置DJANGO_SETTINGS_MODULE让pytest知道django项目的模块配置, 设置python_files让pytest监测所有test相关文件，包含django自带
测试文件, 其实可以按照pytest的文件组织形式，只写`test_*.py`的测试文件，并且都放在tests文件夹下

然后执行`pytest`就可以跑单元测试了。
