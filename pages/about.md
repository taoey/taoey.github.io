---
layout: page
title: 关于
description: 有时候阳光很好，有时候阳光很暗，这就是生活。
keywords: handx, handexing
comments: true
menu: 关于
permalink: /about/
---

长风破浪会有时，直挂云帆济沧海。

## 联系

{% for website in site.data.social %}
* {{ website.sitename }}：[@{{ website.name }}]({{ website.url }})
{% endfor %}

## Skill Keywords

{% for category in site.data.skills %}
### {{ category.name }}
<div class="btn-inline">
{% for keyword in category.keywords %}
<button class="btn btn-outline" type="button">{{ keyword }}</button>
{% endfor %}
</div>
{% endfor %}
