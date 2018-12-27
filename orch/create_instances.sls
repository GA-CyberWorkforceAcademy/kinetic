{% set type = pillar['type'] %}
{% set identifier = salt.cmd.shell("uuidgen") %}

prepare_vm_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: {{ pillar['target'] }}
    - sls:
      - orch/states/virtual_prep
    - pillar:
        identifier: {{ identifier }}
        type: {{ type }}
    - concurrent: true

wait_for_provisioning_{{ type }}-{{ identifier }}:
  salt.wait_for_event:
    - name: salt/auth
    - id_list:
      - {{ type }}-{{ identifier }}
    - timeout: 300

accept_minion_{{ type }}-{{ identifier }}:
  salt.wheel:
    - name: key.accept
    - match: {{ type }}-{{ identifier }}
    - require:
      - wait_for_provisioning_{{ type }}-{{ identifier }}

wait_for_minion_first_start_{{ type }}-{{ identifier }}:
  salt.wait_for_event:
    - name: salt/minion/{{ type }}-{{ identifier }}/start
    - id_list:
      - {{ type }}-{{ identifier }}
    - timeout: 300
    - require:
      - accept_minion_{{ type }}-{{ identifier }}

apply_base_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - sls:
      - formulas/common/base
    - require:
      - wait_for_minion_first_start_{{ type }}-{{ identifier }}

apply_networking_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - sls:
      - formulas/common/networking
    - require:
      - apply_base_{{ type }}-{{ identifier }}

reboot_{{ type }}-{{ identifier }}:
  salt.function:
    - tgt: '{{ type }}-{{ identifier }}'
    - name: system.reboot
    - kwarg:
        at_time: 1
    - require:
      - apply_networking_{{ type }}-{{ identifier }}

wait_for_reboot_{{ type }}-{{ identifier }}:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list:
      - {{ type }}-{{ identifier }}
    - require:
      - reboot_{{ type }}-{{ identifier }}
    - timeout: 300

mine_update_{{ type }}-{{ identifier }}:
  salt.runner:
    - name: mine.update
    - tgt: '{{ type }}-{{ identifier }}'

minion_setup_{{ type }}-{{ identifier }}:
  salt.state:
    - tgt: '{{ type }}-{{ identifier }}'
    - highstate: true
    - failhard: true
    - require:
      - wait_for_reboot_{{ type }}-{{ identifier }}
