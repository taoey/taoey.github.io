---
layout: post
title: golang-heap使用(leetcode-滑动窗口的最大值)
categories: [golang,leetcode]
description: 
keywords: golang,heap,leetcode
---

> 转载于：http://cngolib.com/container-heap.html
本文是 Go 标准库中 container/heap 包文档的翻译， 原文地址为： https://golang.org/pkg/container/heap/

## heap的使用方法

包 heap 为所有实现了 heap.Interface 的类型提供堆操作。 一个堆即是一棵树， 这棵树的每个节点的值都比它的子节点的值要小， 而整棵树最小的值位于树根（root）， 也即是索引 0 的位置上。

堆是实现优先队列的一种常见方法。 为了构建优先队列， 用户在实现堆接口时， 需要让 Less() 方法返回逆序的结果， 这样就可以在使用 Push 添加元素的同时， 通过 Pop 移除队列中优先级最高的元素了。 具体的实现请看接下来展示的优先队列例子。

### 示例：整数堆

```go
// 这段代码演示了如何使用堆接口构建一个整数堆。
package main

import (
	"container/heap"
	"fmt"
)

// IntHeap 是一个由整数组成的最小堆。
type IntHeap []int

func (h IntHeap) Len() int           { return len(h) }
func (h IntHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h IntHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }

func (h *IntHeap) Push(x interface{}) {
	// Push 和 Pop 使用 pointer receiver 作为参数，
	// 因为它们不仅会对切片的内容进行调整，还会修改切片的长度。
	*h = append(*h, x.(int))
}

func (h *IntHeap) Pop() interface{} {
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[0 : n-1]
	return x
}

// 这个示例会将一些整数插入到堆里面， 接着检查堆中的最小值，
// 之后按顺序从堆里面移除各个整数。
func main() {
	h := &IntHeap{2, 1, 5}
	heap.Init(h)
	heap.Push(h, 3)
	fmt.Printf("minimum: %d\n", (*h)[0])
	for h.Len() > 0 {
		fmt.Printf("%d ", heap.Pop(h))
	}
}
```

执行结果：

```
minimum: 1
1 2 3 5 
```

### 示例：优先队列

```go
// 这段代码演示了如何使用堆接口构建一个优先队列。
package main

import (
	"container/heap"
	"fmt"
)

// Item 是优先队列中包含的元素。
type Item struct {
	value    string // 元素的值，可以是任意字符串。
	priority int    // 元素在队列中的优先级。
	// 元素的索引可以用于更新操作，它由 heap.Interface 定义的方法维护。
	index int // 元素在堆中的索引。
}

// 一个实现了 heap.Interface 接口的优先队列，队列中包含任意多个 Item 结构。
type PriorityQueue []*Item

func (pq PriorityQueue) Len() int { return len(pq) }

func (pq PriorityQueue) Less(i, j int) bool {
	// 我们希望 Pop 返回的是最大值而不是最小值，
	// 因此这里使用大于号进行对比。
	return pq[i].priority > pq[j].priority
}

func (pq PriorityQueue) Swap(i, j int) {
	pq[i], pq[j] = pq[j], pq[i]
	pq[i].index = i
	pq[j].index = j
}

func (pq *PriorityQueue) Push(x interface{}) {
	n := len(*pq)
	item := x.(*Item)
	item.index = n
	*pq = append(*pq, item)
}

func (pq *PriorityQueue) Pop() interface{} {
	old := *pq
	n := len(old)
	item := old[n-1]
	item.index = -1 // 为了安全性考虑而做的设置
	*pq = old[0 : n-1]
	return item
}

// 更新函数会修改队列中指定元素的优先级以及值。
func (pq *PriorityQueue) update(item *Item, value string, priority int) {
	item.value = value
	item.priority = priority
	heap.Fix(pq, item.index)
}

// 这个示例首先会创建一个优先队列，并在队列中包含一些元素
// 接着将一个新元素添加到队列里面，并对其进行操作
// 最后按优先级有序地移除队列中的各个元素。
func main() {
	// 一些元素以及它们的优先级。
	items := map[string]int{
		"banana": 3, "apple": 2, "pear": 4,
	}

	// 创建一个优先队列，并将上述元素放入到队列里面，
	// 然后对队列进行初始化以满足优先队列（堆）的不变性。
	pq := make(PriorityQueue, len(items))
	i := 0
	for value, priority := range items {
		pq[i] = &Item{
			value:    value,
			priority: priority,
			index:    i,
		}
		i++
	}
	heap.Init(&pq)

	// 插入一个新元素，然后修改它的优先级。
	item := &Item{
		value:    "orange",
		priority: 1,
	}
	heap.Push(&pq, item)
	pq.update(item, item.value, 5)

    // 以降序形式取出并打印队列中的所有元素。
	for pq.Len() > 0 {
		item := heap.Pop(&pq).(*Item)
		fmt.Printf("%.2d:%s ", item.priority, item.value)
	}
}
```

执行结果：

```
05:orange 04:pear 03:banana 02:apple 
```



## 相关函数汇总

### Fix 函数

```
func Fix(h Interface, i int)
```

在索引 i 上的元素的值发生变化之后， 重新修复堆的有序性。 先修改索引 i 上的元素的值然后再执行 Fix ， 跟先调用 Remove(h, i) 然后再使用 Push 操作将新值重新添加到堆里面的做法具有同等的效果， 但前者所需的计算量稍微要少一些。

Fix 函数的复杂度为 O(log(n)) ， 其中 n 等于 h.Len() 。

### Init 函数

```
func Init(h Interface)
```

在执行任何堆操作之前， 必须对堆进行初始化。 Init 操作对于堆不变性（invariants）具有幂等性， 无论堆不变性是否有效， 它都可以被调用。

Init 函数的复杂度为 O(n) ， 其中 n 等于 h.Len() 。

### Pop 函数

```go
func Pop(h Interface) interface{}
```

Pop 函数根据 Less 的结果， 从堆中移除并返回具有最小值的元素， 等同于执行 Remove(h, 0) 。

Pop 函数的复杂度为 O(log(n)) ， 其中 n 等于 h.Len() 。

### Push 函数

```go
func Push(h Interface, x interface{})
```

Push 函数将值为 x 的元素推入到堆里面， 该函数的复杂度为 O(log(n)) ， 其中 n 等于 h.Len() 。

### Remove 函数

```go
func Remove(h Interface, i int) interface{}
```

Remove 函数将移除堆中索引为 i 的元素， 该函数的复杂度为 O(log(n)) ， 其中 n 等于 h.Len() 。

### Interface 类型

任何实现了 heap.Interface 接口的类型， 都可以用作带有以下不变性的最小堆， （换句话说， 这个堆在为空、已排序或者调用 Init 之后， 应该具有以下性质）：

```go
!h.Less(j, i) for 0 <= i < h.Len() and 2*i+1 <= j <= 2*i+2 and j < h.Len()
```

注意， 这个接口中的 Push 和 Pop 都是由 heap 包的实现负责调用的。 因此用户在向堆添加元素又或者从堆中移除元素时， 需要使用 heap.Push 以及 heap.Pop ：

```go
type Interface interface {
    sort.Interface
    Push(x interface{}) // 将 x 添加为元素 Len()
    Pop() interface{}   // 移除并返回元素 Len() - 1
}
```



## 来个实战

题目：[剑指 Offer 59 - I. 滑动窗口的最大值](https://leetcode-cn.com/problems/hua-dong-chuang-kou-de-zui-da-zhi-lcof/)

解题思路：使用大根堆方式维护滑动窗口的最大值，如果大根堆弹出的值的index不再窗口中需要进行抛弃操作，否则需要重新把该值塞回heap中。该方案并不是此题最优解，只是为了运用golang-heap练习。

实际代码：

```golang
import (
	"container/heap"
	"fmt"
)

type HeapItem struct {
	value int
	index int
}

// 大根堆
type IntHeapBig []HeapItem

func (h IntHeapBig) Len() int           { return len(h) }
func (h IntHeapBig) Less(i, j int) bool { return h[i].value > h[j].value }
func (h IntHeapBig) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }

func (h *IntHeapBig) Push(x interface{}) {
	*h = append(*h, x.(HeapItem))
}

func (h *IntHeapBig) Pop() interface{} {
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[0 : n-1]
	return x
}

func maxSlidingWindow(nums []int, k int) []int {
	if len(nums) == 0 {
		return nil
	}
	ret := []int{}
	// 创建一个大根堆
	bheap := IntHeapBig{}
	heap.Init(&bheap)
	for i := 0; i < k-1; i++ {
		heap.Push(&bheap, HeapItem{nums[i], i})
	}

	// 添加一个元素，必须弹出一个合适的元素
	for i := k - 1; i < len(nums); i++ {
		heap.Push(&bheap, HeapItem{nums[i], i})
		for {
			item := heap.Pop(&bheap)
			if item.(HeapItem).index >= i-k+1 {
				ret = append(ret, item.(HeapItem).value)
				heap.Push(&bheap, item)
				break
			}
		}
	}
	return ret
}
```







