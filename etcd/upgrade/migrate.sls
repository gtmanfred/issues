{% from "etcd/map.jinja" import etcd_settings with context -%}

etcd-upgrade-service-stop:
  service.dead:
    - name: {{ etcd_settings.service.name }}
    - require:
        - cmd: etcd-upgrade-kube-apiserver-wait

etcd-upgrade-backup:
  cmd.run:
    - name: |
        etcdctl backup --data-dir=/var/lib/etcd/default.etcd --backup-dir=/var/lib/etcd/backup-`date +%F`-.etcd
    - require:
        - service: etcd-upgrade-service-stop

# points etcd client port at nothing
etcd-upgrade-config:
  file.managed:
    - name: {{ etcd_settings.config }}
    - source: salt://etcd/upgrade/files/etcd.conf.jinja
    - mode: 644
    - user: root
    - group: root
    - template: jinja

# we upgrade before migrating data so we can test convergence
# with `endpoint status`
etcd-upgrade-pkg-version:
  pkg.installed:
    - name: etcd
    - version: {{ etcd_settings.version }}
    - update_holds: True

etcd-upgrade-service-start:
  service.running:
    - name: {{ etcd_settings.service.name }}
    - require: 
        - pkg: etcd-upgrade-pkg-version
        - file: etcd-upgrade-config

# so ugly, but correct. we check to see if the raftIndex's
# are within one of each other, a la
# https://coreos.com/etcd/docs/latest/op-guide/v2-migration.html

# we begin by repeating a trick from etcd-config
{% set client_port = etcd_settings.cluster.client_port|string -%}
{% set peer_string = [] -%}
{% for hostname,cfg in etcd_settings.cluster.peers.items() -%}
  {% do peer_string.append( cfg.ip + ":36667" ) -%} # FIXME: set port to real free port
{% endfor %}

# and now we patiently wait for convergence
etcd-upgrade-convergence:
  cmd.run:
    - name: |
        has_converged() {
          ETCDCTL_API=3 etcdctl endpoint \
            --endpoints="{{ peer_string|join(',') }}" \
            -w json status  | \
          python -c 'import json,sys; I=[int(o["Status"]["raftIndex"]) for o in json.load(sys.stdin) if "Status" in o.keys()]; sys.exit(0 if max(I)-min(I) <= 1 else 1)'
          return $?
        }
        until has_converged; do sleep 5; done;
        sleep 20
    - timeout: 120
    - require:
        - pkg: etcd-upgrade-pkg-version
        - service: etcd-upgrade-service-start

etcd-upgrade-service-stop-again:
  service.dead:
    - name: {{ etcd_settings.service.name }}
    - require:
        - cmd: etcd-upgrade-convergence

etcd-upgrade-migrate:
  cmd.run:
    - name: |
        ETCDCTL_API=3 etcdctl migrate --data-dir=/var/lib/etcd/default.etcd
    - runas: etcd
    - require:
        - service: etcd-upgrade-service-stop-again
    # these `require_in`s force the upgrade to finish before normal state begins
    - require_in:
        - pkg: etcd-pkg
        - file: etcd-config

# and from here on we should be able to defer to high-state
