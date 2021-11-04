---
title: Go语言中的执行顺序
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
  - Golang
tags:
  - go
date: 2021-11-04 08:51:13
summary:
---

> 最近梳理项目结构的时候，对于Go中项目执行流程有点模糊，因此有了本文的诞生方便巩固复习

{% note info, 我们知道整个Go项目只能有一个全局的main()函数，但是Go项目可以有多个不同的package，每一个package下都可以有很多go文件，每一个go文件可以导入其他package，并且每一个go文件可以包含自己的常量定义，全局变量，init()以及其他函数。总结下来，一个Go程序中通常由导入的包，常量，变量，init()，其他函数，main()构成，那么具体的执行流程是怎样的呢？%}

{% note danger, 注意不可以因为导入包造成循环依赖 %}

正常的执行流程：
1. 首先进入main函数所在的go文件，假设为`main.go`
   1. 执行 `main.go` 中的 `import` 语句，然后进入到其他的pkg中，
      1. 重复我们进入`main.go`中的类似流程：首先执行import导包，然后定义常量和全局变量并执行init
   2. 执行`const`定义的常量
   3. 执行`var`定义的变量
   4. 执行`init()`对应的初始化函数
   5. 执行`main()`启动程序


注意点：
1. 同一个包下面的多个go文件，如果每一个go文件中都有一个init函数，那么执行顺序就是go文件的导入顺序，并且同包下的不同 go 文件，按照文件名“从小到大”排序顺序执行
2. 其他的包只有被 main 包 import 才会执行，按照 import 的先后顺序执行，也就是按照 main 包中 import 的顺序调用其包中的 init() 函数
3. 一个包被其它多个包 import，但只能被初始化一次
4. 对同一个 go 文件的 init( ) 调用顺序是从上到下的
5. 在同一个 package 中，可以多个文件中定义 init 方法
6. 在同一个 go 文件中，可以重复定义 init 方法
7. 在同一个 package 中，不同文件中的 init 方法的执行按照文件名先后执行各个文件中的 init 方法
8. 所有 init 函数都在同⼀个 goroutine 内执⾏。 所有 init 函数结束后才会执⾏ main.main 函数。




## 参考文章
1. [Go语言的执行顺序（转）](https://www.cnblogs.com/lxx-coder/p/13081517.html)
<!-- more -->