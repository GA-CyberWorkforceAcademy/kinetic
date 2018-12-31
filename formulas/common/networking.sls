{% if grains['virtual'] == 'physical' %}
  {% set srv = 'hosts' %}
{% else %}
  {% set srv = 'virtual' %}
/etc/netplan/50-cloud-init.yaml:
  file.absent
{% endif %}

{% set management_address_octets = grains['ipv4'][0].split('.') %}

{% if grains['osfinger'] == 'Ubuntu-18.04' %}
{% if grains['role'] == 'storage' %}
/etc/netplan/01-netcfg.yaml:
  file.managed:
    - contents: |
        network:
          version: 2
          renderer: networkd
          ethernets:
            ens5f0:
              dhcp4: yes
            ens5f1:
              dhcp4: no
            ens5f2:
              dhcp4: no
            ens5f3:
              dhcp4: no
            ens7f0np0:
              dhcp4: no
            ens7f1np1:
              dhcp4: no
          bonds:
            sfe:
              interfaces:
                - ens7f0np0
                - ens7f1np1
          {%- set target_subnet = '10.30.0.0/22' %}
          {%- set target_subnet_netmask = target_subnet.split('/') %}
          {%- set target_subnet_octets = target_subnet_netmask[0].split('.') %}
              addresses: [{{ target_subnet_octets[0]}}.{{ target_subnet_octets[1]}}.{{ management_address_octets[2]}}.{{ management_address_octets[3]}}/{{ target_subnet_netmask[1]}}]
              parameters:
                mode: 802.3ad
            sbe:
              interfaces:
                - ens5f1
                - ens5f2
                - ens5f3
          {%- set target_subnet = '10.40.0.0/22' %}
          {%- set target_subnet_netmask = target_subnet.split('/') %}
          {%- set target_subnet_octets = target_subnet_netmask[0].split('.') %}
              addresses: [{{ target_subnet_octets[0]}}.{{ target_subnet_octets[1]}}.{{ management_address_octets[2]}}.{{ management_address_octets[3]}}/{{ target_subnet_netmask[1]}}]
              parameters:
                mode: 802.3ad
{% elif grains['role'] == 'haproxy' %}
/etc/netplan/01-netcfg.yaml:
  file.managed:
    - contents: |
        network:
          version: 2
          renderer: networkd
          ethernets:
            ens3:
              addresses:
                - 10.10.5.200/22
            ens4:
              addresses:
                - 10.50.10.0/16
              gateway4: 10.50.255.254
              nameservers:
                  search: [bbh.cyberschool.army.mil]
                  addresses: [10.50.255.254]
{% else %}
/etc/netplan/01-netcfg.yaml:
  file.managed:
    - contents: |
        network:
          version: 2
          renderer: networkd
          ethernets:
  {%- if pillar[srv][grains['type']]['networks']['bridge'] == false %}
    {%- for binding in pillar[srv][grains['type']]['networks']['bindings'] %}
      {%- for network in binding %}
        {%- if network == 'management' %}
            {{ binding[network] }}:
              dhcp4: yes
        {%- elif grains['type'] == 'cache' and network == 'public' %}
            {{ binding[network] }}:
              addresses: [{{ pillar['subnets']['public']['cache_ip'] }}/{{ pillar['subnets']['public']['network'].split('/')[1] }}]
        {%- else %}
          {%- set target_subnet = pillar['subnets'][network] %}
          {%- set target_subnet_netmask = target_subnet.split('/') %}
          {%- set target_subnet_octets = target_subnet_netmask[0].split('.') %}
            {{ binding[network] }}:
              addresses: [{{ target_subnet_octets[0]}}.{{ target_subnet_octets[1]}}.{{ management_address_octets[2]}}.{{ management_address_octets[3]}}/{{ target_subnet_netmask[1]}}]
              dhcp4: no
        {%- endif %}
      {%- endfor %}
    {%- endfor %}
  {%- else %}
    {%- for binding in pillar[srv][grains['type']]['networks']['bindings'] %}
      {%- for network in binding %}
            {{ binding[network] }}:
              dhcp4: no
      {%- endfor %}
    {%- endfor %}
          bridges: 
    {%- for binding in pillar[srv][grains['type']]['networks']['bindings'] %}
      {%- for network in binding %}
            {{ network }}:
        {%- if network == 'management' %}
              dhcp4: yes
        {%- elif network == 'public' %}
              dhcp4: no
        {%- else %}
          {%- set target_subnet = pillar['subnets'][network] %}
          {%- set target_subnet_netmask = target_subnet.split('/') %}
          {%- set target_subnet_octets = target_subnet_netmask[0].split('.') %}
              dhcp4: no
              addresses: [{{ target_subnet_octets[0]}}.{{ target_subnet_octets[1]}}.{{ management_address_octets[2]}}.{{ management_address_octets[3]}}/{{ target_subnet_netmask[1]}}]
        {%- endif %}
              interfaces:
                - {{ binding[network] }}
      {%- endfor %}
    {%- endfor %}
  {%- endif %}
{%- endif %}

{% else %}
placeholder for ifupdown:
  test.nop
{% endif %}

networking_mine_update:
  module.run:
    - name: mine.update
  event.send:
    - name: {{ grains['type'] }}/mine/address/update
    - data: "{{ grains['type'] }} mine has been updated."

