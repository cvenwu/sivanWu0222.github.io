---
title: Go中神奇的内置数据结构
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
tags:
  - go
date: 2021-09-26 09:26:17
summary:
---
> 本节内容是自己学习 [empGo高级工程师实战营](https://class.imooc.com/sale/golive) 课程中**神奇的内置数据结构**一节所做的笔记

## 概览

概览图：![y3h5kk](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/y3h5kk.png)

1. semaphore是信号量，是所有锁实现的基础，iface与eface是interface底层实现相关的
2. netpoll就是我们之前讲到的runtime的四座大山，里面也有一些自定义数据结构，会在之后讲网络编程或者web框架的时候说
3. sync是同步相关的，sync.Mutex是互斥锁相关的，sync.Pool是对象池，sync.Once必须只在只能初始化一次的函数中使用，waitgroup是汇集多个并发执行的结果
4. os比较简单，因为最复杂的在底层进行了封装，我们是看不到的
5. 内存分配会专门在gc中讲解
6. context是`Go 1.6`增加的数据结构，也是值得去讲的

## channel

### 两种创建方式
1. 不带缓冲的：其实是有buffer的特殊情况，可以理解为buffer size为0的buffered chan。`ch := make(chan int)`
2. 带缓冲的：会生成一个hchan数据结构，dataqsize(队列的大小)将会是我们定义的缓冲区的大小，`ch := make(chan int, 3)`

### channel结构
> 如下的hchan结构体就是我们channel的结构，点击查看[channel源码](https://github.com/golang/go/blob/aeea5bacbf79fb945edbeac6cd7630dd70c4d9ce/src/runtime/chan.go#L33)

```go
type hchan struct {
	qcount   uint           // total data in the queue
	dataqsiz uint           // size of the circular queue
	buf      unsafe.Pointer // points to an array of dataqsiz elements
	elemsize uint16
	closed   uint32
	elemtype *_type // element type
	sendx    uint   // send index
	recvx    uint   // receive index
	recvq    waitq  // list of recv waiters
	sendq    waitq  // list of send waiters

	// lock protects all fields in hchan, as well as several
	// fields in sudogs blocked on this channel.
	//
	// Do not change another G's status while holding this lock
	// (in particular, do not ready a G), as this can deadlock
	// with stack shrinking.
	lock mutex
}
```

一张图片生动形象的介绍channel的数据结构：![9lOZyp](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/9lOZyp.jpg)

<!-- more -->

各个字段含义如下：
1. qcount：表示当前channel当前实际元素的个数，代表 chan 中已经接收但还没被取走的元素的个数。内建函数 len 可以返回这个字段的值。
2. dataqsiz：队列的大小，也就是我们缓冲区的大小。chan 使用一个循环队列来存放元素，循环队列很适合这种生产者 - 消费者的场景（我很好奇为什么这个字段省略 size 中的 e）。
3. buf：存放元素的**循环队列或环形数组**的 buffer。
4. elemtype 和 elemsize：chan 中元素的类型和 size。因为 chan 一旦声明，它的元素 类型是固定的，即普通类型或者指针类型，所以元素大小也是固定的。
5. sendx：表示发送方向channel发送数据的时候，应该往哪个位置发送。一旦接收了新的数据，指针就会加上 elemsize，移向下一个位置。buf 的总大小是 elemsize 的整数倍，而且 buf 是一个循 环列表。
6. recvx：表示接收方从channel接收数据的时候，应该从哪个位置获取我们的数据。处理接收请求时的指针在 buf 中的位置。一旦取出数据，此指针会移动到下一 个位置。
7. recvq：消费者队列，chan 是多生产者多消费者的模式，如果消费者因为没有数据可读而被阻塞了， 就会被加入到 recvq 队列中。
8. sendq：发送者队列，如果生产者因为 buf 满了而阻塞，会被加入到 sendq 队列中。
9. lock：是保护channel所有字段的一个大锁，channel中保证并发安全也是要靠锁来保证的。

### 发送和接收
send过程的源码流程图：![nl5e4h](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/nl5e4h.png)

注意：
1. 当channel已经满了，如果发送者还要发送数据，发现无法发送，此时就会将goroutine的运行情况与现场保存起来，将其和当前的channel进行一个绑定来生成sudog，然后挂到sendq这个发送者等待队列。![psEPMX](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/psEPMX.png)
2. 当channel已经满了，并且sendq中有等待的生产者，此时如果我们有一个消费者来消费，首先将会将sendx指向的生产者的数据交给消费者，然后放入我们等待队列中的第一个生产者的数据
3. 每次向我们hchan结构体发送数据的时候会加锁，并且会涉及到数据的拷贝

**为什么会说整个流程是并发安全的呢？**
> 从下图中可以看到因为chansend，chanrecv，以及close内部都是加锁的，
![ZlkAZY](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/ZlkAZY.png)

### gopark与goready
> 前面我们讲到两个比较关键的函数：![8ylQpO](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/8ylQpO.png)

1. gopark与goready是一对的，也就是说只要有休眠的一方就一定有唤醒的一方，所谓的挂起就是将我们的goroutine打包成sudog挂载到sendq的过程，反之亦然
2. gopark与goready位置是一一对应的：![VtVJf1](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/VtVJf1.png)
3. goready其实也是一样的：![DurnlH](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/DurnlH.png)


## 第三部分：Timer
> 我们用的是Go 1.14，在Golang早期的版本中，timer实现比较简单

> 我们平常写的代码中，`time.sleep`以及`time.after`本质上都是创建一个timer结构体，timer会加入到runtime维护的四叉堆，四叉堆很好了解，但是以什么为依据建立这个四叉堆呢，主要是触发时间为准，是一个**小顶四叉堆，离当前时间最近的那个时间一定是在堆顶**，如果一个新的时间是在堆顶时间之后就会往下走。在timer最老的实现里面，只有一个全局的四叉堆，会专门针对这个四叉堆启动一个goroutine叫做timerproc，goroutine的逻辑也很简单就是运行一个for循环，for循环不断检查我们堆顶的元素是否到期，如果到期就会触发，触发的时候会不断调整我们的堆，直到所有触发timer都触发完毕为止，然后继续休眠。

四叉堆的结构如下图所示：![dvIUEX](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/dvIUEX.png)

{% folding 这种单一的四叉堆有什么问题呢？ %}
就是我所有goroutine执行timer相关操作的时候都要去抢占操作这个堆的全局锁，这个锁是写锁，会对性能伤害比较大。
{% endfolding %}


{% folding timer改进历史 %}
- timer大致经历的阶段如下：全局只有一个四叉堆 -> 通过一个长度为64的timers数组，数组中的每一个元素都是一个对应的timer四叉堆 ![a9T9iX](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/a9T9iX.png) -> 现在是给我们的每一个p绑定一个对应的四叉堆
- 改进：之前我们都是单个全局的四叉堆，并且是一个全局锁，Go官方在后期的改进中通过一个长度为64的timers数组，最多只能还有64个四叉堆，数组中的每一个元素都对应于一个四叉堆。通过改进之后，我们有了多个四叉堆，而不是之前的一个四叉堆，也就是降低锁的粒度，其实是分片锁，从单个四叉堆变成多个四叉堆，我们知道gomaxprocs=8说明我们有8个p，并且每一个M都会有一个对应的p，每一个M都会在某一时刻都会执行一个Goroutine，此时如果goroutine中有`time.sleep`或者`time.after`的时候，就会将我们此时的timer插入到四叉堆里面，此时和以前的逻辑就不一样了，我们用goroutine找到对应的M，然后找到对应的P，假设此时P的编号为2，那么去timers数组里面找到索引为2的timer元素，该元素是一个四叉堆，所以也就是说每一个p对应的执行线程都会找到自己对应的四叉堆。此时我们就会发现这个锁从原来的全局锁变成了每一个p自己的锁。
{% endfolding %}

{% folding 使用timers数组之后遇到的问题 %}
- **之后又遇到了一些问题**：社区中有人提出，CPU密集型任务会导致timer唤醒延迟。
- **改进**：现在1.14中，timers数组直接干掉，也就是直接将四叉堆与p进行绑定，在p里面新建一个timers字段，**那么此时检查四叉堆堆顶的时间交给了schedule。** 
- ![kElznB](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/kElznB.png)
{% endfolding %}

{% folding timer所做的改进(Go1.14中) %}
目的：所做的这些变化都是为了解决之前timer不能被及时执行的问题
- ![M7lLRR](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/M7lLRR.png)
- ![7ZPFSK](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/7ZPFSK.png)
- ![5LdwwG](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/5LdwwG.png)
{% endfolding %}

## 10分钟的问答
中间还有10分钟的问答，这里自己没有详细看，后面可以去看一下

28:37->44:20

## 第四部分：map
> 大家可能初学go有一个疑问，为什么map获取值的时候可以有一个返回值也可以有两个返回值，这个其实是语法糖，也就是底层会根据返回值个数的不同去调用不同的函数来获取结果，图示如下，![8aiZYj](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/8aiZYj.png)

### map创建
使用make创建map的时候，![FubDbe](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/FubDbe.png)
1. 如果我们第2个参数指定的长度小于等于8将会调用`makemap_small`函数，
2. 如果指定的map长度大于8，我们将会调用`makemap`函数。

曹大刚才说的，比如这里我们将专门把map创建的代码放到main之外，此时就会调用runtime.makemap函数。

map函数会有很多看起来类似的实现，主要是因为Go中没有泛型。
map函数一览：![oQ7OZO](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/oQ7OZO.png)，很多access逻辑都类似，都可以使用泛型来完善

上面这些函数都是对应于编译器我们可以看到调用函数的代码，

mapaccess是获取map值的过程，如果只是返回1个值将会调用返回mapaccess1这个函数，如果返回值以及值是否存在将会调用mapaccess2这个函数

当使用make将map分配到堆上的时候，如果hint大于8将会调用makemap，如果hint<=8将会调用makemap_small 

### map内置结构
> map结构图如下：![elUT2w](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/elUT2w.png)
对上图的说明：每一个map都对应底层的一个runtime.hmap这个结构，位于runtime下面的map.go文件

[点击查看map结构源码](https://github.com/golang/go/blob/aeea5bacbf79fb945edbeac6cd7630dd70c4d9ce/src/runtime/map.go#L116)

map对应的结构体如下：
```Go
// A header for a Go map.
type hmap struct {
	// Note: the format of the hmap is also encoded in cmd/compile/internal/reflectdata/reflect.go.
	// Make sure this stays in sync with the compiler's definition.
	count     int // # live cells == size of map.  Must be first (used by len() builtin)
	flags     uint8
	B         uint8  // log_2 of # of buckets (can hold up to loadFactor * 2^B items)
	noverflow uint16 // approximate number of overflow buckets; see incrnoverflow for details
	hash0     uint32 // hash seed

	buckets    unsafe.Pointer // array of 2^B Buckets. may be nil if count==0.
	oldbuckets unsafe.Pointer // previous bucket array of half the size, non-nil only when growing
	nevacuate  uintptr        // progress counter for evacuation (buckets less than this have been evacuated)

	extra *mapextra // optional fields
}
```

- count：表示map中元素个数。而不是bucket个数
- B：bucket个数对2的对数，假设B为4，那么就会有2^4个bucket，B>=4之后会额外多分配几个bucket作为预留的overflow的 bucket，比如0号bucket满了，但是如果发生hash冲突，此时将会链在0号bucket后面的bucket
- noverflow：记录的是溢出桶总共的个数
- hash0：避免hash碰撞攻击特意设置的一个值，map初始化的一个特殊值
- buckets：指向我们正在使用的一个Bucket数组
- oldBuckets：如果我们的map发生了扩容，那么此时就会有两个bucket，一个是新的bucket，放在buckets里面，另外一个是old buckets，也就是扩容前的bucket数组
- extra：记录和overflow相关的情况

### map查询以及赋值
> 如果B=4，那么我们可以用到的Bucket个数有16个，但是分配的时候有一个特殊的逻辑，会有一个向上的roundup的操作，所以2^4=16个bucket之后又多留了两个预留的bucket

![TcK9md](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/TcK9md.png)

1. 查询与赋值的过程：首先对key进行一个hash函数的计算，然后计算出一个64位的二进制hash，分成三部分：开头8位是top hash，最后的B(bucket个数)位是我们的low bits，将low bits与我们的bucket mask进行&运算得到的便是我们桶的序号，再找到tophash相同的那个位置对应的数字，注意：如果tophash找到了并不代表一定存在，实际还需要做一个key的简单对比，如果tophash可以找到并且key也相等说明就是存在的，查找就是这样一个流程，如果是赋值的话，如果找到就修改，找不到的话就找到一个空然后填进去。如果tophash值相同，但是key不同，我们需要将这一组数据放到后面的一个空上，如果当前的bucket放满了，那我就会把新的bucket链到老的bucket后面(通过老的bucket的overflow指针)，
2. 注意：赋值的过程中，如果tophash相同，但是key不同，那么我们需要向后找到一个空位置放入对应的值，如果key相同，那么直接用新值进行覆盖即可。
3. map访问，删除是不会触发扩容的，赋值的时候可能会触发扩容，如果赋值的是之前不存在的值，那么增长的同时会导致我原来很多的bucket是不够用的，另外一方面此时的overflow bucket过多也就意味着同一个bucket后面会链接很长的链表，如果找一个元素就会遍历链表并且非常慢，Go语言中是通过对map扩容来解决这个问题

### map扩容
Go语言中Map的扩容：![7b4q1H](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/7b4q1H.png) ![7uyLPI](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/7uyLPI.png)

map扩容操作主要是由元素赋值操作引发的，赋值的时候发现load factor过大，
1. 触发行为：通过mapassign进行map的扩容
2. 触发时机：load factor过大 或 overflow bucket过多造成扩容
3. 注意：搬运过程是渐进式的，而不是一次性就搬迁完成的

曹大这里有给到一个渐进式扩容的动画

{% folding 扩容的两种情况 %}
1. bucket不增加：原来有8个bucket，现在依然有8个bucket，只不过有一些Bucket有overflow链表，此时需要将overflow出来的元素整理，都可以紧密放到非overflow的bucket中 ![YP0JSG](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/YP0JSG.png) -> ![zdx7nv](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zdx7nv.png) 可以看到重新紧密排列之后元素更加紧密了，
2. bucket增加：比如现在我们要做增大扩容，比如现在有8个bucket，我们扩容之后是16个bucket，然后老的8个bucket中的所有元素全部重新放置到新扩容之后的16个Bucket ![YP0JSG](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/YP0JSG.png) -> ![6NjxIU](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/6NjxIU.png) -> ![fn1SA9](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/fn1SA9.png) 
{% endfolding %}

具体的扩容过程：
1. ![7JTEHC](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/7JTEHC.png)


### 遍历
{% folding map的遍历 %}
1. 遍历是随机的，整个遍历起始位置的随机化都是通过如下过程来完成的：![zD8J1u](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/zD8J1u.png)
2. 选取了一个随机的桶和桶内的一个随机的位置之后就开始顺序遍历，遍历完选择的桶之后再按序遍历其他的桶。注意：如果遍历的桶有overflow，遍历完对应桶之后遍历后面挂的overflow的bucket的时候，我们会从我们上面已经明确的那个随机位置开始遍历，比如上面那个随机位置是3，那么这次遍历overflow bucket时候也是从3位置开始 ![cs0GBT](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/cs0GBT.png)
3. 如果是在迁移过程中遍历的则稍微麻烦些，需要做一些恶心的判断，比如我们遍历到了第5个bucket，且正在扩容。扩容可能意味着我有一些老的bucket还没有搬迁到新的bucket里面，如果是等大扩容直接就遍历原来的bucket就可以了，如果是非等大扩容，需要做一些计算 ![jHP8Lq](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/jHP8Lq.png)
{% endfolding %}

### 缺陷
{% folding 目前map存在的缺陷 %}
1. delete的时候没办法缩容 ![GBF6oO](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/GBF6oO.png)
2. 并发不安全：![c3tvYk](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/c3tvYk.png) 比如使用defer去进行解锁，如果在defer后面的代码中调用了函数，函数里面进行了加锁，那么就有可能死锁
3. map结构中有一些场景要做分配和释放，我们希望对频繁分配和释放的数据结构进行重用，![Ux8WuK](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/Ux8WuK.png)
{% endfolding %}


map的讲解中我们省略了同时涉及到扩容和overflow的情况，讲起来特别复杂，直接看代码就好了

## 第五部分 Context
Go 1.6 之后增加的Context：![DEgKNO](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/DEgKNO.png)

![JRXWq0](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/JRXWq0.png)

![9plNBj](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/9plNBj.png)
我们前面说到context更像一棵树：
![cPuOpv](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/cPuOpv.png)

![0BJDHV](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/0BJDHV.png)


![QdKsjD](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/QdKsjD.png)
我们执行goroutine的时候需要通过select的ctx.Done这个case进行配合，如果不这样的话我们就是完全不配合外部的取消操作，也就是不监听外部的取消通知，此时依然配合不了

## 参考
1. [Context](https://github.com/cch123/golang-notes/blob/master/context.md)
2. [⽼版本的 timer 实现](https://github.com/cch123/golang-notes/blob/master/timer.md)
3. [1.14 timer 性能提升分析](http://xiaorui.cc/archives/6483)
4. [这位⼩姐姐的 PPT 还是做的不错的，有⼀些本节课未覆盖到的细节](https://speakerdeck.com/kavya719/understanding-channels)
5. 工程里面时间轮的实现：
   1. [DPVS时间轮](https://www.jianshu.com/p/f38cd8c99f70)
   2. [kafka时间轮](https://www.infoq.cn/article/erdajpj5epir65iczxzi)
6. [深入理解Golang之channel](https://juejin.cn/post/6844904016254599176)
7. [深度解密Go语言之channel](https://mp.weixin.qq.com/s/90Evbi5F5sA1IM5Ya5Tp8w)
8.  鸟窝大佬极客时间<<并发编程实战课>>第13讲


1:21:59->1:32:40都是石墨文档答疑
本次课没有涉及到的实现：slice/interface/string，会当做源码分析比赛的内容


作业：
![00uDao](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/00uDao.png)，如果是学基础的同学将必做做了就可以了

曹大的建议：
1. 源码分析的时候建议尽量多琢磨琢磨阅读源码的过程，尽量少去看别人的源码分析，也就是锻炼自己的源码分析能力
2. 

------


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
