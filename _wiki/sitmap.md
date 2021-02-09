---
layout: wiki
title: sitmap
categories: wiki
description: 
keywords: 
---

```
{% assign sorted_categories = site.categories | sort %}
{% for category in sorted_categories %}
{% for post in category.last %}
http://beangogo.cn/{{ post.url }}
{% endfor %}
{% endfor %}
```
