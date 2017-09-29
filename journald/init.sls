# journald
{% from "journald/map.jinja" import journald with context -%}

journald_conf:
    file.managed:
        - name: /etc/systemd/journald.conf
        - makedirs: True
        - source: salt://journald/files/journald.conf.jinja
        - template: jinja

systemd-journald:
    service.running:
        - name: systemd-journald
        - enable: True
        - watch:
            - file: /etc/systemd/journald.conf
