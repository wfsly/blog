---
layout: post
title:  git-cheat-sheet
description: 
modified:   2019-09-18 10:25:56
tags: [git]
---

git 指令收集

## git cherry-pick
1. 将某个commit合并到某分支
首先找到commit id，然后切换到那个分支
应用场景，修复线上分支bug，新开hotfix分支，然后cherry-pick commit_id,之后提测通过后，合并到master
`git cherry-pick commit_id`

## git commit
1. 修改最新一次commit message
`git commit --amend`

## git log

1. 查看带分支曲线的提交历史
`git log --graph --pretty=oneline --abbrev-commit`

2. 通过关键字查找历史commit
`git log --grep "key word"`

## git push
1. 强制push覆盖远程分支
`git push --force`

## git show
3. 查看commit的内容
`git show commit_id`

