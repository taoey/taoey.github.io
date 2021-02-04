---
layout: post
title: golang-channel使用及底层原理
categories: [golang]
description: golang-channel
keywords: golang,并发
---

golang  channel 的常见使用方式及底层原理

## 相关特性

- channel关闭后，channel中的数据仍然可读取，但是不能写入，否则会引发panic错误：send on closed channel
- 数据发送不完，不应该关闭channel
- 已经关闭的channel，可以从中读到数据0。读到0就说明：写端已经关闭了
- channel读取不到内容将会阻塞协程，因此channel可配合select使用
- channel是通过注册相关goroutine id实现消息通知的



## channel的整体结构图

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan.png)

简单说明：

- `buf`是有缓冲的channel所特有的结构，用来存储缓存数据。是个循环链表
- `sendx`和`recvx`用于记录`buf`这个循环链表中的发送或者接收的index
- `lock`是个互斥锁。
- `recvq`和`sendq`分别是接收(<-channel)或者发送(channel <- xxx)的goroutine抽象出来的结构体(sudog)的队列。是个双向链表

源码位于`/runtime/chan.go`中(版本：1.14)。结构体为`hchan`。



```
type hchan struct {
    qcount   uint // 当前缓存数据的总量  
    dataqsiz uint // 缓存数据的容量      
    buf      unsafe.Pointer // 缓存数据，为一个循环数组，容量大小为 dataqsiz，当前大小为 qcount
    elemsize uint16 // 数据类型的大小，比如 int 为 4
    closed   uint32 // 标记是否关闭
    elemtype *_type // 数据的类型
    sendx    uint  // 发送队列 sendq 的长度
    recvx    uint  // 接收队列 recvq 的长度
    recvq    waitq // 阻塞的接收 goroutine 的队列
    sendq    waitq // 阻塞的发送 goroutine 的队列
    lock mutex     // 锁，用于并发控制队列操作
}
```



下面我们来详细介绍`hchan`中各部分是如何使用的。

## 先从创建开始

我们首先创建一个channel。

```
ch := make(chan int, 3)
```

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan1.png)

创建channel实际上就是在内存中实例化了一个`hchan`的结构体，并返回一个ch指针，我们使用过程中channel在函数之间的传递都是用的这个指针，这就是为什么函数传递中无需使用channel的指针，而直接用channel就行了，因为channel本身就是一个指针。

## channel中发送send(ch <- xxx)和recv(<- ch)接收

先考虑一个问题，如果你想让goroutine以先进先出(FIFO)的方式进入一个结构体中，你会怎么操作？

加锁！对的！channel就是用了一个锁。hchan本身包含一个互斥锁`mutex`

### channel中队列是如何实现的

channel中有个缓存buf，是用来缓存数据的(假如实例化了带缓存的channel的话)队列。我们先来看看是如何实现“队列”的。

还是刚才创建的那个channel

```
ch := make(chan int, 3)
```



### send/recv的细化操作

注意：缓存链表中以上每一步的操作，都是需要加锁操作的！

每一步的操作的细节可以细化为：

- 第一，加锁
- 第二，把数据从goroutine中copy到“队列”中(或者从队列中copy到goroutine中）。
- 第三，释放锁

每一步的操作总结为动态图为：(发送过程)

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/send_single.gif)

所以不难看出，Go中那句经典的话：`Do not communicate by sharing memory; instead, share memory by communicating.`的具体实现就是利用channel把数据从一端copy到了另一端！



### 当channel缓存满了之后会发生什么？这其中的原理是怎样的？

使用的时候，我们都知道，当channel缓存满了，或者没有缓存的时候，我们继续send(ch <- xxx)或者recv(<- ch)会阻塞当前goroutine，但是，是如何实现的呢？

我们知道，Go的goroutine是用户态的线程(`user-space threads`)，用户态的线程是需要自己去调度的，Go的调度器会帮我们完成这件事情。



goroutine的阻塞操作，实际上是调用`send (ch <- xx)`或者`recv ( <-ch)`的时候主动触发的，具体请看以下内容：

```
//goroutine1 中，记做G1
ch := make(chan int, 3)
ch <- 1
ch <- 1
ch <- 1
```

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block.png)

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block1.png)

此时channel缓冲区已经满了，这个时候G1正在正常运行,当再次进行send操作(ch<-1)的时候，会主动调用Go的调度器,让G1等待，并从让出M，让其他G去使用

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block2.png)

同时G1也会被抽象成含有G1指针和send元素的`sudog`结构体保存到hchan的`sendq`中等待被唤醒。

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_blok3.gif)

那么，G1什么时候被唤醒呢？这个时候G2隆重登场。

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block4.png)

G2执行了recv操作`p := <-ch`，于是会发生以下的操作：

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block5.gif)

G2从缓存队列中取出数据，channel会将等待队列中的G1推出，将G1当时send的数据推到缓存中，然后调用Go的scheduler，唤醒G1，并把G1放到可运行的Goroutine队列中。

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block6.gif)

### 假如channel为空时，先进行执行recv操作的G2会怎么样？

你可能会顺着以上的思路反推。首先：

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block7_1.png)

这个时候G2会主动调用Go的调度器,让G2等待，并从让出M，让其他G去使用。

G2还会被抽象成含有G2指针和recv空元素的`sudog`结构体保存到hchan的`recvq`中等待被唤醒

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block7.gif)

此时恰好有个goroutine G1开始向channel中推送数据 `ch <- 1`。

此时，非常有意思的事情发生了：



G1并没有锁住channel，然后没有将数据放到缓存中，而是直接把数据从**G1直接copy到了G2的栈**中。

**这种方式非常的赞！在唤醒过程中，G2无需再获得channel的锁，然后从缓存中取数据。减少了内存的copy，提高了效率**。

之后的事情显而易见：

![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block8.gif)

![image.png](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/image.png)



![image](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-2-4-golang_channel.assets/hchan_block9.gif)





参考资料：

- [图解Golang的channel底层原理](https://studygolang.com/articles/20714)