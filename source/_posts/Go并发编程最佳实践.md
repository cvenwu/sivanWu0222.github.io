---
title: Go并发编程最佳实践
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
date: 2021-09-27 16:57:47
summary:
---


# Go并发编程最佳实践

Go语言中提供了非常完善的并发库，所以去写简单并发生产和消费比较简单，只要参考**Go实战**这本书，对着代码修改不断修改就已经可以线上使用了，如果稍微写的复杂一点，我们就需要去看一下专业书籍了，3本书如下：![6j8ExI](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/6j8ExI.png)


中间那本书是一个小册子，相对于左边那本书会偏理论一些，如果想要写一些高性能的无锁算法需要去理解中间一些理论方面的知识，只用sync是不够的，我们还得使用atomic这个之类的，还得理解atomic的内存操作与普通内存操作的顺序，怎样才能够完备的保证顺序不会出现并发的Bug，这是比较底层的API。

右边这本书是以前IBM工程师写的开源书籍，如果想要并发方面更加深入的话，可以去看一下，这里面有大量的理论，

目录：
1. 并发内置数据结构
2. 并发编程模式举例
3. 常见的并发bug
4. 内存模型：主要解析一下官方的那篇happen-before的文档



## 并发内置数据结构



### sync.Once
最简单的就是sync.Once，![oANPeH](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/oANPeH.png)，经常会有很多人去问很多问题，为什么使用atomic为什么使用defer等等，官方比较烦，所以**写了大量的注释**


比如我们的网络编程里面要处理连接，网络连接如果多次close是会触发问题的，所以有很多网络连接，会在自己的connection上面加上Once对象，保证关闭被执行一次。

官方在注释里面写的非常详细，大家多看官方写的注释


### sync.Pool

sync.Pool用例非常非常的多，

![QZes1c](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/QZes1c.png)


优化是后面的内容，但是现在可以先提一下，我们在看pprof中的inuse_objects的时候，有时候会发现某一个对象的in use数目特别多，这种前提就是程序吞吐量比较低，比如我们压测的时候可能只有两千qps，我们希望提高到三四千，但是这时候cpu占用很多， 这时候我们发现gc占用特别高，已经到达了30%，此时我们想要优化GC，按照上节课所讲到的，GC消耗CPU主要就是mark阶段挨个遍历存活的对象，如果我们可以降低存活对象的个数，那么我们就可以降低GC mark阶段CPU的占用了，因此我们此时需要做的就是降低存活对象的数量。

另外一种情况是，如果我们的进程运行在一种非常苛刻的条件下面，只给我们的进程分配两G左右的内存，有时候用了一些内存限制手段，如果超过2gb，进程就会被Kill。但是经过一系列迭代以后，内存占用越来越高，表现在监控图上就是进程RSS占用过高，

其实这两种情况我们都可以用sync.Pool来做优化，基本的用法就是我们做后端请求响应的这种程序，可以在请求开始时候调用一个pool.Get去获取缓存的struct或者slice，请求响应结束时候，调用pool.Put，之后再将我们拿出来的对象放置回去。


sync.Pool在开源项目fasthttp中使用的是最广泛的：[点击查看](https://github.com/valyala/fasthttp/blob/b433ecfcbda586cd6afb80f41ae45082959dfa91/server.go#L402)
因为在性能优化以及内存优化方面做的非常多，所以性能也比几乎所有其他第三方http库和官方库好很多，但是这些优化也是有代价的

sync.Pool结构其实也是比较复杂的，这里有一张结构图：![GGgyAt](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/GGgyAt.png)

我们在应用层里面写了`var objPool = sync.Pool{}`，其实就是在底层给我们生成了一个pool对象，pool对象生成之后一定会被加入到runtime全局的pool对象中，runtime.allPools是一个全局对象，并且是一个数组，每次生成一个pool都会append进去，因此我们并不能够无限生成Pool，因为每次生成一个Pool都会去加入到全局的runtime.allPools这个数组中，并且在操作这个全局数组的时候会进行加锁，所以效率会比较低，如果代码导致这样的问题，那就会存在非常严重的性能问题。

接下来我们看一下Pool结构，
noCopy字段：它里面有一个字段noCopy，runtime里面有很多结构体都有这个字段，为了就是不让我们对结构体进行拷贝操作，因为拷贝之后可能会有bug，比如有的拷贝可能会将内部锁的状态也进行拷贝。有的可能是因为拷贝之后是一个浅拷贝，删除对象的时候就会出问题，
local和localSize是一对：local代表的是一个pool的数组对象，localSize的值就是我们p的数量，此时localSize的值就是我们local数组的长度，
victim：是为了做优化加入的一个特殊的东西，
victimSize：与victim是一对，
New：初始化sync.Pool的时候需要提供一个New函数，

刚才说到的，如果gomaxProcs为4，那么这里就会有一个大小为4的数组，这个数组中的每一个元素都是一个poolLocal，poolLocal里面有一个poolLocalInternal(里面的private类似于cpu的l1 cache之类的，)这样一个字段，这个就是它的一个主字段，另外一个字段基本是用来做对齐的，

我们如果从pool里面去拿取对象，一定是去private里面拿取第一个，但是拿之前要看一下G是在哪一个p上面运行的，去当前的p上面去拿取，如果是p0就会去索引为0的位置上去拿取，然后顺着找到本地的private(只可以放一个元素，类似于我们之前的runnext；如果private为空，那么我们需要去找shared这一个链表了，链表被设计为无锁的)


如果我们往sync.Pool里面放的话，第一步就要往private里面放，如果private已经满的话就要往share里面放，share通过链表实现完全的无锁，比如往里面放的时候会调用pushHead，如果拿走元素就调用popTail，链表的无锁是通过一边是pushHead，另一边是popTail来实现，如果sync.Pool get不到的话还回去victim里面找，也就是Local和victim里面找，如果这两个都找不到，那它就会去其他Pool的share链表里面找，shared是在所有的p之间共享的，对于我们这种情况，我们可以将自己的private理解为l1 cache，将shared理解为l2 cache，其他人的shared可以理解为l3，其实和缓存的设计非常类似


我们看一下如果对sync.Pool进行GC会发生什么：![ZaKZFS](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/ZaKZFS.png)

其实就是相当于将我们之前的Local以及LocalSize平移下来到victim以及victimSize，将我们的local赋值给victim，将localSize赋值给p，之前如果victim以及victimSize有值的话那就直接丢弃掉，是通过这个方式来把以前可能不需要的或者多出来的那些对象慢慢的淘汰掉，如果你现在把他刚替换掉，然后现在又需要从sync.Pool里面Get对象的时候，此时Local是空，就会去victim里面找到，大致流程与我们刚才从Local里面找一样，sync.Pool最早的实现中，shared是有锁的，从1.13开始，锁就被干掉了，变成一个非常诡异的双端链表，可以直接无锁操作。所以早期sync.Pool在GC的时候是完全把里面对象清空掉的，会导致什么问题呢？如果你的程序对sync.Pool重度使用，那么每次gc完成，如果此时发生流量请求数量波动，就会发生应用程序大量阻塞在一个锁上，会有短时间的延迟波动，


## 并发内置数据结构：semaphore 信号量
![yM3TyE](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/yM3TyE.png)


是所有和锁相关的同步结构的基础，底层可以理解为每一个锁其实就是一个wait的链表，但是这个wait链表，runtime要去维护好它，所以就整了一个semtable，是一个定长的数组，每一个元素都是一个叫treap的结构，这个treap其实是tree和head的合成结构，既是一个数又是一个堆

所有和锁相关的同步结构的基础，

-------

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
