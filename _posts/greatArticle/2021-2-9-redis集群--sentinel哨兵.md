---
layout: post
title: redis集群：sentinel哨兵
categories: [redis]
description: redis集群：sentinel哨兵
keywords: redis,集群
---

通过Redis Sentinel 来实现Redis的高可用集群方案，本文使用如上配置：一主两从

![image.png](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1595224812819-af458051-28cc-41f9-a8b0-54aadad0ed39.png)

整体架构：

- 当前采用主从机构+哨兵（sentinel），实现redis容灾的自动切换

  ![](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/sentinel.jpeg)

-  一个主节点（master）可拥有多个从节点（slave），从节点实现对主节点的复制，保证数据同步。而哨兵（sentinel）则对各节点进行监控，主要包括**主节点存活检测、主从运行情况检测**等，一旦主节点宕机，哨兵可自动进行**故障转移 （failover）、主从切换**。 
- 采用3台主机来进行配置，一个主机拥有一个redis服务器和sentinel

## 1. redis  安装

- redis安装步骤同mysoft平台部署文档中redis安装步骤，三台主机安装步骤相同

- 配置文件在主从配置中进行配置

## 2. redis 主从配置

- 将端口6379和26379添加为防火墙例外，保证服务器之前能相互进行通信

~~~
firewall-cmd --zone=public --add-port=6379/tcp --permanent
firewall-cmd --zone=public --add-port=26379/tcp --permanent
firewall-cmd --reload
~~~



- redis安装好后，修改主从服务器的配置，3台示例服务器如下图所示

| IP地址        | 端口号 | 角色           | 密码         |
| ------------- | ------ | -------------- | ------------ |
| 192.168.3.189 | 6379   | 主机（master） | mypassword |
| 192.168.3.190 | 6379   | 从机（slave）  | mypassword |
| 192.168.3.191 | 6379   | 从机（slave）  | mypassword |

- 主机（master）redis.conf配置,使用vi /mysoft/redis/redis.conf 进行修改

~~~
//Redis 默认只允许本机访问，把 bind 修改为 0.0.0.0 表示允许所有远程访问
bind: 0.0.0.0
//关闭保护模式
protected-mode no
//监听端口为6379 
port: 6379
//设置为后台启动
daemonize：yes
//pid文件路径
pidfile /var/run/redis.pid
//redis日志文件
logfile /mysoft/redis/log/redis.log
//数据库内容存放目录
dir /mysoft/redis/data
//redis连接密码
requirepass：mypassword
//slave 服务连接master的密码
masterauth：mypassword
//开启aof持久化方式
apendonly yes
~~~
- 从机（slave）redis.conf配置,使用vi /mysoft/redis/redis.conf 进行修改

~~~
bind: 0.0.0.0
protected-mode no
port: 6379
daemonize：yes
pidfile /var/run/redis.pid
logfile /mysoft/redis/log/redis.log
dir /mysoft/redis/data
requirepass：mypassword
masterauth：mypassword
//当指定本机为slave服务时， 设置 master 服务的IP地址及端口，在 redis 启动的时候会自动跟 master 进行数据同步，所以两台从机都这样配置即可。5.0版本之后为replicaof。
slaveof 192.168.231.130 6379 
appendonly yes
~~~

- 当主从节点的配置文件配置好后，重启redis服务，通过redis-cli 工具分别查看三台机器的信息

~~~
#cd /mysoft/redis/src
#redis-cli -p 6379 -a mypassword
>info replication
~~~

- 192.168.3.189: 6379 （master）
![](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596518761606.png)

- 192.168.3.190:6379 （slave）（当master_link_status 为 down 时，检查端口是否开启）

![](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596518870312.png)

- 主从验证，

  在主机master添加几条数据，查看从机slave是否可以获取到，如果可以获取到，则数据可以同步

  - 主机（master）

![1596519195543](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596519195543.png)

  - 从机（slave）

![1596519250568](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596519250568.png)

## 3. sentinel 文件配置

- sentinel 用于监控多个服务器，当主服务器（master）发生故障时，sentinel会自动进行故障迁移，进行主从切换

- 在redis安装目录下找到sentinel.conf文件进行配置，主机（master）和从机（slave）配置相同

  ~~~shell
  //端口默认为26379。
  port:26379
  //关闭保护模式，可以外部访问。
  protected-mode:no
  //设置为后台启动。
  daemonize:yes
  //日志文件。
  logfile:./sentinel.log
  //指定主机IP地址和端口，并且指定当有2台哨兵认为主机挂了，则对主机进行容灾切换。
  sentinel monitor mymaster 192.168.3.189 2
  //当在Redis实例中开启了requirepass，这里就需要提供密码。
  sentinel auth-pass mymaster mypassword
  //这里设置了主机多少秒无响应，则认为挂了。
  sentinel down-after-milliseconds mymaster 3000
  //主备切换时，最多有多少个slave同时对新的master进行同步，这里设置为默认的1。
  sentinel parallel-syncs mymaster 1
  //故障转移的超时时间，这里设置为三分钟。
  sentinel failover-timeout mymaster 180000
  ~~~

- 新建sentinel启动和关闭脚本

  ~~~shell
  start_sentienl.sh
  
  #!/bin/bash
  /mysoft/redis/src/redis-sentinel /mysoft/redis/sentinel.conf
  echo "sentinel started"
  
  stop_sentinel.sh
  
  #!/bin/bash
  /mysoft/redis/src/redis-cli -p 26379 -a mypassword shutdown
  echo "sentinel stoped"
  ~~~

- 通过启动脚本启动三个哨兵，使用如下命令查看哨兵信息

  ~~~shell
  #/mysoft/redis/src/redis-cli -p 26379
  >info sentine
  ~~~

- 哨兵已监听到master主机ip和端口和运行状态 ，并且有2台从机，3个哨兵 。

![1596521549910](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596521549910.png)

​		

## 4. 验证

- 将master主机重启查看从机是否会切换到主机模式，实现主从切换。

  - 重启master（192.168.3.189）后redis状态，当前显示192.168.3.191 从机服务器切换成为主机

    ![1596521966337](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596521966337.png)

  - 查看（192.168.3.191）服务器，此时从机切换成主机（master）

    ![1596522090356](https://raw.githubusercontent.com/taoey/taoey.github.io/master/_pics/2021-2-9-redis集群--sentinel哨兵.assets/1596522090356.png)