---
title: Morris遍历
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
  - 算法
tags:
  - Morris遍历
  - 树
date: 2021-11-27 14:58:54
summary:
---

## Morris遍历：
优点：不同于我们之前递归遍历或者借助栈来进行树的遍历，因为Morris遍历可以在保证时间复杂度依然为O(N)的情况下可以将空间复杂度降低为O(1)

> 假设当前节点为cur,最一开始来到树根，什么时候停呢，当cur来到nil的时候就停止

1. 如果当前节点没有左子树，直接向右移动
2. 如果当前节点有左子树，找到当前节点左子树的最右节点mostRight
   1. 如果mostRight的右指针指向null，那么mostRight.Right=Cur,cur=cur.Left
   2. 如果mostRight的右指针指向cur，那么mostRight.Right=nil,cur=cur.Right

遍历之后发现一个问题：任何一个节点，只要有左孩子Morris遍历的时候会遍历两次，也就是有左树的节点，左树不为空，首先遍历当前节点，然后遍历左树，遍历之后再回到当前节点，所以当前节点会遍历两次。因为用这个就可以知道是第一次来到自己还是第二次来到自己。

### Morris先序遍历：
第一次遍历到该节点的时候直接打印（没有左子树的节点会遍历到一次，有左子树的节点会遍历到两次，但是我们第一次就应该打印）

{% folding blue, Morris先序遍历代码 %}
```go
func MorrisPreOrderTraverse(root *TreeNode) []int {
	if root == nil {
		return nil
	}

	var mostRight *TreeNode
	cur := root
	var ret []int
	for cur != nil {
		//如果当前节点没有左子树
		if cur.Left == nil { //当前节点向右移动  (只有没有左子树的节点会走这一步)
			ret = append(ret, cur.Val)
			cur = cur.Right
		} else { //找到当前节点左子树的最右节点
			mostRight = cur.Left

			for mostRight.Right != nil && mostRight.Right != cur {
				mostRight = mostRight.Right
			}
			//此时mostRight就是当前节点左子树的最右节点
			if mostRight.Right == nil { //说明是第一次来到
				ret = append(ret, cur.Val)
				mostRight.Right, cur = cur, cur.Left
			} else { //说明是第二次来到(只有有左子树的时候才会有第二次来到)
				mostRight.Right, cur = nil, cur.Right
			}
		}
	}

	return ret
}
```
{% endfolding %}

<!-- more -->

### Morris中序遍历：

{% folding blue, Morris中序遍历代码 %}

```go
//✅Morris中序遍历
func MorrisInOrderTraverse(root *TreeNode) []int {
	if root == nil {
		return nil
	}

	var mostRight *TreeNode
	cur := root
	var ret []int
	for cur != nil {
		//如果当前节点没有左子树
		if cur.Left == nil { //当前节点向右移动  (只有没有左子树的节点会走这一步)
			ret = append(ret, cur.Val)
			cur = cur.Right
		} else { //找到当前节点左子树的最右节点
			mostRight = cur.Left

			for mostRight.Right != nil && mostRight.Right != cur {
				mostRight = mostRight.Right
			}
			//此时mostRight就是当前节点左子树的最右节点
			if mostRight.Right == nil { //说明是第一次来到
				mostRight.Right, cur = cur, cur.Left
			} else { //说明是第二次来到(只有有左子树的时候才会有第二次来到)
				ret = append(ret, cur.Val)
				mostRight.Right, cur = nil, cur.Right
			}
		}
	}

	return ret
}
```
{% endfolding %}

<!-- more -->

### Morris后序遍历
> 这种有点类似于线索二叉树，就是利用节点的空闲指针可以串回去


思路：![Nt2Ayy](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/Nt2Ayy.png)
1. 打印时机就放到可以回到自己并且第二次回到的时候，但是不是打印自己而是打印左树的右边界，并且是逆序打印（不可以放到栈里面，通过反转链表，第二次遍历到某个节点的时候先将左子树的最右节点的右指针恢复为null，然后开始反转链表，打印之后反转回去）
2. 但是这样的方式会错过整棵树的右边界，所以最后自己单独打印一下右边界

因为一棵树是按照一条一条右边界拆分下来的：![uuNVNN](https://cdn.jsdelivr.net/gh/sivanWu0222/ImageHosting@master/uPic/uuNVNN.png)



{% folding blue, Morris后序遍历代码 %}

```go
//Morris后序遍历，自己写的参考左神
//打印时机就放到可以回到自己并且第二次回到的时候，但是不是打印自己而是打印左树的右边界，并且是逆序打印
//但是这样的方式会错过整棵树的右边界，所以最后自己单独打印一下右边界
//因为一棵树是这么拆分下来的：
func MyMorrisPostOrderTraverse(root *TreeNode) []int {
	if root == nil {
		return nil
	}

	var mostRight *TreeNode
	cur := root
	var ret []int
	for cur != nil {
		if cur.Left == nil {
			cur = cur.Right
		} else {
			mostRight = cur.Left
			for mostRight.Right != nil && mostRight.Right != cur {
				mostRight = mostRight.Right
			}
			if mostRight.Right == nil { //说明是第一次遍历你到
				mostRight.Right, cur = cur, cur.Left
			} else {
				mostRight.Right = nil
				//打印左子树的右边界
				ret = append(ret, prinSubTreeRightEdge(cur.Left)...)
				cur = cur.Right
			}
		}
	}

	//最后再打印一下整棵树的右边界即可
	ret = append(ret, prinSubTreeRightEdge(root.Right)...)
	return ret
}

func prinSubTreeRightEdge(head *TreeNode) []int {
	if head == nil {
		return nil
	}

	var ret []int

	//反转
	var prev *TreeNode
	cur := head
	for cur != nil {
		prev, cur, cur.Right = cur, cur.Right, prev
	}

	//此时prev指向反转之后的头
	//开始打印
	cur = prev
	for cur != nil {
		ret = append(ret, cur.Val)
		cur = cur.Right
	}

	//反转回去
	prev, cur = nil, prev
	for cur != nil {
		prev, cur, cur.Right = cur, cur.Right, prev
	}

	return ret
}
```


{% endfolding %}
