include:
  - /formulas/horizon/install
  - formulas/common/base
  - formulas/common/networking

{% if grains['spawning'] == 0 %}

spawnzero_complete:
  event.send:
    - name: {{ grains['type'] }}/spawnzero/complete
    - data: "{{ grains['type'] }} spawnzero is complete."

{% endif %}

/etc/openstack-dashboard/local_settings.py:
  file.managed:
    - source: salt://formulas/horizon/files/local_settings.py
    - template: jinja
    - defaults:
{% for server, address in salt['mine.get']('type:memcached', 'network.ip_addrs', tgt_type='grain') | dictsort() %}
        memcached_servers: {{ address[0] }}:11211
{% endfor %}
        keystone_url: {{ pillar['endpoints']['internal'] }}

/etc/apache2/conf-enabled/openstack-dashboard.conf:
  file.managed:
    - source: salt://formulas/horizon/files/openstack-dashboard.conf

/var/www/html/index.html:
  file.managed:
    - source: salt://formulas/horizon/files/index.html
    - template: jinja
    - defaults:
        dashboard_domain: {{ pillar['haproxy']['dashboard_domain'] }}

/var/lib/openstack-dashboard/secret_key:
  file.managed:
    - user: horizon
    - group: horizon

apache2_service:
  service.running:
    - name: apache2
    - watch:
      - file: /etc/openstack-dashboard/local_settings.py
      - file: /var/lib/openstack-dashboard/secret_key
      - file: /etc/apache2/conf-enabled/openstack-dashboard.conf
