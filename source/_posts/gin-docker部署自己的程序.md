---
title: gin+docker部署Golang应用
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
  - go
  - 
tags:
  - docker
  - go
date: 2021-07-23 16:28:07
summary:
---

> 使用gin编写Go的后端程序，然后使用docker打包成镜像并在我们的阿里云ECS上进行部署


## 编写Go后端程序
项目目录如下：
```
go-web
├── go.mod
├── main.go
├── Dockerfile
```

> main.go文件内容如下：

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
	"time"
)

/**
 * @Author: yirufeng
 * @Date: 2021/7/10 9:04 下午
 * @Desc:
 **/

type User struct {
	Username string `json:"username"`
}

func main() {
	engine := gin.Default()

	engine.GET("/", func(c *gin.Context) {
		startTime := time.Now()

		c.JSON(http.StatusOK, gin.H{
			"method":         http.MethodGet,
			"elapsedTime/ms": time.Since(startTime).Milliseconds(),
		})
	})

	engine.POST("/", func(c *gin.Context) {
		startTime := time.Now()

		var u User
		err := c.BindJSON(&u)
		if err != nil {
			c.JSON(http.StatusOK, gin.H{
				"error": err.Error(),
			})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"method":         http.MethodPost,
			"elapsedTime/ms": time.Since(startTime).Milliseconds(),
			"username":       u.Username,
		})
	})

	engine.Run(":8081")
}
```

<!-- more -->

## 构建镜像
1. 在项目根目录下编写`Dockerfile`文件
2. 使用编写好的`Dockerfile`构建镜像
   1. 执行命令：`docker build -t first_go .`：`-t` 后面指定的是打包出来的镜像名字`first_go` 并且`.`表示从当前目录下的`Dockerfile`进行构建

> 什么是Dockerfile：Dockerfile 文件是用于定义 Docker 镜像生成流程的配置文件，文件内容是一条条指令，每一条指令构建一层，因此每一条指令的内容，就是描述该层应当如何构建；这些指令应用于基础镜像并最终创建一个新的镜像。你可以认为用于快速创建自定义的 Docker 镜像


之前的Dockerfile
```
FROM golang:1.14 as mod
ENV GOPROXY https://goproxy.cn
WORKDIR /root/

COPY ./ ./

COPY go.mod ./
RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o main main.go

EXPOSE 8081
ENTRYPOINT ["./main"]
```

**由于Golang基础镜像太大**，因此推荐在本地编译出二进制之后直接在镜像里面拷贝二进制即可，因此最后的`Dockerfile`如下：
```
FROM alpine:latest
COPY ./main /main
EXPOSE 8081
CMD ["./main"]
```

## 上传镜像到docker hub
1. 创建docker hub的账号：熟记用户名与密码，后面我们需要在本机上面进行配置
2. 本机上使用`docker login -u dockerhub的用户名 -p dockerhub的密码`登录到dockerhub
3. 给我们本地构建出的镜像打上tag：`docker tag 镜像名 用户名/镜像名`
4. 上传镜像：`docker push 用户名/镜像名`

## 服务器下载并运行镜像
1. 登入服务器
2. 下载镜像：`docker pull 用户名/镜像名`
3. 运行镜像：`docker run -p 主机端口:我们镜像中的端口 -d 用户名/镜像` 就可以在端口映射之后使用后台运行的方式运行起来我们的应用

<!-- more -->

## 客户端访问
> 这里使用curl模拟客户端

直接使用命令`curl -d '{"username":"123"} -X POST' 服务器的IP:8081`，将会向指定IP的服务器携带着数据`username=123`发送POST请求

返回的结果如下：![2XoJ2J](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/2XoJ2J.png)

## References


1. [将Golang应用部署到Docker](https://eddycjy.gitbook.io/golang/di-3-ke-gin/golang-docker#chuang-jian-chao-xiao-de-golang-jing-xiang)：讲解了docker镜像依赖的配置文件以及docker镜像中如何与我们的mysql镜像进行连接
2. [使用 Docker 构建 Go 应用](https://basefas.github.io/2019/09/24/%E4%BD%BF%E7%94%A8%20Docker%20%E6%9E%84%E5%BB%BA%20Go%20%E5%BA%94%E7%94%A8/)
3. [Docker命令大全](https://www.runoob.com/docker/docker-command-manual.html)
4. [Docker build 命令](https://www.runoob.com/docker/docker-build-command.html)
5. [Docker 将go项目打包成Docker镜像](https://www.cnblogs.com/aaronthon/p/13494839.html)
6. [Docker镜像推送（push）到Docker Hub](https://blog.csdn.net/u013258415/article/details/80050956/)
7. [如何将自己的镜像上传到Docker hub上](https://blog.csdn.net/qq_39629343/article/details/80158275)
8. [docker中的命令参数（小白常用）](https://www.cnblogs.com/JMLiu/p/10277482.html)
9. [curl命令使用](https://mp.weixin.qq.com/s/N-_jsA6eoM0f_7LCM-il5A)
10. [Docker 创建镜像、修改、上传镜像](https://www.cnblogs.com/lsgxeva/p/8746644.html)