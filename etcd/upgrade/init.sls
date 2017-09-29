{% from "etcd/map.jinja" import etcd_settings with context -%}

# run if
# 1. is installed (current_version is truthy), and
# 2. if current_version < settings version

{% set current_version = salt['pkg.version']('etcd') %}
{% if current_version and salt['pkg.version_cmp'](current_version, etcd_settings.version) == -1 %}
include:
  - .stop-world
  - .migrate
{% endif %}
