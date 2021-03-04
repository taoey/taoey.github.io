---
layout: post
title: mysql redis 如何保证缓存一致性
categories: [mysql,redis]
description:  mysql redis 如何保证缓存一致性
keywords: mysql,redis,缓存一致性
---



前言：如何保证redis缓存在一些极端条件下拿到的数据是可靠得的？

## 问题探究：

一般系统里的缓存一致性策略为：先更新mysql中的数据，然后删除redis中的数据，但是这种策略，在一些极端操作下还是有问题的：

- 首先更新数据库(A)和删除缓存(B)不是原子操作，任何在A之后B之前的读操作，都会读到redis中的旧数据。
  正常情况下操作缓存的速度会很快，通常是毫秒级，脏数据存在的时间极端。
  但是，对超高并发的应用可能会在意这几毫秒。
- 更新完数据库后，线程意外被kill掉(真的很不幸)，由于没有删除缓存，缓存中的脏数据会一直存在。
- 线程A读数据时cache miss，从Mysql中查询到数据，还没来得及同步到redis中,
  此时线程B更新了数据库并把Redis中的旧值删除。随后，线程A把之前查到的数据同步到了Redis。
  显然，此时redis中的是脏数据。
  通常数据库读操作比写操作快很多，所以除非线程A在同步redis前意外卡住了，否则发生上述情况的概率极低。

虽然以上情况都有可能发生，但是发生的概率相比“先删除缓存再更新数据库”会低很多。



## 策略一、双删策略

先上伪代码：

```python
def write(key, value):
	redis.delKey( key )
	db.updateData( data )
	time.sleep( 0.5 ) #　sleep 500毫秒，睡眠时间应该为redis读操作最大用时
	redis.delKey( key )
```

结合双删策略+缓存超时设置，这样最差的情况就是在超时时间内数据存在不一致，而且又增加了写请求的耗时



## 策略二、binlog+canal+MQ

![img](https://raw.githubusercontent.com/Taoey/Taoey.github.io/master/_posts/greatArticle/2021-02-26-mysql-redis数据一致性.assets/1049928-78c959e0e4696330.webp)

MySQL binlog增量订阅消费+消息队列+增量数据更新到redis

- **读Redis**：热数据基本都在Redis
- **写MySQL**:增删改都是操作MySQL
- **更新Redis数据**：MySQ的数据操作binlog，来更新到Redis

**2.Redis更新**

**(1）数据操作主要分为两大块：**

- 一个是全量(将全部数据一次写入到redis)
- 一个是增量（实时更新）

这里说的是增量,指的是mysql的update、insert、delate变更数据。

**(2）读取binlog后分析 ，利用消息队列,推送更新各台的redis缓存数据。**

这样一旦MySQL中产生了新的写入、更新、删除等操作，就可以把binlog相关的消息推送至Redis，Redis再根据binlog中的记录，对Redis进行更新。

其实这种机制，很类似MySQL的主从备份机制，因为MySQL的主备也是通过binlog来实现的数据一致性。

这里可以结合使用canal(阿里的一款开源框架)，通过该框架可以对MySQL的binlog进行订阅，而canal正是模仿了mysql的slave数据库的备份请求，使得Redis的数据更新达到了相同的效果。

当然，这里的消息推送工具你也可以采用别的第三方：kafka、rabbitMQ等来实现推送更新Redis!



## 参考资料

- [Redis和mysql数据怎么保持数据一致的？](https://juejin.cn/post/6844903805641818120)
- [实现缓存最终一致性的两种方案](https://www.jianshu.com/p/fbe6a7928229?utm_source=oschina-app)

