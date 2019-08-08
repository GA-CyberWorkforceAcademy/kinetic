{% set pgs = salt['pillar.get']('cephconf:images_pgs') %}

create_glance_pool:
  local.cmd.run:
    - tgt: 'G@spawning:0 and G@type:cephmon'
    - tgt_type: compound
    - arg:
      - ceph osd pool create images {{ pgs }}
