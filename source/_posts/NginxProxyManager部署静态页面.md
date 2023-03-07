---
title: Nginx Proxy Manager部署静态页面
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
  - docker
  - website
date: 2023-02-26 22:46:30
summary:
---

1. 首先查看自己部署nginx-proxy-manager的docker-compose.yml，位于`/opt/docker/NginxProxyManager`目录下
    ```yaml
    version: '3'
    services:
      app:
        image: 'jc21/nginx-proxy-manager:latest'
        network_mode: "host"
        restart: always
        ports:
          # Public HTTP Port:
          - '80:80'
          # Public HTTPS Port:
          - '443:443'
          # Admin Web Port:
          - '81:81'
          # Add any other Stream port you want to expose
          # - '21:21' # FTP
        environment:
          DISABLE_IPV6: 'true'
          # These are the settings to access your db
          # If you would rather use Sqlite uncomment this
          # and remove all DB_MYSQL_* lines above
          DB_SQLITE_FILE: "/data/database.sqlite"
          # Uncomment this if IPv6 is not enabled on your host
          # DISABLE_IPV6: 'true'
        volumes:
          # - ./Users/brittanysalas/.config/production.json
          - ./data:/data
          - ./letsencrypt:/etc/letsencrypt
    ```
2. 查看volume发现将当前目录下的data目录映射到容器的/data，于是在`./data`下创建`yirufeng.top`目录，
3. 在`yirufeng.top`目录下创建index.html文件，内容如下：
<!-- more -->
    ```html
    hello world
    ```
4. 进入nginx-proxy-manager管理页面:
    1. 点击`Proxy Host`并新建：
        1. 输入域名
        2. Scheme选择http
        3. IP输入0.0.0.0
        4. Port输入80
    2. Advanced标签卡新建如下内容：
        ```
        location / {
            root /data/yirufeng.top;
        }
        ```
5. 打开浏览器，访问`ip`即可

## 参考文章
1. [Host a Static Site on NGINX Proxy Manager (NPM)](https://dimensionquest.net/2021/02/host-static-site-on-npm/)
