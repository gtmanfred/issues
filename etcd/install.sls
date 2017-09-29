# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "etcd/map.jinja" import etcd_settings with context -%}

install versionlock:
  pkg.latest:
    - name: yum-plugin-versionlock

etcd-pkg:
  pkg.installed:
    - name: {{ etcd_settings.pkg }}
    - version: {{ etcd_settings.version }}
    - hold: true
    - update_holds: true

# This grains indicate we will collect metric about etcd process
grains-etcd-managed-set:
    grains.present:
        - name: salt_managed_pkgs:{{ etcd_settings.pkg }}
        - force: True
        - value:
            version: {{ etcd_settings.version }}
            proc: etcd
            monitor: True
            service: etcd

