# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "etcd/map.jinja" import etcd_settings with context -%}

etcd-config:
  file.managed:
    - name: {{ etcd_settings.config }}
    - source: salt://etcd/files/etcd.conf.jinja
    - mode: 644
    - user: root
    - group: root
    - template: jinja
