#!/bin/bash
if [ $# -ne 2 ]; then
    me=`basename "$0"`
    echo "Usage $me <hostname> <snapshot name>"
	exit 1
fi
curl -XPOST http://$1:9200/_snapshot/rdm_backup/snapshot_$2/_restore