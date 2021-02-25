---
layout: post
title: 练习题-大数组并发查找问题
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

```go
package main

import (
	"context"
	"fmt"
	"runtime"
	"time"
)

const(
	TIME_OUT_SECOND = 5
)


func FindNum(arr []int,target int)  {
	ctx, cancelFunc := context.WithTimeout(context.Background(), time.Second * TIME_OUT_SECOND)
	defer cancelFunc()

	// 确定goroution个数
	goroutineNum := runtime.NumCPU()
	exitChan := make(chan int)
	if len(arr) < goroutineNum{
		go subFindNum(ctx,arr,target,exitChan)
	}else{
		// 子切片划分
		subLength := len(arr) / goroutineNum
		for i := 0; i <goroutineNum; i++ {
			index := i
			var subArr []int
			if index == goroutineNum - 1{ //剩余元素都归到最后一个切片中
				subArr = arr[index*subLength:]
			}else{
				subArr = arr[index*subLength:(index+1)*subLength]
			}
			go subFindNum(ctx,subArr,target,exitChan)
		}
	}
	select {
	case <-ctx.Done():
		fmt.Println("timeout")
		return
	case <-exitChan:
		fmt.Println("find it")
		return
	}
	return
}

// 子切片查询，选用了最简单的遍历排序，可以使用排序和二分查找优化
func subFindNum(ctx context.Context ,subArr []int,targetNum int, exitChan chan int) {
	for _, val := range subArr{
		select {
		case <-ctx.Done():
			return
		default:
		}
		if val == targetNum{
			exitChan <- 1
			return
		}
	}
}

func main() {
	maxNum := 100000
	arr := make([]int,maxNum)
	for i:=0;i<maxNum;i++{
		arr[i] = i
	}
	targetNum := 1000
	FindNum(arr,targetNum)
}

```



我们添加一些调试代码，看一下goroutine是否进行了关闭，修改defer部分的代码，改成如下：

```go
defer func() {
    fmt.Println("cancel before",runtime.NumGoroutine())
    cancelFunc()
    time.Sleep(time.Second)
    fmt.Println("cancel after",runtime.NumGoroutine())
}()

```

再次执行之前的程序，可以看到打印的日志：

```
current cpu num: 12
current cpu num: 13
find it
cancel before 13
cancel after 1
```

可以看到能够goroutine已经被关闭掉

