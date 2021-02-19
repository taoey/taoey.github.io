---
layout: post
title: golang-redis连接池内存泄露分析
categories: [golang]
description: golang-redis连接池内存泄露分析
keywords: golang,redis,内存泄露,连接池
---

前言：

下面这段代码是一段redis初始化连接的代码，在初始化过程中我们增加了心跳检测协程，防止连接的自动关闭，同时需要加一个channel，监听退出事件

```go
func InitRedis() {
	if RedisConf.SentinelEnable == false {
		Pool = newPool(*RedisConf)
	} else {
		Pool = sentinelConnPool(*RedisConf)
	}
	if Pool != nil {
		//防止因超过idle时间而造成的连接关闭
		client := Pool.Get()
		go func() {
			for {
				select {
				// 防止goroutine泄露
				case <-RedisPingDestoryChannel:
					LOG.Debug("close redis ping goroutine")
					client.Close()
					return
				default:
					reply, err := client.Do("PING")
					if err != nil {
						LOG.Error("redis init error:", err)
					}
					LOG.Debug("exec ping：", reply, err)

					once.Do(func() {
						if err == nil {
							LOG.Info("redis init succeed")
						}
					})
				}
				time.Sleep(5 * time.Second)
			}
		}()
	}
}
```



配置发生变更，进行配置更新操作，需要释放对应的goroution

```go

if RedisConfChanged(conf) {
    LOG.Debug("Redis config update", conf)
    RedisPingDestoryChannel <- 1 // 释放redisPingGoroutine
    // 全局Redis赋值
    RedisConf = &conf
    InitRedis()
}
```



总结：使用goroution时时刻需要注意是否可能会发生内存泄露情况

