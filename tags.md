---
layout: default
title: Tags
permalink: /tags/
---

{% assign sorted_tags = site.tags | sort %}

<div class="container">

<h1>Tags</h1>

<div class="tag-container">
  {% for tag in sorted_tags %}
  <a class="badge bg-CortanaDesign-blue-dark fs-5 mb-1" href="/tags/#{{ tag[0] }}">{{ tag[0] }}</a>
  {% endfor %}
</div>

{% for tag in sorted_tags %}
{% assign t = tag | first %}
{% assign posts = tag | last %}

  <h4 id="{{ t }}" class="text-capitalize">{{ t }}</h4>

  <ul>
  {% for post in posts %}
    {% if post.tags contains t %}
    {% unless post.categories contains "drafts" %}
     <li>
      {% if post.external_url %}
      <a href="{{ post.external_url }}" target="_blank"
        ><span class="badge bg-secondary me-1">
          <i class="fa-solid fa-arrow-up-right-from-square me-1"></i>External Post </span
        >{{ post.title }}
        </a>
      {% else %}
      <a href="{{ post.url }}">{{ post.title }}</a>
      {% endif %}<span class="tags"> - {{ post.date | date: "%B %-d, %Y"  }}</span>
      </li>
      {% endunless %}
    {% endif %}
  {% endfor %}
  </ul>
{% endfor %}
</div>
