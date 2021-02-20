---
layout: post
title: redis-运维之swap空间
categories: [redis]
description: redis-内存淘汰策略
keywords: redis,内存
---

前言：redis 2G内存是否能存储 2.5G 数据？



相关问题：redis 2G内存是否能存储 2.5G 数据？

答案：可以，不过操作系统会使用swap空间，swap空间由硬盘提供，对于高并发场景会严重降低系统可用性，如果是缓存场景可以配置内存淘汰策略，具体配置可见：  [redis-内存淘汰策略](http://beangogo.cn/2021/02/20/redis-缓存淘汰策略/)，同时现在有种使用ssd做reids的方法 [pika](https://www.cnblogs.com/ExMan/p/11529059.html)

---



原文地址：[Redis运维之swap空间](https://cloud.tencent.com/developer/article/1681396)

   swap空间对于操作系统来说比较重要，当我们使用操作系统的时候，如果系统内存不足，常常会将一部分内存数据页进行swap操作，以解决临时的内存困境。swap空间由磁盘提供，对于高并发场景下，swap空间的使用会严重降低系统性能，因为它引入了磁盘IO操作。

   在Linux中，提供了free命令来查询操作系统的内存使用情况，free 命令的结果中也包含了swap相关的情况，例如下面的结果中：

```javascript
[root@VM-0-14-centos ~]# free -ht
              total        used        free      shared  buff/cache   available
Mem:           1.8G        1.3G         72M        692K        433M        283M
Swap:            0B          0B          0B
Total:         1.8G        1.3G         72M
```

我们可以看到swap的值都是0，说明当前的内存是没有配置swap空间的，目前的操作系统的内存是足够的，通常情况下swap一行的used列应该是0B比较好，它证明你的操作系统内存充足，没有发生swap空间的交换操作。

实时查看swap的使用

Linux中还为我们封装了vmstat这个命令来查看系统的相关性能指标，其中也包含swap空间，其中和swap有关的指标是si和so，分别代表swap in和swap out，我们看看vmstat的执行结果：

```javascript
[root@VM-0-14-centos ~]# vmstat
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 4  0      0  73712  84464 362016    0    0     7    26    7    1  1  1 98  0  0
```

查看执行进程占用swap的情况

在Linux操作系统中，/proc/pid/smaps这个文件记录了当前进程所对应的内存映像信息，这个信息对于查询指定进程的swap使用情况很有帮助。下面以一个Redis实例进行说明：

```javascript
[root@VM-0-14-centos ~]# ps -ef|grep redis    
root      1711     1  0 Jul20 ?        00:20:15 src/redis-server 127.0.0.1:21243
root      2370     1  0 Jul20 ?        00:20:18 src/redis-server 127.0.0.1:21244
root      2371     1  0 Jul20 ?        00:20:13 src/redis-server 127.0.0.1:21263
root      7815  5781  0 23:39 pts/3    00:00:00 grep --color=auto redis
root     14804     1  0 Jul20 ?        00:20:39 redis-server *:6379
我们以14804这个redis进程为例
[root@VM-0-14-centos ~]# cat /proc/14804/smaps | grep Swap
Swap:                  0 kB
Swap:                  0 kB
Swap:                  0 kB
.....
Swap:                  0 kB
Swap:                  0 kB
Swap:                  0 kB
```

通常情况下，Linux服务器不会等到所有物理内存都被使用完再使用swap空间，它引入swapiness这个变量来决定操作系统使用swap空间的倾向程度，它的取值是0~100，值越大，表示操作系统使用swap的可能性越高，反之则越低。swapiness变量值存在于系统配置文件/proc/sys/vm/swappiness 和/etc/sysctl.conf中，其前面的文件在重启之后，就失效了，只有将这个值写入后面的文件，才能长久的保存下去。

```javascript
[root@VM-0-14-centos ~]# cat /proc/sys/vm/swappiness 
30
```

写入/etc/sysctl.conf的方法如下：

```javascript
echo vm.swappiness={value} >> /etc/sysctl.conf
```

Redis在不同版本下，对于swapiness的建议配置也不一样，通常情况下，swapness的值可以设置为：0、1、60、100这几个。

其中：

设置为60是默认值，

设置为100则操作系统会主动使用swap空间，

设置成为0的话，在Linux3.4以及更早的Linux版本中，内存不够时，倾向使用swap而不是OOM killer，在Linux3.5以及之后的版本中，倾向使用OOM Killer而不是swap空间

设置为1的话，在Linux3.5以及后续版本中，内存不够用的时候，倾向于使用swap空间，而不是OOM Killer

多说一句：OOM kill是指Linux发现操作系统不可用的时候，也就是Out Of Memory的时候，强制杀死一些非内核进程，来保证有足够的可用内存进行分配。一般OOM的日志记录在系统日志/var/log/message中