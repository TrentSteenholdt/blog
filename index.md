---
layout: default
title: Blog
pagination:
  enabled: true
  per_page: 9
  permalink: '/page:num/'
  sort_field: 'date'
  sort_reverse: true
---

<div class="container-xxl">
  <div class="row row-cols-1 row-cols-md-3 g-4 my-2">

  {% for post in paginator.posts %}
      <div class="col">
        <div class="card rounded-0">
          {% if post.external_url %}
            <a href="{{ post.external_url }}" target="_blank">
              <img src="{{ post.image }}" class="card-img-top height rounded-0" alt="{{ post.title }}">
            </a>
          {% else %}
            <a href="{{ post.url }}">
              <img src="{{ post.image }}" class="card-img-top height rounded-0" alt="{{ post.title }}">
            </a>
          {% endif %}
          <div class="card-body text-left">
            {% if post.external_url %}
              <span class="badge bg-secondary me-1 mb-1">
                <i class="fa-solid fa-arrow-up-right-from-square me-1"></i>External Post
              </span>
            {% endif %}
            {% if post.external_url %}
              <a href="{{ post.external_url }}" target="_blank">
                <h5 class="card-title">{{ post.title }}</h5>
              </a>
            {% else %}
              <a href="{{ post.url }}">
                <h5 class="card-title">{{ post.title }}</h5>
              </a>
            {% endif %}
            <p>
              {% for tag in post.tags %}
                <a class="badge text-bg-CortanaDesign-blue-dark" href="/tags/#{{ tag }}">{{ tag }}</a>
              {% endfor %}
            </p>
            <p class="card-text">
              {{ post.excerpt | default: post.content | strip_html | truncatewords: 50 }}
            </p>
          </div>
          <div class="card-footer">
            <small class="text-muted">
              {{ post.date | date: "%B %-d, %Y" }} by
              <a href="/author/{{ post.author }}">{{ post.author }}</a>
            </small>
          </div>
        </div>
      </div>
  {% endfor %}
  </div>
  <div class="pagination-wrapper mt-4 d-flex justify-content-center" aria-label="Page navigation">
    <ul class="pagination">
      <!-- Previous Page Link -->
      {% if paginator.previous_page %}
        <li class="page-item">
          <a class="page-link" href="{{ paginator.previous_page_path | relative_url }}" aria-label="Previous">
            <span aria-hidden="true">&laquo;</span>
          </a>
        </li>
      {% else %}
        <li class="page-item disabled">
          <span class="page-link">&laquo;</span>
        </li>
      {% endif %}

      <!-- Page Number Links -->
      {% assign start_page = paginator.page | minus: 4 | at_least: 1 %}
      {% assign end_page = paginator.page | plus: 4 | at_most: paginator.total_pages %}
      {% for page in (start_page..end_page) %}
        {% if page == 1 %}
          {% assign page_path = '/' %}
        {% else %}
          {% assign page_path = '/page' | append: page %}
        {% endif %}

        {% if page == paginator.page %}
          <li class="page-item active">
            <span class="page-link">{{ page }}</span>
          </li>
        {% else %}
          <li class="page-item">
            <a class="page-link" href="{{ page_path }}">{{ page }}</a>
          </li>
        {% endif %}
      {% endfor %}

      <!-- Next Page Link -->
      {% if paginator.next_page %}
        <li class="page-item">
          <a class="page-link" href="{{ paginator.next_page_path }}" aria-label="Next">
            <span aria-hidden="true">&raquo;</span>
          </a>
        </li>
      {% else %}
        <li class="page-item disabled">
          <span class="page-link">&raquo;</span>
        </li>
      {% endif %}
    </ul>
  </div>
</div>
