---
title: Go中的垃圾回收与内存管理
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
date: 2021-09-27 10:46:23
summary:
---


> 本节内容是自己学习 [empGo高级工程师实战营](https://class.imooc.com/sale/golive) 课程中 **Go 语言的内存管理与垃圾回收**一节所做的笔记


开场闲聊：
学习垃圾回收必须要有理论基础，可以看图中所示的三本书籍：![euu5jm](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/euu5jm.png)，曹大比较推荐左边这一本和右边这一本，中间这本和go没有很大的关系并且讲的都是java的东西，而且是更加具体的G1GC，左边那本书的亮点是里面的图比较多，对于我们而言只要将第一部分的算法看完就可以了，也没有多少页，右边这本书的理论比较全，我们也是不需要全部看完，只要挑一些章节也就是和Go相关的标记清扫与并发标记，还有三色双向等


第一本书与第三本书籍内容加起来对我们有用的也就两三百页左右吧，因此我们要学会选择性的去看


目录：
1. 基本概念
2. 进程虚拟内存布局
3. Allocator基础
4. malloc实现
5. Go语言内存分配
6. 垃圾回收基础
7. Go语言垃圾回收
8. GC标记流程


## 第一部分：基本概念

比如我们看内存分配的时候，我们需要问自己两个问题：
1. 内存从哪里来
2. 内存到哪里去？

顺着这两条线我们一点一点跟踪代码就可以理清内存分配的流程

如果我们要看GC的标记流程，我们也要问自己两个问题：
1. 标记对象从哪里来
2. 标记对象到哪里去

如果我们学习gc的清扫，我们就要问自己如下两个问题：
1. 垃圾是从哪里来
2. 垃圾要到哪里去

掌握了这些之后我们就可以知道中间的过程并且通过流向连接起来


基本概念：栈分配与堆分配的概念


任何一门语言上面都有栈分配和堆分配这两个概念，栈分配其实是一种成本非常小的操作，

动画演示：栈上变量的管理，我们知道函数调用的时候有自己的栈帧，栈帧上面所有的变量都是函数的局部变量，我们做函数调用的时候其实就是相当于把栈从高地址空间向低地址空间增长，然后移动一下栈顶的寄存器，当函数调用返回以后，被调用函数栈上的内容其实就都无效了
1. ![gDwGKY](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/gDwGKY.png)
2. 


所以说栈分配是一个非常轻量级的操作，但是堆分配并不是一个轻量级的操作了
![PQYOfe](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/PQYOfe.png)

上图在C语言中就是返回一个局部变量的指针，其实是有问题在里面的，但是为什么Go语言是可以的，这其实是有门道的![lXVvlt](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/lXVvlt.png)，这是因为Go语言中帮助我们做了逃逸分析，当发生类似于之前代码情况的时候，Go语言会将我们看起来是局部变量的内容分配在堆上，堆就是函数返回的时候地址依然是有效的，我们可以直接用Go语言的工具栈直接看逃逸分析的结果

-gcflags表示的是Go complier的flag，有-m表示我们可以看到逃逸分析的结果，如果说局部变量发生了逃逸，比如图中所示的代码m将会被分配在堆上，然后会将逃逸到堆的结果输出出来，如果我们想要

我们可以先看一下为什么会有堆分配这种操作，比如说，在我们的c语言中


## 第二部分：进程虚拟内存布局

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
