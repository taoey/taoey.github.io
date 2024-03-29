---
layout: post
title: 斐讯N1--Armbian系统的安装及配置
categories: [斐讯N1]
keywords: #工具
wxurl:
---

关于斐讯N1刷机到Armbian5.44的全方面指南

本文N1初始系统为YYF，并不是斐讯初始的系统，仅供参考

## 1、需要准备的资源



### 1.1 硬件

- 斐讯N1盒子一台（带电源）
- 金士顿3.0U盘一个（大于8G的U盘即可）

- HDMI线一条
- 显示器一个

- window电脑一台（刻录U盘使用，本人使用的win7）



### 1.2 软件

- U盘刻录工具

- 外置系统启动器_1.1.apk
- Armbian5.44系统

- 恩山大佬的N1固件兼容包



资源链接

```
链接：https://pan.baidu.com/s/1uNeVcgHUo8ojc34yw2HL6A 
提取码：630w 
```



## 2、刷机

比较推荐ARMBIAN用U盘启动，方便折腾，不需要把系统刷入N1的emmc，这个刷机可以保证N1上面的电视系统和U盘Armbian系统共存，不用Armbian的时候，直接把U盘拔掉即可



### 2.1 系统U盘制作

刷机之后

注意：如果系统盘制作失败，重新制作需要先把U盘做清空操作，此处参考了这篇文章http://www.kqidong.com/question/question_3673.html



```bash
# windows cmd下
diskpart
# 查看对应磁盘
list disk 
# 选在对应的U盘磁盘
select disk 2
# 清空
clean
```



然后在磁盘管理工具中选择对应磁盘，右键‘新建简单卷’即可



### 2.2 N1盒子安装外部启动软件

用U盘在盒子上安装"外部启动软件"

### 2.3 刷机

我使用的是 Armbian_5.44_S9xxx_Ubuntu_bionic_3.14.29_server_20180729.img，这版本的Armbian

- 将系统写入到U盘之后，将补丁包放到dtb目录
- 修改uEnv.ini，改成如下配置

```go
dtb_name=/dtb/meson-gxl-s905d-phicomm-n1-xiangsm.dtb
bootargs=root=LABEL=ROOTFS rootflags=data=writeback rw console=ttyS0,115200n8 console=tty0 no_console_suspend consoleblank=0 fsck.fix=yes fsck.repair=yes net.ifnames=0 mac=${mac} 
```



刷机之后，按照提示输入初始用户名密码 root ， 1234 （如果提示什么token 错误啥的，再试一遍即可，不行就重新刷）

之后会提示让你修改密码 （密码有位数要求，我重置为了 123456tao）

然后提示你新建一个用户（我建立了一个 work用户，密码123456tao）



配置界面

*armbian*-config 

## 3、Armbian配置



### 3.1 WIFI 配置

Armbian5.44 需要加载wifi驱动，否则使用nmtui或者armbian-config均无法获取wifi信息

```basic
modprobe dhd && echo dhd >> /etc/modules
```







如果连接WiFi后，先不要执行 `ping www.baidu.com`测试网络连通性，我们需要先修改DNS，如果真的想测试的话，可以先获取`www.baidu.com`的公网ip，然后ping对应的ip测试



### 3.2 修改DNS及apt源

```bash
# 删除默认DNS
rm /etc/resolvconf/resolv.conf.d/head && touch /etc/resolvconf/resolv.conf.d/head

# 更换软件源



vim /etc/apt/sources.list.d/armbian.list

deb http://mirrors.nju.edu.cn/armbian/ bionic main bionic-utils bionic-desktop


  vim /etc/apt/sources.list

deb http://ports.ubuntu.com/ bionic main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ bionic main restricted universe multiverse

deb http://ports.ubuntu.com/ bionic-security main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ bionic-security main restricted universe multiverse

deb http://ports.ubuntu.com/ bionic-updates main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ bionic-updates main restricted universe multiverse

deb http://ports.ubuntu.com/ bionic-backports main restricted universe multiverse
# deb-src http://ports.ubuntu.com/ bionic-backports main restricted universe multiverse
deb [arch=arm64] https://download.docker.com/linux/debian bionic stable
# deb-src [arch=arm64] https://download.docker.com/linux/debian bionic stable


# 更新软件包
apt update && apt upgrade -y
```

注：在重启系统后，输入cat /etc/resolv.conf，查看返回结果是否为你路由器的 DNS，如果是，则表示删除成功，如果不是，则再执行一次删除命令，或者直接配置成8.8.8.8



### 3.4 停止、删除红外支持(5.44)

由于 N1 没有红外，造成红外支持找不到红外，一直给系统日志写错误，此问题仅存在于 5.44 版本。

```bash
# 停止红外支持
systemctl stop lircd.service lircd-setup.service lircd.socket lircd-uinput.service lircmd.service

# 删除红外支持
apt remove -y lirc && apt autoremove -y
```

syslog中每10s出现一次ttyS2服务启动失败的日志。不理它也没关系，也可以通过以下方式解决：

```bash
sudo systemctl disable serial-getty@ttyS2
```

### 3.5 设置中国时区

```bash
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo 'Asia/Shanghai' > /etc/timezone
```

### 3.5 重启系统

```bash
reboot
```

### 3.6 挂载移动硬盘

推荐把外置存储设备分区格式化为 ext4 格式，不推荐使用 NTFS 格式。

如果你的外置存储设备是 NTFS 格式，可以使用mkfs.ext4命令将你的外置存储设备格式化为 ext4 格式，格式化前提前备份数据。

可以用fdisk -l查看你的外置存储设备是那个设备，一般是/dev/sdb，分区是/dev/sdb1，如果有多个分区，依次类推。

输入mkfs.ext4 /dev/sdb1将分区格式化为 ext4，格式化完成后使用fdisk -l查看是否格式化成功



```bash
# 查看磁盘分区
fdisk -l

# 挂载磁盘到 /home/work/ntfs
mount -t ntfs-3g /dev/sdb1 /home/work/ntfs

# 最后使用完之后一定要记得卸载
umount /dev/sdb1
```





### 3.7 SMB安装及配置



```bash
# 安装
apt-get update
apt-get install samba

# 配置
vim /etc/samba/smb.conf

# 将下方内容写到该配置文件的最下方，注意path需要改成你自己的需要分享的目录
[share]
path = /home/work/ntfs
readonly = no
writable = yes


# 保存后需要设置一个用户和密码，该用户必须是系统已有用户，按照提示输入密码即可（方面起见我都设置为了123456tao）
smbpasswd -a work

# 重启samba服务
service smbd restart
```





**到现在为止，我们就拥有一台比较省点的nas系统了，推荐投影仪（可直接在当贝商店中下载），手机平板使用Nplayer这个软件观看分享目录中的软件**



### 3.8 安装配置docker

通过 arch 命令可以知道斐讯的架构为aarch64，因此需要下载对应架构的docker （参考自[如何查看linux系统的体系结构](https://blog.csdn.net/lixuande19871015/article/details/90485929)）

下载地址： https://download.docker.com/linux/static/stable/aarch64/



安装参考：

此处为语雀内容卡片，点击链接查看：https://www.yuque.com/go/doc/6916520

### 3.9 安装nginx

```plain
apt-get install nginx
```



### 3.10 安装redis

```plain
redis-server  # 或者使用docker 安装 docker pull arm64v8/redis
```



### 3.11 安装MySQL

```plain
apt install mysql-server
apt-get install mysql
```



### 3.12 内网穿透ngrok

登录ngrok 官网https://dashboard.ngrok.com/get-started/setup

下载红框中的版本，之后按照步骤操作即可

![img](http://beangogo.cn/assets/images/artcles/2021-09-25-N1-Armbian系统安装配置.assets/1633228917814-f4794779-6aaa-4488-a632-88efdab5b543.png)



参考资料：

- 刷机后的配置项：https://blog.csdn.net/weixin_31736005/article/details/114486783
- linux下读取移动硬盘：https://blog.csdn.net/weixin_30911809/article/details/99279542

- 修改源：https://hanximeng.com/zyfx/1060.html