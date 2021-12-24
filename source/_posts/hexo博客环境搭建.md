---
title: hexo环境搭建(涵盖mac + win)并将我们的博客同步和发布到github
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
  - blog
tags:
  - hexo
  - blog
date: 2019-03-21 21:17:42
summary:
---
{% note warning, 如果不想使用nvm进行node多版本的管理，直接可以使用去[node中文网](http://nodejs.cn/download/) 下载**LTS版本**(安装的时候记得添加到环境变量选项要勾上)，安装后从第四步开始执行 %}

## 第一步：安装nvm
> 这一步mac和windows有所区别

{% tabs tab-id %}

<!-- tab mac -->

- 执行`curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash` 或 `wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash`
  - 注意：注意后面的`v0.33.8`这是nvm的版本号，[最新版本查看](https://github.com/coreybutler/nvm-windows/releases)
<!-- endtab -->

<!-- tab windows -->

- 参考[Windows下安装及使用nvm](https://www.cnblogs.com/jing-tian/p/11225123.html)在windows下安装nvm

<!-- endtab -->

{% endtabs %}


- 安装完成后关闭终端，然后键入`nvm`看一下是否有输出，如果`command not found`请[查看](https://www.jianshu.com/p/622ad36ee020)
- `nvm ls`查看所有已安装node的版本，并且使用`node use <version>`命令选择一个合适的node用来安装hexo

补充：nvm常用命令介绍
```shell
● nvm install stable  安装最新稳定版 node
● nvm install <version>  安装指定版本，如：安装v4.4.0，nvm install v4.4.0
● nvm uninstall <version>  删除已安装的指定版本，语法与install类似
● nvm use <version>  切换使用指定的版本node
● nvm ls  列出所有安装的版本
● nvm alias default <version>  如： nvm alias default v11.1.0
```

## 第二步：卸载原来的hexo
1. 删除原来的hexo：`npm uninstall -g hexo-cli`

## 第三步：安装node
> 由于hexo必须要用npm安装，hexo安装的版本取决于node的版本

1. 使用nvm选择我们的node版本，如果对应版本没有安装，首先使用nvm安装对应版本的node。`nvm install <version>`
2. 切换到对应的node版本：`npm use <version>`

## 第四步：安装hexo
1. 安装hexo： `npm install -g hexo-cli`

## 第五步：同步并发布自己的博客(CI + CD)
> 这里假设我们的博客文章已经编写完成

这一部分涉及到两部分内容：
1. (备份)同步博客源内容到github：避免之前编写的博客内容丢失
2. (发布)将我们编写的博客发布到github：可以以网页的形式看到我们编写之后的内容

### 具体步骤
1. 在我们的博客根目录下新建`.github`目录，然后进入`.github`目录新建`workflows`目录，进入之后新建`deploy.yml`文件
2. 键入如下内容：
```
name: Build and Deploy
on: 
  push:
    branches:
      - source

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
          npm install
          npm run build
        env:
          CI: false

      - name: Deploy 🚀
        uses: JamesIves/github-pages-deploy-action@releases/v3
        with:
          GITHUB_TOKEN: ${{ secrets.ACCESS_TOKEN }}
          BRANCH: main # The branch the action should deploy to.
          FOLDER: public # The folder the action should deploy.
```
3. 配置ACCESS_TOKEN
   1. 进入[github token页面](https://github.com/settings/tokens)
   2. 点击`generate new token`ranhou
4. 使用git的`add`、`commit`、`push` 命令提交
   1. 注意事项：
      - 博客的源代码存放到 `用户名.github.io`这个仓库下的source分支下
      - 博客的发布流程我们在上面已经配置到了github的action中，github会在我们push到source分支的时候直接拉取代码然后发布到main分支，之后我们就可以通过`用户名.github.io`这个域名进行访问了


## 后续
> 博客搭建好之后，只需要选一个合适的主题，就可以书写自己的博客了

## 参考
1. [GitHub如何配置SSH Key](https://blog.csdn.net/u013778905/article/details/83501204)
2. [Hexo-5.x 与 NexT-8.x 跨版本升级](https://www.imczw.com/post/tech/hexo5-next8-updated.html)
3. [【干货】Luke教你20分钟快速搭建个人博客系列(hexo篇) | 自动化部署在线编辑统统搞定 | 前端必会！](https://www.bilibili.com/video/BV1dt4y1Q7UE?from=search&seid=14792497382015603750)