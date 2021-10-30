---
title: git技巧总结
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
  - git
tags:
  - git
date: 2021-09-28 19:08:42
summary:
---
{% note info, 工作中经常用到一些git命令，所以此博文方便自己复习和巩固，加快自己的提高效率 %}

## git 图解



对于git已经跟踪的文件，我们可以使用`git add -u`将这些已经被管理的文件一起提交

## git 常用技巧

{% folding green, git stash使用技巧 %}

{% note message blue, 应用场景：工作中经常遇到一种情况就是突然临时来了任务或者紧急修复一个线上bug，我们需要将我们之前的修改进行一个临时保存(并不会应用到分支的改变中)，此时我们就需要使用`git stash`命令，`git stash`命令有很多参数和子命令，需要我们熟练使用 %}

通过`git stash -h`之后我们可以看到`git stash`的子命令以及对应的参数

```shell
BooksMark on hotfix-1 [$] via 🅒 base
[I] ➜ git stash -h
usage: git stash list [<options>]
   or: git stash show [<options>] [<stash>]
   or: git stash drop [-q|--quiet] [<stash>]
   or: git stash ( pop | apply ) [--index] [-q|--quiet] [<stash>]
   or: git stash branch <branchname> [<stash>]
   or: git stash clear
   or: git stash [push [-p|--patch] [-k|--[no-]keep-index] [-q|--quiet]
          [-u|--include-untracked] [-a|--all] [-m|--message <message>]
          [--] [<pathspec>...]]
   or: git stash save [-p|--patch] [-k|--[no-]keep-index] [-q|--quiet]
          [-u|--include-untracked] [-a|--all] [<message>]
```

注意：我们`git stash`都会将所有的记录加入到我们的栈顶中

1. `git stash`：可以将我们**暂存区**中改变的内容加入到我们的堆栈区中
   1. `git stash -u`：可以将**工作区和暂存区**中改变的内容加入到我们的堆栈区中
   2. `git stash -a`：可以将**工作区和暂存区以及我们忽略的文件**中改变的内容加入到我们的堆栈区中
2. `git stash save "你的stash message"`：同`git stash`，只不过我们后面可以加上一个自定义的message(其实就是`git commit`的message)，方便我们之后恢复现场或者区分其他的改变记录 ![j0pNU5](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/j0pNU5.jpg)
   1. `git stash save -u "你的stash message"`：可以将**工作区和暂存区**中改变的内容加入到我们的堆栈区中，并且通过自定义的stash message区分我们之前的记录
   2. `git stash save -a "你的stash message"`：可以将**工作区和暂存区以及我们忽略的文件**中改变的内容加入到我们的堆栈区中，并且通过自定义的stash message区分我们之前的记录
3. `git stash list`：可以查看我们目前堆栈区中所有内容
4. `git stash pop`：弹出堆栈区栈顶改变的内容，并且应用到当前分支中
5. `git stash apply`：此时会将我们**堆栈顶部的内容**应用到当前分支中，并且不会弹出堆栈区的堆顶
   1. `git stash apply stash的id`：此时会将**堆栈中指定的stash**应用到当前分支中，并且不会弹出堆栈区的堆顶，比如`git stash apply stash@{1}`
6. `git stash clear`：会清除堆栈区中所有的记录
7. `git stash drop`：会删除堆栈区中最近的stash，
   1. `git stash drop stash的id`：删除堆栈区中指定的stash
8. `git stash show`：默认以总览的形式显示堆顶的stash做了哪些改动，如果想要我们看某一个stash做的全部改动我们可以传递参数`-p`
   1. `git stash show stash的id -p`：显示指定的stash做了哪些具体的改动
9.  `git stash branch 分支名`：会**根据最近的stash创建一个新的分支，然后删除最近的stash**
    1.  `git stash branch 分支名 stash的id`：将指定的stash运用到新创建的分支中，**分支名必须是目前不存在的分支**


参考文章
1. [☆☆☆Git stash](https://www.atlassian.com/git/tutorials/saving-changes/git-stash)
2. ☆☆☆https://github.com/rfyiamcool/share_ppt#git%E7%9A%84%E9%82%A3%E4%BA%9B%E4%BA%8B%E5%84%BF
3. https://www.jianshu.com/p/471c9537f45a
4. https://www.cnblogs.com/fxwoniu/p/13823337.html
5. https://www.cnblogs.com/zndxall/archive/2018/09/04/9586088.html

{% endfolding %}


## 参考文章




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
