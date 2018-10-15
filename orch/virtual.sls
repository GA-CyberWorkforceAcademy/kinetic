master_setup:
  salt.state:
    - tgt: 'salt'
    - highstate: true

{% for type in pillar['virtual'] %}
  {% set count = pillar['virtual'][type]['config']['count'] %}
  {% for host in range(count) %}
  {% set identifier = salt.cmd.shell("uuidgen") %}

prepare_vm_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: controller*
    - sls:
      - orch/states/virtual_prep
    - pillar:
        identifier: {{ identifier }}
        type: {{ type }}

wait_for_provisioning:
  salt.wait_for_event:
    - name: salt/auth
    - id_list:
      - {{ type }}-{{ identifier }}
    - timeout: 300

accept_minion:
  salt.wheel:
    - name: key.accept
    - match: {{ type }}-{{ identifier }}
    - require:
      - wait_for_provisioning

wait_for_minion_first_start:
  salt.wait_for_event:
    - name: salt/minion/{{ type }}-{{ identifier }}/start
    - id_list:
      - {{ host }}
    - timeout: 60
    - require:
      - accept_minion

apply_base:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - sls:
      - formulas/common/base
    - require:
      - wait_for_minion_first_start

apply_networking:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - sls:
      - formulas/common/networking
    - require:
      - apply_base

reboot_{{ type }}-{{ identifier }}:
  salt.function:
    - tgt: '{{ host }}'
    - name: system.reboot
    - require:
      - apply_networking

wait_for_reboot:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list:
      - {{ type }}-{{ identifier }}
    - require:
      - reboot_{{ type }}-{{ identifier }}
    - timeout: 300

minion_setup:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - highstate: true
    - require:
      - wait_for_reboot

  {% endfor %}
{% endfor %}
