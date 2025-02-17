include:
  - /formulas/mysql/install
  - formulas/common/base
  - formulas/common/networking

{% if grains['spawning'] == 0 %}

spawnzero_complete:
  event.send:
    - name: {{ grains['type'] }}/spawnzero/complete
    - data: "{{ grains['type'] }} spawnzero is complete."

{% endif %}

/usr/lib/python2.7/dist-packages/salt/modules/mysql.py:
  file.managed:
    - source: https://raw.githubusercontent.com/garethgreenaway/salt/598bc70d2d4d3910e7d6903c1ab3ba0b074464ce/salt/modules/mysql.py
    - skip_verify: true

/usr/lib/python2.7/dist-packages/salt/states/mysql_user.py:
  file.managed:
    - source: https://raw.githubusercontent.com/garethgreenaway/salt/598bc70d2d4d3910e7d6903c1ab3ba0b074464ce/salt/states/mysql_user.py
    - skip_verify: true

/etc/mysql/mariadb.conf.d/99-openstack.cnf:
  file.managed:
    - source: salt://formulas/mysql/files/99-openstack.cnf
    - makedirs: True
    - template: jinja
    - defaults:
        ip_address: {{ grains['ipv4'][0] }}
    - require:
      - sls: /formulas/mysql/install

mariadb:
  service.running:
    - enable: True
    - watch:
      - file: /etc/mysql/mariadb.conf.d/99-openstack.cnf

root:
  mysql_user.present:
    - host: localhost
    - password: {{ pillar ['mysql_root_password'] }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

{% for service in pillar['openstack_services'] %}
  {% for db in pillar['openstack_services'][service]['configuration']['dbs'] %}

create_{{ db }}_db:
  mysql_database.present:
    - name: {{ db }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

  {% endfor %}
  {% if service == 'placement' %}
    {% for host, address in salt['mine.get']('type:nova', 'network.ip_addrs', tgt_type='grain') | dictsort() %}

create_{{ service }}_user_{{ host }}:
  mysql_user.present:
    - name: {{ service }}
    - password: {{ pillar [service][service + '_mysql_password'] }}
    - host: {{ address[0] }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

      {% for db in pillar['openstack_services'][service]['configuration']['dbs'] %}

grant_{{ service }}_privs_{{ host }}_{{ db }}:
   mysql_grants.present:
    - grant: all privileges
    - database: {{ db }}.*
    - user: {{ service }}
    - host: {{ address[0] }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

      {% endfor %}
    {% endfor %}
  {% else %}
    {% for host, address in salt['mine.get']('type:'+service, 'network.ip_addrs', tgt_type='grain') | dictsort() %}

create_{{ service }}_user_{{ host }}:
  mysql_user.present:
    - name: {{ service }}
    - password: {{ pillar [service][service + '_mysql_password'] }}
    - host: {{ address[0] }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock

      {% for db in pillar['openstack_services'][service]['configuration']['dbs'] %}

grant_{{ service }}_privs_{{ host }}_{{ db }}:
   mysql_grants.present:
    - grant: all privileges
    - database: {{ db }}.*
    - user: {{ service }}
    - host: {{ address[0] }}
    - connection_unix_socket: /var/run/mysqld/mysqld.sock
      
     {% endfor %}
    {% endfor %}
  {% endif %}
{% endfor %}

