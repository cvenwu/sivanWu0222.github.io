---
title: 使用docker部署docsify在线网站
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
  - website
tags:
  - docsify
  - website
  - docker
date: 2023-02-20 22:49:24
summary:
---

## 环境准备
1. 一台云服务器（极力推荐），本机也可以
## 创建目录
1. 进入到`~`创建目录`docsify_demo`
## 编写Dockerfile
> 本操作以及后续操作都是以当前目录docsify_demo为准
当前目录下编写`Dockerfile`文件，内容如下：

```dockerfile
FROM node:latest
LABEL description="A demo Dockerfile for build Docsify."
# 克隆仓库
WORKDIR /
RUN git clone https://github.com/sivanWu0222/AlgoBook.git
WORKDIR /AlgoBook/docs
RUN npm install -g docsify-cli@latest
EXPOSE 9001/tcp
ENTRYPOINT docsify serve . -p 9001
```
<!-- more -->

## 创建自动部署脚本

当前目录下编写自动化部署脚本`auto_deploy_docsify.sh`，内容如下

```shell
#!/bin/bash
# 删除之前部署的网站对应的目录
rm -rf ./website
# 克隆仓库, 将会把项目所有内容克隆到当前目录的repo目录下(如果repo目录不存在会创建)
git clone https://github.com/sivanWu0222/AlgoBook.git website
# 将Dockerfile克隆到website目录的docs目录下
cp ./Dockerfile ./website/docs
# 构建docker镜像
docker build -f ./website/docs/Dockerfile -t docsify/demo .
# 运行docker镜像，通过-p来修改默认的3000端口避免端口冲突
# -v表示将:前面的目录(宿主机的目录)映射到容器的/docs目录
docker run -dp 9001:9001 --name=docsify -v $(pwd)/website/docs:/docs docsify/demo
```

运行自动化部署脚本即可成功部署到容器中

## 更新容器

当我们更新了docsify的内容之后，我们需要及时更新容器，编写脚本`auto_update_docs.sh`，内容如下：

```shell
#!/bin/bash
# 0. 获取当前运行的容器id
container_id=`docker ps -a | grep docsify | awk '{print $1}'`
# 1. 获取容器的镜像名
image_name=`docker images | grep docsify | awk '{print $3}'`

# 2. 如果容器不为空
if [ ${container_id} != "" ]; then
    echo "container_id is" ${container_id}
    # 2.1 停止当前运行的docker容器
    docker kill ${container_id}
    echo "succeed to stop container"
    # 2.2 移除停止的docker容器
    docker rm ${container_id}
    echo "succeed to remove container"
fi

# 3. 如果镜像不为空
if [ ${container_id} != "" ]; then
	# 3.1 移除构建出的docker镜像
    docker rmi ${image_name}
    echo "succeed to remove images"
fi

# 4. 重新执行自动部署脚本
./auto_deploy_docsify.sh
```

## 进阶：通过Github仓库的webhook来触发更新容器的脚本
> 在Github中可以在仓库中配置webhook，配置后，当我们push到仓库中时，webhook会给配置的远程地址发送一个请求告知仓库有更新，此时我们就可以利用这个通知去执行本文中的更新容器一节


## 参考
1. [docsify官方网站使用docker部署](https://docsify.js.org/#/deploy?id=docker)