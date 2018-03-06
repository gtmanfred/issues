# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "etcd/map.jinja" import etcd_settings with context -%}

etcd-systemd-conf:
  file.managed:
    - name: {{ etcd_settings.service.config }}
    - source: salt://etcd/files/etcd.service
    - mode: 644
    - user: root
    - group: root


etcd-service:
  service.running:
    - name: {{ etcd_settings.service.name }}
    - enable: True
    - init_delay: 30
    - watch:
      - file: etcd-systemd-conf


