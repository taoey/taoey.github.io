---
layout: post
title: 实战Nginx-LVS双机热备集群
categories: [nginx,高可用集群]
description: 实战Nginx-LVS双机热备集群
keywords: nginx,高可用
---



一般情况下我们会使用Nginx用做路由转发或者部署我们的静态资源，那你知道如何什么是Nginx的高可用，并如何实现吗？

# 一、Nginx高可用



为了屏蔽负载均衡服务器的宕机，需要建立一个备份机。主服务器和备份机上都运行高可用（High Availability）监控程序，通过传送诸如“Iam alive”这样的信息来监控对方的运行状况。当备份机不能在一定的时间内收到这样的信息时，它就接管主服务器的服务IP并继续提供负载均衡服务；当备份管理器又从主管理器收到“I am alive”这样的信息时，它就释放服务IP地址，这样的主服务器就开始再次提供负载均衡服务。

# 二、keepalived



Keepalived软件起初是专门为LVS（**Linux Virtual Server**）负载均衡软件设计的用来管理并监控LVS集群系统中各个服务节点的状态，后来又加入了可以实现高可用的VRRP功能。因此，Keepalived除了能够管理LVS软件外，还可以作为其他服务的高可用解决方案软件。

Keepalived软件主要是通过VRRP协议实现高可用功能的,VRRP是Virtual Router Redundancy Protocol（虚拟路由器冗余协议）的缩写.VRRP出现的目的就是为了解决静态路由单点故障问题的

**VRRP原理**

![image](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596005204240-a77b93df-346c-4a0a-b8ec-4b1606f86d38.png)

- master在工作状态会不断群发一个广播包(内涵优先参数)
- 其他路由收到收到广播后会和自己的优先参数作对比,如果优先参数小于自己则什么都不执行,如果优先参数大于自己则开启争抢机制
- 如果启动了争抢机制,他就会群发自己的优先参数,最终优先参数最小的称为master路由.



本文Nginx灾备集群便是基于keepalived，利于其机制故障转移特性来实现Nginx的高可用。

# 三、实操部署

## 1、环境说明

- centos7
- docker
- nginx 1.6
- 虚拟机环境/真实服务器

Nginx在此次实验中的定位：资源服务器

## 2、部署结构图

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596260157193-c9c1837f-bf89-44ea-8537-41d447306be7.png)

## 3、实操部署

我们事先准备两台虚拟机，并且保证网络畅通，如下图：

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596260188082-352353d9-bfff-483d-b248-4f68ca895edd.png)

（1）docker 安装

如下命令可以直接安装docker，已经有docker环境的可以直接略过该步骤

```
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sudo yum  makecache fast
sudo yum -y install docker-ce
sudo systemctl start docker
docker run hello-world
```



（2）docker-nginx安装

两台服务器同时安装Nginx，所需的配置文件和重启脚本我都已经准备好了，可在如下地址获取

https://github.com/Taoey/tao-dockerfiles/tree/master/nginx

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596262247379-003e00ea-a7bd-4b4f-9f47-50710440ca06.png)



在我们的两台服务器上分别创建一个目录存放如上文件，这是我的配置。注意如果start.sh没有执行权限的话，可以使用`chmod +x start.sh` 为我们的文件赋权

```
[root@192 nginx]# pwd
/root/soft/nginx
[root@192 nginx]# ls
conf  html  logs  start.sh
```

有了如上的文件，直接在该目录下执行`./start.sh` ，即可创建一个docker-nginx服务，效果如下图

```
[root@192 nginx]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
2e90b26259e1        nginx:1.16          "nginx -g 'daemon of…"   6 minutes ago       Up 6 minutes        0.0.0.0:8080->80/tcp   nginx-server
```

启动之后的效果：

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596262575094-50eae203-45ed-48e6-8e57-3316f60d405a.png)



为了后期比较直接的区分这两台服务器，我们需要编辑刚刚从我的github上下载的nginx的相关文件：html文件夹下的index.html，我们以修改主节点为例

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596262815932-57886598-8258-46dc-b9e4-16dc3c457a0d.png)





刷新网页，修改之后的效果图：

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596262912368-492f67e8-b825-411b-b235-da2ba341d115.png)

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596262925533-21933011-fbbf-443a-ab91-5629199d877d.png)



## 4、安装配置keepalived

（1）安装keepalived

```
#外网环境安装
yum install -y curl gcc openssl-devel libnl3-devel net-snmp-devel
yum install -y keepalived
```

（2）修改配置文件

修改配置文件：vi /etc/keepalived/keepalived.conf 

需要修改的位置：

- global_defs 配置下，删除掉vrrp_strict配置
- state ：主节点为MASTER，备节点为BACKUP
- interface ：需要绑定的网卡（可以通过ifconfig查看，我的是ens33）
- priority ：主节点配置成100，备节点配置成99
- virtual_ipaddress ： 虚拟IP，两个节点需要相同

只需要修改这5处即可，其他可不用修改，部分配置如下：

```
vrrp_instance VI_1 {
    state MASTER
    interface ens33
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.2.111
    }
}
```

修改完配置文件之后，重启keepalived，重启命令和其他相关命令如下：

```
systemctl enable keepalived # 开机自启动
systemctl start keepalived     # 启动
systemctl stop keepalived     # 暂停
systemctl restart keepalived  # 重启
systemctl status keepalived   # 查看状态  
```

（3）检查结果

对两台服务器分别执行`ip a`命令：

主节点执行结果：

```
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 00:0c:29:67:13:0b brd ff:ff:ff:ff:ff:ff
    inet 192.168.2.109/24 brd 192.168.2.255 scope global dynamic ens33
       valid_lft 4718sec preferred_lft 4718sec
    inet 192.168.2.111/32 scope global ens33
       valid_lft forever preferred_lft forever
    inet6 fe80::25d3:a617:69d0:2d52/64 scope link 
       valid_lft forever preferred_lft forever
    inet6 fe80::21f4:56b8:342f:acaf/64 scope link tentative dadfailed 
       valid_lft forever preferred_lft forever
```

访问http://192.168.2.111:8080/ 发现是主节点IP，keepalived配置完成

![image.png](http://taoey.github.io/assets/images/artcles/2021-2-5-nginx-lvs双机热备.assets/1596283134847-d3a31211-9d83-4d64-b5bc-1aad556a81d0.png)



主节点停掉keepalived服务的话，systemctl stop keepalived ，可以发现http://192.168.2.111:8080/现在访问的是备用节点

主节点重启 keepalived服务，http://192.168.2.111:8080/ 域名访问的又是主节点了。

也可以通过：**tail -f /var/log/messages** 命令来检查keepalived的日志哦~

## 5、绑定Nginx进程和Keepalived服务

上一步我们做的只是keepalived虚拟IP的配置，还没有实现真正的Nginx的高可用。通过如上配置我们可以知道，虚拟IP的切换是通过keepalived服务的启动和停止进行的。

因此，我们需要将Nginx进程的健康绑定到keepalived上，那如何绑定？我们可以通过linux的定时任务进行绑定，配置过程如下：

**（1）编写定时检查脚本**

主备节点都要添加该脚本 vi /etc/keepalived/nginx_check.sh

该脚本的原理是通过检查Nginx进程个数来判断Nginx的健康的，如果你的docker容器中有其他Nginx进程，需要先把这些Nginx关掉。

```
#!/bin/bash
A=`ps -C nginx --no-header |wc -l`
B=`ps -C keepalived --no-header |wc -l`
# nginx 不在运行状态 ：尝试重启nginx，三秒后如果nginx仍然未运行，关闭keepalived，节点切换到备用节点
if [ $A -eq 0 ];then
      /usr/bin/docker restart nginx-server   #正常情况下这里需要重启 nginx，注意这是docker容器的重启命令
      sleep 3
      if [ `ps -C nginx --no-header |wc -l` -eq 0 ];then
          ps -ef|grep keepalived|grep -v grep|awk '{print $2}'|xargs kill -9
      fi
fi
# nginx 处于运行状态,但keepalived处于非运行状态:重启keepalived
if [ $A -ne 0 -a $B -eq 0 ];then
    systemctl restart keepalived
fi
```

**（2）配置环境变量**

这个配置是一个注意点，之前出现过linux定时任务脚本中无法执行linux命令的情况，原因是没有把环境变量添加到linux定时脚本中，这里保险起见需要进行如下配置：

```
# 将docker所在位置/usr/bin 添加到环境变量中
echo "export PATH=\$PATH:/usr/bin" >> /etc/profile
# 刷新环境变量
source /etc/profile
```

**（3）添加linux定时任务**

```
# 编辑定时任务
crontab -e
# 添加/修改自启配置与如下相同
*/1 * * * * . /etc/profile;/bin/sh  /etc/keepalived/nginx_check.sh #每分钟进行检查 解决环境变量问题
```

到此为止，我们就实现Nginx的高可用啦，

# 四、结语



Nginx高可用的配置，其实原理还是挺简单的：

核心观点就是：

- keepalived能够实现虚拟IP映射到实体主机上，并通过keepalived服务进程健康进行IP映射的切换
- 通过linux定时任务实现