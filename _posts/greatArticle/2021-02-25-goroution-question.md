---
layout: post
title: 练习题-多并发goroutine的超时与取消
categories: [golang]
description: 练习题-多并发goroutine的超时与取消
keywords: golang,goroutine,context,超时
---

前言：大数组并发查找问题

> 假设有一个超长的切片，切片的元素类型为int，切片中的元素为乱序排列。限时5秒，使用多个goroutine查找切片中是否存在给定值，在找到目标值或者超时后立刻结束所有goroutine的执行。
>
> 比如切片为：[23, 32, 78, 43, 76, 65, 345, 762, …… 915, 86]，查找的目标值为345，如果切片中存在目标值程序输出:"Found it!"并且立即取消仍在执行查找任务的goroutine。如果在超时时间未找到目标值程序输出:"Timeout! Not Found"，同时立即取消仍在执行查找任务的goroutine。



解题思路：

- 获取CPU个数，作为切片个数
- 使用context控制超时（goroutine的退出）
- 找到目标元素后，使用channel通信，执行context的cancel()函数





上代码：



