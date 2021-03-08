---
layout: post
title: golang中Context的使用场景
categories: [golang]
description:  golang中Context的使用场景
keywords: golang,context
---

前言：contex主要的用处如果用一句话来说，是在于控制goroutine的生命周期。


contex主要的用处如果用一句话来说，是在于控制goroutine的生命周期。当一个计算任务被goroutine承接了之后，由于某种原因（超时，或者强制退出）我们希望中止这个goroutine的计算任务，那么就用得到这个Context了。

本文主要来盘一盘golang中context的一些使用场景。



## 1、超时请求

一个例子：

> 假设有一个超长的切片，切片的元素类型为int，切片中的元素为乱序排列。限时5秒，使用多个goroutine查找切片中是否存在给定值，在找到目标值或者超时后立刻结束所有goroutine的执行。
>
> 比如切片为：[23, 32, 78, 43, 76, 65, 345, 762, …… 915, 86]，查找的目标值为345，如果切片中存在目标值程序输出:”Found it!”并且立即取消仍在执行查找任务的goroutine。如果在超时时间未找到目标值程序输出:”Timeout! Not Found”，同时立即取消仍在执行查找任务的goroutine。



```go
package main

import (
	"context"
	"fmt"
	"runtime"
	"time"
)

const (
	TIME_OUT_SECOND = 5
)

func FindNum(arr []int, target int) {
	ctx, cancelFunc := context.WithTimeout(context.Background(), time.Second*TIME_OUT_SECOND)
	defer func() {
		fmt.Println("cancel before", runtime.NumGoroutine())
		cancelFunc()
		time.Sleep(time.Second)
		fmt.Println("cancel after", runtime.NumGoroutine())
	}()

	// 确定goroution个数
	goroutineNum := runtime.NumCPU()
	exitChan := make(chan int)
	if len(arr) < goroutineNum {
		go subFindNum(ctx, arr, target, exitChan)
	} else {
		// 子切片划分
		subLength := len(arr) / goroutineNum
		for i := 0; i < goroutineNum; i++ {
			index := i
			var subArr []int
			if index == goroutineNum-1 { //剩余元素都归到最后一个切片中
				subArr = arr[index*subLength:]
			} else {
				subArr = arr[index*subLength : (index+1)*subLength]
			}
			go subFindNum(ctx, subArr, target, exitChan)
		}
	}
	fmt.Println("current cpu num:", runtime.NumCPU())
	fmt.Println("current cpu num:", runtime.NumGoroutine())
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

// 子切片查询
func subFindNum(ctx context.Context, subArr []int, targetNum int, exitChan chan int) {
	for _, val := range subArr {
		select {
		case <-ctx.Done():
			return
		default:
		}
		if val == targetNum {
			exitChan <- 1
			return
		}
	}
}

func main() {
	maxNum := 100000
	arr := make([]int, maxNum)
	for i := 0; i < maxNum; i++ {
		arr[i] = i
	}
	targetNum := 1000
	FindNum(arr, targetNum)
}

```



## 2、HTTP服务器的request互相传递数据

context还提供了valueCtx的数据结构。

这个valueCtx最经常使用的场景就是在一个http服务器中，在request中传递一个特定值，比如有一个中间件，做cookie验证，然后把验证后的用户名存放在request中。

我们可以看到，官方的request里面是包含了Context的，并且提供了WithContext的方法进行context的替换。



```go
package main

import (
	"net/http"
	"context"
)

type FooKey string

var UserName = FooKey("user-name")
var UserId = FooKey("user-id")

func foo(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ctx := context.WithValue(r.Context(), UserId, "1")
		ctx2 := context.WithValue(ctx, UserName, "yejianfeng")
		next(w, r.WithContext(ctx2))
	}
}

func GetUserName(context context.Context) string {
	if ret, ok := context.Value(UserName).(string); ok {
		return ret
	}
	return ""
}

func GetUserId(context context.Context) string {
	if ret, ok := context.Value(UserId).(string); ok {
		return ret
	}
	return ""
}

func test(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("welcome: "))
	w.Write([]byte(GetUserId(r.Context())))
	w.Write([]byte(" "))
	w.Write([]byte(GetUserName(r.Context())))
}

func main() {
	http.Handle("/", foo(test))
	http.ListenAndServe(":8080", nil)
}
```

在使用ValueCtx的时候需要注意一点，这里的key不应该设置成为普通的String或者Int类型，为了防止不同的中间件对这个key的覆盖。

最好的情况是每个中间件使用一个自定义的key类型，比如这里的FooKey，而且获取Value的逻辑尽量也抽取出来作为一个函数，放在这个middleware的同包中。这样，就会有效避免不同包设置相同的key的冲突问题了。







