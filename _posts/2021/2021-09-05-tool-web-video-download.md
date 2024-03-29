---
layout: post
title: 网页视频下载工具
categories: [工具]
keywords: #工具
wxurl: https://mp.weixin.qq.com/s/2oRjrSUn8d_OyZaSGJ-XXw
---

> 有时我们有保存网页视频的需求，这类视频或是比较敏感的存在下架风险的视频，亦或者是你想下载该视频用用来做视频素材
>
> 我常用的网站大多为YouTube，B站

今天总结一下我自己常用的视频下载工具吧

### 1、谷歌浏览器插件--CoCoCut

![image-20210905125756199](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20210905125756199.png)



### 2、谷歌浏览器插件--Video Downloader Pro

![image-20210905125944110](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20210905125944110.png)



### 3、谷歌浏览器插件--bilibili哔哩哔哩下载助手

该插件作者已经收到律师函了，这个插件已经在谷歌插件商店下架了，不能直接从插件商店下载，所以无法直接安装，只能通过离线的方式安装，相关文档见如下链接

https://docs.qq.com/doc/DQ2lhaWRpS0tubVVF

![image-20210905130346910](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20210905130346910.png)

![image-20210905130757095](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20210905130757095.png)



### 4、you-get

我只能说you-get是永远的神，当然这种方法也比较折腾

官网：https://github.com/soimort/you-get

you-get功能:

1. 于您心仪的媒体播放器中观看在线视频，脱离浏览器与广告

2. 下载您喜欢的网页上的图片 下载任何非HTML内容，例如二进制文件

3. 目前已经支持的网站包括如下图

   ![image-20210905131420782](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20210905131420782.png)



那如何下载使用呢？

如果你是mac用户，那就灰常简单了，直接在控制台执行如下命令即可：

```shell
brew install you-get
```

使用最简单的命令，就可以下载视频了

```shell
$ you-get 'https://www.youtube.com/watch?v=jNQXAC9IVRw'
site:                YouTube
title:               Me at the zoo
stream:
    - itag:          43
      container:     webm
      quality:       medium
      size:          0.5 MiB (564215 bytes)
    # download-with: you-get --itag=43 [URL]

Downloading Me at the zoo.webm ...
 100% (  0.5/  0.5MB) ├██████████████████████████████████┤[1/1]    6 MB/s

Saving Me at the zoo.en.srt ... Done.

```

### 5、【推荐】视频链接解析

https://youtube.iiilab.com/

该视频解析网站，对于YouTube还支持音频的解析，很是不错，配合多线程文件下载工具是一个不错的选择，推荐使用

![image-20211005105958699](http://beangogo.cn/assets/images/artcles/2021-09-05-工具-网页视频下载.assets/image-20211005105958699.png)

### 6、结语

使用如上方法便可以下载常见的相关网页视频了，再也不用因为视频下架而烦恼了

