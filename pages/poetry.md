---
layout: page
title: 诗词
keywords: 维基, poetry
menu: 诗词
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
