---
layout: page
title: 友链
description: 没有链接的博客是孤独的
keywords: 友情链接
comments: true
menu: 友链
permalink: /links/
---

> 太阳强烈，水波温柔

{% for link in site.data.links %}
* [{{ link.name }}]({{ link.url }})
{% endfor %}
