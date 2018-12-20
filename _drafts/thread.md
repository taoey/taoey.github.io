---
layout: post
title: java多线程
categories: java
description: java多线程
keywords: java多线程
---

Java 平台提供了一套广泛而功能强大的API、工具和技术。其中，内建支持线程是它的一个强大的功能。

## 线程、进程的概念
> 线程是什么呢？但凡讲到线程时不得不提下“进程”，进程是什么呢？

- 进程：
进程是计算机中的程序关于某数据集合上的一次运行活动，是系统进行资源分配和调度的基本单位，是操作系统结构的基础。

- 线程：
线程可以理解成是在进程里面独立运行的一个子任务，一个进程中可以运行多个线程。

## 线程的使用
java的jdk中已经支持多线程，可以很方便进行多线程编程，实现多线程编程的方式主要有两种：

- 继承Thread类
- 实现Runnable接口

> **继承Thread类与实现Runnable接口哪个更好？**
1. java不支持多继承，如果已经继承了一个类就无法在继承Thread。
2. 实现Runnable是面向接口，扩展性等方面比继承Thread要好。
3. Runnable能增加程序的健壮性，代码能够被多个线程共享。

### 基础实例

- 继承Thread

```
package com.handx.thread;

class MyThread extends Thread {
	
	@Override
	public void run() {
		super.run();
		System.out.println("hello MyThread!");
	}
	
}

public class ThreadDeom {

	public static void main(String[] args) {
		MyThread thread = new MyThread();
		thread.start();
		System.out.println("run end.");
	}
}
```
> 继承Thread类重写run方法，实例化*MyThread*，调用start方法将线程启动。这是最简单的一个线程了。

- 实现Runnable接口

> 已经有父类了就不能继承Thread了，java不支持多继承，因而实现Runnable接口。

```
package com.handx.thread;

public class RunnableDemo implements Runnable {

	public static void main(String[] args) {
		RunnableDemo r = new RunnableDemo();
		Thread thread = new Thread(r);
		thread.start();
		System.out.println("run end.");
	}

	@Override
	public void run() {
		System.out.println("hello runnable!");
	}
}
```

> 需要Thread的构造方法，构造方法如下：
- Thread(Runnable target) 
- Thread(Runnable target, String name) 
- Thread(ThreadGroup group, Runnable target) 
- Thread(ThreadGroup group, Runnable target, String name) 
- Thread(ThreadGroup group, Runnable target, String name, long stackSize)






## 结语
以上代码都在我的github上，其中有问题或者不对的地方欢迎交流。
项目地址：[javaCoreSkill](https://github.com/handexing/javaCoreSkill)




