---
layout: page
title: 诗歌
description: 那些有诗的日子，阳光灿烂
keywords: 维基, poetry
comments: false
menu: 诗歌
permalink: /poetry/
---

> 那些平凡的日子，也很美丽

<ul class="listing">
{% for poetry in site.poetry reversed  %}
{% if poetry.title != "poetry Template" %}
<li class="listing-item"><a href="{{ poetry.url }}">{{ poetry.title }}</a></li>
{% endif %}
{% endfor %}
</ul>
