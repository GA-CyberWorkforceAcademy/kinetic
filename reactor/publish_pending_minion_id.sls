{% set type = data['path'].split('/')[5] %}

publish pending id:
  local.mine.send:
    - tgt: 'pxe'
    - arg:
      - minionmanage.populate_{{ type }}
      - /var/www/html/pending_hosts/{{ type }}
