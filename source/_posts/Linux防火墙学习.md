---
title: Linux防火墙学习
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
  - null
tags:
  - null
  - null
date: 2021-07-28 17:53:41
summary:
---


通过防火墙限制哪些用户或者哪些IP可以访问我们提供的服务，以此来保护我们的服务可以更加安全的运行，防火墙默认是关闭的状态，因此我们要学会开启防火墙，防火墙有哪些基本功能这样才可以更加方便的使用我们自己的服务。  

除了防火墙的分类，Linux中使用最广泛的软件防火墙是iptables，iptables中最重要的概念是表和链，着重于如何控制，其中有两个表是我们重点掌握的，一个是filter表，另外一个是nat表，还有iptables中有自己的配置文件，配置文件中写了什么内容我们要去掌握，除了Iptables，centos7被封装成了firewallD服务，用起来会比iptables更加简洁，因此也会讲解一下firewallD如何使用。

Linux中防火墙的分类：
1. 软件防火墙：数据包的过滤，比如说是否允许某一个IP或者某一个端口进入到主机，是否某一个数据包进行转发。软件防火墙又可以分为如下几类：
   1. 包过滤防火墙：控制的比较宽泛，效率也就会很高，比如控制访问IP，但是不能限制用户
   2. 应用层防火墙：控制应用程序的具体行为控制的更加细致，比如控制访问时间
2. 硬件防火墙：用来防御DDos攻击，流量攻击很大我们会使用硬件防火墙来防护。除此之外硬件防火墙也会兼顾一些数据包的过滤功能。

iptables就是软件防火墙中的包过滤防火墙，主要是用于对IP,Port,常见的TCP,UDP以及ICMP进行控制
centos6下面默认就是iptables,我们使用的是iptables中的接口，真正包过滤的是内核中完成的，内核中有一个netfilter模块来完成，iptables就是一个控制器，类似于我们给netfilter上面包了一层皮。


为什么centos7使用firewallD：
1. iptables规则虽然清晰，但是需要记得的参数很多
2. 控制的时候是一条一条去控制
3. 需要我们去看多条控制顺序的问题 

因此centos7重新写了iptables的控制界面，叫做firewallD，会将自己的规则转换成iptables的规则，然后再交给Netfilter

iptables中的表和链：
- 表：filter，nat，mangle，raw。最主要两个就是filter和nat，另外两个是确定功能
- 链：INPUT OUTPUT FORWARD PREROUTING POSTROUTING

过滤的时候会有过滤的方向，比如我们提供服务，客户端向服务端发起连接，这个方向叫做进入服务端的方向

我们通过服务器向客户端发起的方向叫做出的方向，这两个方向如果通过一个规则进行控制的话，就会显得规则很死板，所以还发明了一个规则量的概念，也就是INPUT规则链，OUTPUT规则链，还有一个FORWARD规则链，也就是说我们的数据包经过iptables所在的主机，然后通过forward将数据包转发给其他的服务器上，作为单独的一个软件存在。
INPUT规则链：表示外部请求进入当前这台主机
OUTPUT规则链：当前主机发出去的数据包要用OUTPUT进行过滤
FORWARD规则链：表示经过当前主机转发给其他主机时候的用FORWARD进行过滤

PREROUTING叫做路由前转换，我们之前的课程讲过路由就是选择rule，也就是选择你的路由之后的目的地址，
POSTROUTING叫做路由后转换，也就是选择之后做一个预处理，也就是控制源地址。

nat主要是做网络地址转换的，比如通过nat表将内网IP转换到公网的IP地址，此时就可以访问到公网的服务器了。



iptables的filter表：`iptables -t filter 命令 规则链 规则`：

iptables -t filter是告诉iptables我现在要做一些过滤，命令选项是不同的过滤条件，比如根据服务的端口限制源端口的访问，命令主要是用来规则的查看，添加和删除，规则的调整，叫做iptables的命令，
filter声明我们要去做数据包过滤这件事，命令告诉具体要做什么也就是添加后面的规则还是删除后面的规则，
规则链表示具体过滤的规则是什么方向的，比如想从进入过滤还是想从出去过滤，
规则表示我们具体要做什么事情。比如限制进来的数据，可以使用INPUT规则链，进来的数据限制哪一个IP哪一个端口哪一个协议，这些是规则，规则后面其实还有一部分我们叫做动作，动作表示我们具体要做什么事情，比如我们是允许规则匹配的通过呢，还是不让规则匹配的通过呢，这些就是我们的iptables的一些命令可以做到的事情。



终端演示iptables的使用：
```shell
# 使用iptables做过滤
iptables -t filter 命令

# 命令：如果是-L，表示已经完成的过滤功能有哪些
# 使用iptables做地址转换
iptables -t nat

# -A表示方向，-s表示限制哪一个源IP可以进来，是允许还是拒绝呢，通过-j ACCEPT来表示允许
iptables -t filter -A INPUT -s 10.0.0.1 -j ACCEPT

# 当我们使用iptables -t filter -L展示我们过滤的规则的时候，展示的ip如果有域名会去找对应的域名，所以会卡一下
iptables -t filter -nL
# 因此我们可以使用参数表示我们只是展示IP不展示我们的域名，因为展示域名太费时。
# 使用v可以显示更加详细的信息
iptables -t filter -nLv


# 我们使用iptables的时候会有一些便捷的方式，也就是如果我们
```


103看到01:34







[文章头部frot-matter编写参考](https://xaoxuu.com/wiki/volantis/page-settings/front-matter/)


所有样式来源于：https://xaoxuu.com/wiki/volantis/tag-plugins/

## issue标签
[参考](https://xaoxuu.com/wiki/volantis/tag-plugins/issues/)

{% issues timeline | api=https://gitee.com/api/v5/repos/xaoxuu/timeline/issues?state=open&creator=xaoxuu&sort=created&direction=desc&page=1&per_page=100 %}


## 相册

### 一行一图
{% gallery %}
![图片描述](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/41F215B9-261F-48B4-80B5-4E86E165259E.jpeg)
{% endgallery %}

### 一行多图

{% gallery %}
![图片描述](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/B18FCBB3-67FD-48CC-B4F3-457BA145F17A.jpeg)
![图片描述](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/67239FBB-E15D-4F4F-8EE8-0F1C9F3C4E7C.jpeg)
![图片描述](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/00E0F0ED-9F1C-407A-9AA6-545649D919F4.jpeg)
{% endgallery %}

### 多行多图

{% gallery stretch, 4 %}
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/B951AE18-D431-417F-B3FE-A382403FF21B.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/AEB33F9D-7294-4CF1-B8C5-3020748A9D45.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/250662D4-5A21-4AAA-BB63-CD25CF97CFF1.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/10A0FCE5-36A1-4AD0-8CF0-019259A89E03.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/B951AE18-D431-417F-B3FE-A382403FF21B.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/AEB33F9D-7294-4CF1-B8C5-3020748A9D45.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/250662D4-5A21-4AAA-BB63-CD25CF97CFF1.jpeg)
![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/landscape/10A0FCE5-36A1-4AD0-8CF0-019259A89E03.jpeg)
{% endgallery %}


## github卡片标签

| {% ghcard xaoxuu %}                | {% ghcard xaoxuu, theme=vue %}             |
| ---------------------------------- | ------------------------------------------ |
| {% ghcard xaoxuu, theme=buefy %}   | {% ghcard xaoxuu, theme=solarized-light %} |
| {% ghcard xaoxuu, theme=onedark %} | {% ghcard xaoxuu, theme=solarized-dark %}  |
| {% ghcard xaoxuu, theme=algolia %} | {% ghcard xaoxuu, theme=calm %}            |


| {% ghcard volantis-x/hexo-theme-volantis %}                | {% ghcard volantis-x/hexo-theme-volantis, theme=vue %}             |
| ---------------------------------------------------------- | ------------------------------------------------------------------ |
| {% ghcard volantis-x/hexo-theme-volantis, theme=buefy %}   | {% ghcard volantis-x/hexo-theme-volantis, theme=solarized-light %} |
| {% ghcard volantis-x/hexo-theme-volantis, theme=onedark %} | {% ghcard volantis-x/hexo-theme-volantis, theme=solarized-dark %}  |
| {% ghcard volantis-x/hexo-theme-volantis, theme=algolia %} | {% ghcard volantis-x/hexo-theme-volantis, theme=calm %}            |

## 分栏标签

{% tabs tab-id %}

<!-- tab 栏目1 -->

。。。

<!-- endtab -->

<!-- tab 栏目2 -->

！！！

<!-- endtab -->

{% endtabs %}

## 引用标签


{% note, 可以在配置文件中设置默认样式，为简单的一句话提供最的简便写法。 %}
{% note quote, note quote 适合引用一段话 %}
{% note info, note info 默认主题色，适合中性的信息 %}
{% note warning, note warning 默认黄色，适合警告性的信息 %}
{% note danger, note error/danger 默认红色，适合危险性的信息 %}
{% note success, note done/success 默认绿色，适合正确操作的信息 %}


{% note radiation, note radiation 默认样式 %}
{% note radiation yellow, note radiation yellow 可以加上颜色 %}
{% note bug red, note bug red 说明还存在的一些故障 %}
{% note link green, note link green 可以放置一些链接 %}
{% note paperclip blue, note paperclip blue 放置一些附件链接 %}
{% note todo, note todo 待办事项 %}
{% note guide clear, note guide clear 可以加上一段向导 %}
{% note download, note download 可以放置下载链接 %}
{% note message gray, note message gray 一段消息 %}
{% note up, note up 可以说明如何进行更新 %}
{% note undo light, note undo light 可以说明如何撤销或者回退 %}

## 引用块标签

{% noteblock, 标题（可选） %}

Windows 10不是為所有人設計,而是為每個人設計

{% noteblock done %}
嵌套测试： 请坐和放宽，我正在帮你搞定一切...
{% endnoteblock %}

{% folding yellow, Folding 测试： 点击查看更多 %}

{% note warning, 不要说我们没有警告过你 %}
{% noteblock bug red %}
我们都有不顺利的时候
{% endnoteblock %}

{% endfolding %}
{% endnoteblock %}

## 单选列表
{% radio 纯文本测试 %}
{% radio checked, 支持简单的 [markdown](https://guides.github.com/features/mastering-markdown/) 语法 %}
{% radio red, 支持自定义颜色 %}
{% radio green, 绿色 %}
{% radio yellow, 黄色 %}
{% radio cyan, 青色 %}
{% radio blue, 蓝色 %}

## 多选列表

{% checkbox 纯文本测试 %}
{% checkbox checked, 支持简单的 [markdown](https://guides.github.com/features/mastering-markdown/) 语法 %}
{% checkbox red, 支持自定义颜色 %}
{% checkbox green checked, 绿色 + 默认选中 %}
{% checkbox yellow checked, 黄色 + 默认选中 %}
{% checkbox cyan checked, 青色 + 默认选中 %}
{% checkbox blue checked, 蓝色 + 默认选中 %}
{% checkbox plus green checked, 增加 %}
{% checkbox minus yellow checked, 减少 %}
{% checkbox times red checked, 叉 %}


## 时间线

{% timeline 时间线标题（可选） %}

{% timenode 时间节点（标题） %}

正文内容

{% endtimenode %}

{% timenode 时间节点（标题） %}

正文内容

{% endtimenode %}

{% endtimeline %}

## 网站卡片标签

{% sitegroup %}
{% site xaoxuu, url=https://xaoxuu.com, screenshot=https://i.loli.net/2020/08/21/VuSwWZ1xAeUHEBC.jpg, avatar=https://cdn.jsdelivr.net/gh/xaoxuu/cdn-assets/avatar/avatar.png, description=简约风格 %}
{% site inkss, url=https://inkss.cn, screenshot=https://i.loli.net/2020/08/21/Vzbu3i8fXs6Nh5Y.jpg, avatar=https://cdn.jsdelivr.net/gh/inkss/common@master/static/web/avatar.jpg, description=这是一段关于这个网站的描述文字 %}
{% site MHuiG, url=https://blog.mhuig.top, screenshot=https://i.loli.net/2020/08/22/d24zpPlhLYWX6D1.png, avatar=https://cdn.jsdelivr.net/gh/MHuiG/imgbed@master/data/p.png, description=这是一段关于这个网站的描述文字 %}
{% site Colsrch, url=https://colsrch.top, screenshot=https://i.loli.net/2020/08/22/dFRWXm52OVu8qfK.png, avatar=https://cdn.jsdelivr.net/gh/Colsrch/images/Colsrch/avatar.jpg, description=这是一段关于这个网站的描述文字 %}
{% site Linhk1606, url=https://linhk1606.github.io, screenshot=https://i.loli.net/2020/08/21/3PmGLCKicnfow1x.png, avatar=https://i.loli.net/2020/02/09/PN7I5RJfFtA93r2.png, description=这是一段关于这个网站的描述文字 %}
{% endsitegroup %}


{% folding 查看图片测试 %}

![](https://cdn.jsdelivr.net/gh/volantis-x/cdn-wallpaper/abstract/41F215B9-261F-48B4-80B5-4E86E165259E.jpeg)

{% endfolding %}

{% folding cyan open, 查看默认打开的折叠框 %}

这是一个默认打开的折叠框。

{% endfolding %}

{% folding green, 查看代码测试 %}

{% endfolding %}

{% folding yellow, 查看列表测试 %}

- haha
- hehe

{% endfolding %}

{% folding red, 查看嵌套测试 %}

{% folding blue, 查看嵌套测试2 %}

{% folding 查看嵌套测试3 %}

hahaha <span><img src='https://cdn.jsdelivr.net/gh/volantis-x/cdn-emoji/tieba/%E6%BB%91%E7%A8%BD.png' style='height:24px'></span>

{% endfolding %}

{% endfolding %}

{% endfolding %}
