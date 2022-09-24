---
title: hexo卸载与更新
author: yirufeng
pin: false
toc: true
mathjax: false
categories:
  - blog
tags:
  - hexo
  - blog
date: 2022-09-21 21:17:42
summary:
---

> 由于博客主题经常更新来加入一些新特性，部分时候需要对hexo版本进行升级，因此本文对hexo卸载与升级进行讲解

## 卸载

1. 进入到博客项目，清除项目下的npm缓存：`rm -rf node_modules`
2. 清除npm自身的缓存：`npm cache clean --force`
3. 卸载hexo：`sudo npm uninstall hexo-cli -g`

## 升级
> 前提：原来hexo的版本是老版本，现在要升级到新版本

1. 执行命令进行升级即可：`sudo npm update hexo`
2. 

<!-- more -->