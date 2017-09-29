# this is hack - we are running locally on the etcd minions
# but we need the kube-apiservers to go down, which might
# not be running on the same machine if we're configured
# in a non-standard topology

etcd-upgrade-kube-apiserver-stop:
  service.dead:
    - name: kube-apiserver

etcd-upgrade-kube-apiserver-wait:
  cmd.run:
    - name: |
        {% for master in salt['pillar.get']('kubernetes:masters').keys() %}
        while curl {{ master }}:8080 >/dev/null; do sleep 2; done 
        {% endfor %}
    - timeout: 30


