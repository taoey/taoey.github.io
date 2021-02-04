---
layout: page
title: 关于
description: 
keywords: taoey
comments: true
menu: 关于
permalink: /about/
---

长风破浪会有时，直挂云帆济沧海。

## 联系我
- 邮箱：hwt8080@163.com
<!-- {% for website in site.data.social %}
* {{ website.sitename }}：[@{{ website.name }}]({{ website.url }})
{% endfor %} -->

## 技能

<!-- {% for category in site.data.skills %}
### {{ category.name }}
<div class="btn-inline">
{% for keyword in category.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %} -->

- 开发语言 ：熟悉Golang基础，并发编程，垃圾回收，协程调度等底层运行原理，熟悉python开发，python爬虫，了解Java
- 数据库    ：熟悉MySQL使用及性能调优，熟悉Redis缓存相关应用场景，了解MongoDB

其他：
- 熟悉 Nginx使用及相关配置
- 熟悉docker及dockerfile编写
- 熟悉常见设计模式，数据结构及算法，TCP/IP协议及其他常见网络协议，Linux
- 熟悉微信公众号后端相关开发


## 工作经历

### 一、公司A--软件工程师（2019.8-至今）

（1）广告屏信息分发管理系统及相关子系统（Golang）

项目主要负责人，负责项目研发整体规划，功能研发测试，版本管理，性能测试及性能调优

主要负责功能模块如下：
- 文件存储模块：文件存储、CDN文件分发、限流、流量监控、七牛云对接
- 授权模块：服务器授权、终端授权
- 系统集群高可用部署方案及相关改造
- 邮件及系统告警模块：终端离线告警
- LED协议对接
- 容器化部署方案

（2）物流收发管理系统（Golang）

主要负责人，实现项目前后端从0到1全部功能

（3）KTV手机点歌平台及微信吸粉平台功能开发及维护（Python）

主要负责工作内容如下：
- KTV增值点歌活动开发及优化
- 日常优化线上MySQL慢查询
- 对sentry平台未知隐患异常及时修复
- 吸粉平台异常数据校对及相关问题处理


### 二、公司B--Java工程师（2018.10-2019.07）
数据采集平台的相关功能后端相关工作


## 其他项目

（1）个人开源  日志采集框架：go-log-listener
- github开源项目，为了更加便捷的实现日志文件监听功能，拥有自定义并发数量，文件监听起点，终止监听和重新监听功能，并内置了Nginx日志的监听相关示例

