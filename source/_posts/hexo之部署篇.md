---
title: hexo之部署篇
author: yirufeng
pin: false
toc: true
mathjax: false
sidebar:
  - blogger
  - webinfo
  - tagcloud
  - category
categories:
  - 网站搭建
tags:
  - hexo
date: 2022-10-02 10:15:26
summary:
---

书接上回，我们讲解了如何搭建hexo所需的博客环境，在环境搭建好之后，奋笔疾书终要呈现给他人，此时就需要知道如何部署到博客了。。。

本文部署的原理是将hexo博客源码推送到Github后，工作流自动编译出html文件到master分支，同时推送到腾讯云轻量应用服务器实现国内国外双部署(国内用户可以秒开博客)

## 前提环境
1. 拥有一台腾讯云轻量应用服务器
2. 按照上文提到的步骤搭建好hexo博客环境

## 腾讯云轻量应用服务器

> 默认已经安装了git

### 创建用户并进行配置
1. `adduser git`
2. `chmod 740 /etc/sudoers`
3. `vim /etc/sudoers` 并在`root    ALL=(ALL)       ALL`下面一行加入：`git     ALL=(ALL)       ALL`
4. `chmod 400 /etc/sudoers`
5. 设置密码: `sudo passwd git`
6. `su git`
7. `mkdir ~/.ssh`
8. 本地机器上执行命令：`ssh-keygen -t rsa -C "邮箱"`生成ssh文件，注意一定要指定生成的ssh文件名否则会覆盖之前的ssh文件（另需要注意的是ssh的时候）
9. 远程机器上执行：`vim ~/.ssh/authorized_keys` 将公钥文件的内容拷贝进去
10. 本地机器上执行：`ssh -v git@机器地址 -i 公钥文件名`发现可以登录到机器上
11. 



## 部署流程

### 编写工作流文件

```yaml
# 当有改动推送到master分支时，启动Action
name: 自动部署

on:
  push:
    branches:
      - source #2020年10月后github新建仓库默认分支改为main，注意更改

  release:
    types:
      - published

jobs:
  checkout:
    runs-on: ubuntu-latest
    steps:
      - name: 检查分支
        uses: actions/checkout@v2
        with:
          ref: master #2020年10月后github新建仓库默认分支改为main，注意更改

      - name: 安装 Node
        uses: actions/setup-node@v1
        with:
          node-version: "12.x"

      - name: 安装 Hexo
        run: |
          export TZ='Asia/Shanghai'
          npm install hexo-cli -g

      - name: 缓存 Hexo
        uses: actions/cache@v1
        id: cache
        with:
          path: node_modules
          key: ${{runner.OS}}-${{hashFiles('**/package-lock.json')}}

      - name: 安装依赖
        if: steps.cache.outputs.cache-hit != 'true'
        run: |
          npm install --save

      - name: 生成静态文件
        run: |
          hexo clean
          hexo generate

      - name: 部署到github pages
        run: |
          git config --global user.name "sivanWu0222"
          git config --global user.email "yirufeng@foxmail.com"
          # git clone https://github.com/xxxxx/xxxx.github.io.git .deploy_git
          # 此处务必用HTTPS链接。SSH链接可能有权限报错的隐患
          # =====注意.deploy_git前面有个空格=====
          # 这行指令的目的是clone博客静态文件仓库，防止Hexo推送时覆盖整个静态文件仓库，而是只推送有更改的文件
          # 我注释掉了是为了刷新整个仓库，也可以选择不注释掉，但是可能出现没有识别到的情况
          hexo deploy

      - name: 部署到云服务器
        uses: cross-the-world/scp-pipeline@master
        with:
          host: ${{ secrets.USER_HOST }}
          user: ${{ secrets.USER_NAME }}
          pass: ${{ secrets.USER_PASS }}
          connect_timeout: 10s
          local: './.deploy_git/*'
          remote: yirufeng@43.154.207.212:/home/git/blog.git

```

老旧的yaml
```yaml
name: Build and Deploy
on: [push]
jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout 🛎️
        uses: actions/checkout@v2 # If you're using actions/checkout@v2 you must set persist-credentials to false in most cases for the deployment to work correctly.
        with:
          persist-credentials: false

      - name: Install and Build 🔧 # This example project is built using npm and outputs the result to the 'build' folder. Replace with the commands required to build your project, or remove this step entirely if your site is pre-built.
        run: |
          npm install --force
          npm run build
        env:
          CI: false

      - name: Deploy 🚀
        uses: JamesIves/github-pages-deploy-action@releases/v4
        with:
          GITHUB_TOKEN: ${{ secrets.ACCESS_TOKEN }}
          BRANCH: master # The branch the action should deploy to.
          FOLDER: public # The folder the action should deploy.
```

<!-- more -->


## 参考文章
1. [手动部署到腾讯云轻量应用服务器](https://yyyzyyyz.cn/posts/45dafe31d273/)
2. 

