---
layout: post
title: go单元测试-基本概念及命令
categories: [go]
description: go单元测试
keywords: golang,go,test,单元测试
---

本文主要介绍golang的单元测试，包含单元测试基本概念，如何进行不同函数单元测试,压测等

# 一、单元测试

## 单元测试框架基准

1、文件命名规则： 含有单元测试代码的go文件必须以_test.go结尾，一般测试文件和待测试文件在同一个文件夹内。

2、函数声明规则：  测试函数的签名必须接收一个指向testing.T类型的指针，并且函数没有返回值。

3、函数命名规则：单元测试的函数名必须以Test开头，是可导出公开的函数，最好是Test+要测试的方法函数名。 

 

## 常用选项

```plain
-v  ：查看更详细的测试结果输出
-run：指定输出哪个函数的测试结果，默认为当前路径下所有单元测试函数
-coverprofile：指定生成覆盖率测试输出文件
```

 

#  二 、基准测试

工具推荐：benchstat

安装：go get golang.org/x/perf/cmd/benchstat （将会安装到$GOPATH/bin目录下，需要将该目录配置到环境变量中）

 

## 1、什么是基准测试

基准测试是一种**测试代码性能**的方法，主要通过测试CPU和内存等因素，来评估代码性能，以此来调优代码性能。

 

## 2、编写规则

```plain
1、文件命名规则：  
   含有单元测试代码的go文件必须以_test.go结尾，Go语言测试工具只认符合这个规则的文件  
   单元测试文件名_test.go前面的部分最好是被测试的方法所在go文件的文件名。
 
2、函数声明规则：  
   测试函数的签名必须接收一个指向testing.B类型的指针，并且函数没有返回值。
 
3、函数命名规则：  
   单元测试的函数名必须以Benchmark开头，是可导出公开的函数，最好是Benchmark+要测试的方法函数名。
 
4、函数体设计规则：
   b.N 是基准测试框架提供，用于控制循环次数，循环调用测试代码评估性能。
    b.ResetTimer()/b.StartTimer()/b.StopTimer()用于控制计时器，准确控制用于性能测试代码的耗时。
```

## 3、基准测试命令选项

 

### **命令参数**

- `-bench=.` 表示指定执行测试函数。`.`表示执行所有，如果修改为`go test -bench=BenchmarkJoinStrUseSprint`那么只会执行`BenchmarkJoinStrUseSprint`。
- `-benchtime=1s`指定执行时间为`1s`
- `-benchmem`显示内存情况
- `-count=1`表示执行一次

### **响应参数**

- `goos: linux` 操作系统
- `goarch: amd64` 系统体系架构
- `BenchmarkJoinStrUseNor-8` 执行的函数名称以及对应的`GOMAXPROCS`值。
- `79888155``b.N`的值
- `15.5 ns/op` 执行一次函数所花费的时间
- `0 B/op` 执行一次函数分配的内存
- `0 allocs/op` 执行一次函数所分配的内存次数



这几个数当然是**越小越好**

```go
操作命令：go test  -bench=. benchtime=3s -run=none -cpuprofile
    -bench      ：go test默认不会基准测试，需要使用bench启动基准测试，指定匹配基准测试的函数，“.”表示运行所有基准测试
    
    -benchtime  ：测试时间默认为1s，如果想测试运行时间更长，用-benchtime指定
    
    -run        ：默认情况下go test会运行单元测试，为防止其干扰基准测试输出结果，
                    可使用-run过滤单元测试，使用none完全屏蔽，“.”运行所有单元测试  
                    
    -count      ：指定执行多少次
 
        $ go test  -bench=. -run=none
        goos: linux
        goarch: amd64
        pkg:   learning/test/benchmark
        BenchmarkSprintf-12       20000000                70.6   ns/op
        PASS
        ok      learning/test/benchmark   1.485s
 
        其中BenchmarkSprintf-12，12表示GOMAXPROCS，20000000表示循环次数，70.6 ns/op表示单次循环操作花费时间
 
    -cpuprofile ：生成运行时CPU详细信息
    go test  -bench=. -run=none -cpuprofile=xxx xxx

    (pprof) quit
 
    -benchmem     ：提供每次操作分配内存的次数，以及每次分配的字节数。
    $ go test  -bench=. -benchmem -run=none
    goos: linux
    goarch: amd64
    pkg:   learning/test/benchmark
    BenchmarkSprintf-12       20000000                70.5   ns/op            16   B/op          2 allocs/op
    BenchmarkFormat-12      20000000                77.1   ns/op            18   B/op          2 allocs/op
    BenchmarkItoa-12        20000000                78.4   ns/op            18   B/op          2 allocs/op
    PASS
    ok      learning/test/benchmark   4.754s
```

 

## 4、实例1：slice的不同使用方式 

```go
package benchmark
 
import (
    "testing"
)
 
const TotalTimes = 1000000
 
func StaticCapacity() {
 
    // 提前一次性分配好slice所需内存空间，中间不需要再扩容，len为0，cap为1000000
    var s   = make([]byte, 0, TotalTimes)
 
    for i :=   0; i < TotalTimes; i++ {
        s = append(s, 0)
        //fmt.Printf("len   = %d, cap = %d\n", len(s), cap(s))
    }
}
 
func DynamicCapacity() {
 
    // 依赖slice底层自动扩容，中间会有很多次扩容，每次都从新分配一段新的内存空间，
    // 然后把数据拷贝到新的slice内存空间，然后释放旧空间，导致引发不必要的GC
    var s []byte
 
    for i :=   0; i < TotalTimes; i++ {
        s = append(s, 0)
        //fmt.Printf("len   = %d, cap = %d\n", len(s), cap(s))
    }
}
 
func BenchmarkStaticCapacity(b   *testing.B) {
    b.ResetTimer()
 
    for i :=   0; i < b.N; i++ {
        StaticCapacity()
    }
}
 
func BenchmarkDynamicCapacity(b   *testing.B) {
    b.ResetTimer()
 
    for i :=   0; i < b.N; i++ {
        DynamicCapacity()
    }
}
```



测试结果: 

模式 | 操作时间消耗 ns/op | 内存分配大小 B/op | 内存分配次数 allocs/op

```go
$ go test  -bench=. -run=none -benchmem 
goos: linux
goarch: amd64
pkg: learning/testing/benchmark
BenchmarkStaticCapacity-12          3000            912668   ns/op         1007617   B/op          1 allocs/op
BenchmarkDynamicCapacity-12           1000           1935269   ns/op         5863427   B/op         35 allocs/op
PASS
ok      learning/testing/benchmark      4.914s
```

 

可以看出StaticCapacity 性能明显优于DynamicCapacity，所以如果同一个slice被大量循环使用，可提前一次性分配好适量的内存空间

总结：在代码设计过程中，对于性能要求比较高的地方，编写基准测试非常重要，这有助于我们开发出性能更优的代码。不过性能、可用性、复用性等也要有一个相对的取舍，不能为了追求性能而过度优化。

 

 

# 参考资料

- https://github.com/sxs2473/go-performane-tuning
- https://www.cnblogs.com/wayne666/p/10559900.html







