{% set type = pillar['type'] %}
{% set count = pillar['virtual'][type]['count'] %}

destroy_{{ type }}_domain:
  salt.function:
    - name: cmd.run
    - tgt: 'controller*'
    - arg:
      - virsh list | grep {{ type }} | cut -d" " -f 2 | while read id;do virsh destroy $id;done

wipe_{{ type }}_vms:
  salt.function:
    - name: cmd.run
    - tgt: 'controller*'
    - arg:
      - ls /kvm/vms | grep {{ type }} | while read id;do rm -rf /kvm/vms/$id;done  

delete_{{ type }}_key:
  salt.wheel:
    - name: key.delete
    - match: '{{ type }}*'

get_available_controllers_for_{{ type }}:
  salt.function:
    - name: cmd.run
    - tgt: salt
    - arg:
      - salt-run manage.up tgt_type="grain" tgt="role:controller" | sed 's/^..//' > /tmp/{{ type }}_available_controllers

{% for host in range(count) %}
create_{{ type }}_{{ host }}:
  salt.runner:
    - name: state.orchestrate
    - kwarg:
        mods: orch/create_instances
        pillar:
          type: {{ type }}
          target: __slot__:salt:cmd.run("shuf -n 1 /tmp/{{ type }}_available_controllers")
          spawning: {{ loop.index0 }}
    - parallel: true

sleep_{{ type }}_{{ host }}:
  salt.function:
    - name: cmd.run
    - tgt: 'salt'
    - arg:
      - sleep 1
{% endfor %}
