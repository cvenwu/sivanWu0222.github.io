---
title: consul集群搭建
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
  - 微服务
tags:
  - 微服务
  - consul
date: 2021-05-17 08:54:06
summary:
---



## consul环境搭建

### 方法一：docker安装consul集群
{% folding green, 自己动手采用docker搭建一个consul集群 %}
```shell
# 下载最新的consul镜像
docker pull consul
# 启动我们的第一个consul节点
docker run --name consul1 -d -p 8500:8500 -p 8300:8300 -p 8301:8301 -p 8302:8302 -p 8600:8600 consul agent -server -bootstrap-expect 2 -ui -bind=0.0.0.0 -client=0.0.0.0
# 获取我们第一个启动节点的ip地址：会输出一个ip地址
docker inspect --format '{{ .NetworkSettings.IPAddress }}' consul1
# 启动第二个consul节点
docker run --name consul2 -d -p 8501:8500 consul agent -server -ui -bind=0.0.0.0 -client=0.0.0.0 -join 这里是第一个节点的ip地址
# 启动第三个consul节点
docker run --name consul3 -d -p 8502:8500 consul agent -server -ui -bind=0.0.0.0 -client=0.0.0.0 -join 这里是第一个节点的ip地址
# 查看运行的容器
docker ps
```
之后访问`localhost:8050`就可以进入到我们的consul可视化界面
{% endfolding %}

### 方法二：本机(mac)安装consul：
1. 直接进入[consul官网](https://www.consul.io/downloads)，下载可执行文件，然后解压到`$HOME/Library/consul/`
2. 同时将路径加入到我们的系统环境变量`~/.bash_profile`中
```shell
# add consul
export PATH=$PATH:$GOPATH/bin:$HOME/Library/consul
```
3. 然后刷新我们的配置，此时使用consul执行命令`consul members`来查看我们docker搭建的consul集群

### consul相关命令补充：
1. ![vtxNib](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/vtxNib.png)
2. ![zT7xfI](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zT7xfI.png)

### consul参考资料：
1. [参考1](https://www.liangxiansen.cn/2017/04/06/consul)
2. [参考2](https://blog.csdn.net.yuanyuanispeak/article/details/54880743)
3. [docker安装consul集群](https://www.jianshu.com/p/0fe826b7017f)


<!-- more -->

### 了解服务发现：
在微服务编码中我们服务经常会遇到如下的问题：
1. 客户端连接服务器的时候，IP去掉将无法连接服务器：`conn, err := grpc.Dial("127.0.0.1:10086", grpc.WithInsecure()`
2. 如果先运行客户端再运行服务端，客户端将会报错。

这些问题都需要解决，因此我们需要通过服务发现来解决这些问题

1. 通过服务发现来管理服务：![7pI3Um](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/7pI3Um.png)
2. consul的代码并没有开源：![hjwDSP](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/hjwDSP.png)
3. 故障检测使得如果有服务挂掉，之后请求的时候将会停止访问我们的服务
4. ![25Ol7t](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/25Ol7t.png)
5. 服务注册：就是服务主动去consul那里登记，服务发现就是指请求过来之后去consul那里查询对应的服务，此时就是服务发现
6. ![m7vwPH](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/m7vwPH.png) 
7. ![zlqs9v](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zlqs9v.png)
8. ![gbYtWf](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/gbYtWf.png)
9. ![BoFnOg](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/BoFnOg.png)
10. ![Nbh3Ph](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/Nbh3Ph.png)

### consul概念
1. ![J2kwru](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/J2kwru.png)
2. consul命令参数：![vtxNib](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/vtxNib.png)
3. ![zT7xfI](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zT7xfI.png)

### consul常用命令
1. 查看集群成员：`consul members` ![Pvx6iX](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/Pvx6iX.png)  ![GYuxXb](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/GYuxXb.png)
2. 查看consul版本：`consul version`
3. `consul leave` 用于退出集群
4. 停止Agent：![NEl3cO](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/NEl3cO.png)


### 虚拟机搭建consul集群搭建
> 环境：3个虚拟机

1. 192.168.110.123
2. 192.168.110.148
3. 192.168.110.124


步骤：![FjtqZl](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/FjtqZl.png)
1. 192.168.110.123 主机执行命令：`consul agent -server -bootstrap-expect 2 -data-dir /tmp/consul -node=n1 -bind=192.168.110.123 -ui -config-dir /etc/consul.d -rejoin -join 192.168.110.123 -client 0.0.0.0` ![VNkw1J](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/VNkw1J.png)
2. 192.168.110.148 主机执行命令：`consul agent -server -bootstrap-expect 2 -data-dir /tmp/consul -node=n2 -bind=192.168.110.148 -ui -rejoin -join 192.168.110.123`  ![VnyBD7](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/VnyBD7.png) ： ![URYZtv](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/URYZtv.png)   访问：![94F8s8](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/94F8s8.png)
3. 148机器访问：![TppyO2](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/TppyO2.png)
4. 192.168.110.124主机执行命令： `consul agent -data-dir /tmp/consul -node=n3 -bind=192.168.110.124 -config-dir /etc/consuld.d -rejoin -join 192.168.110.123` + ![qFexDB](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/qFexDB.png)
5. 148机器访问：![RbrG6L](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/RbrG6L.png)


### consul 服务注册
1. ![tp72FN](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/tp72FN.png)
2. ![1fRIrx](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/1fRIrx.png)
3. 测试程序：![1J8DIk](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/1J8DIk.png)


在micro中我们不需要手动写consul的配置文件

### consul扩展
1. ![xv7foa](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/xv7foa.png)
2. consul架构图：![UwSjSy](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/UwSjSy.png) 如果要跨域（图中的黑色）：通过网络进行连接。
3. ![9ZWjlz](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/9ZWjlz.png)
4. ![JPZ2Ag](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/JPZ2Ag.png)
5. ![zU0oLv](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zU0oLv.png)


## 参考
1. [Consul节点创建与集群的搭建（含单机多节点集群）](https://www.jianshu.com/p/c6644fa98b8a)