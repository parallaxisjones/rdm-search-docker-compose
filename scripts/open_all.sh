#!/bin/bash
if [ $# -ne 1 ]; then
    me=`basename -- "$0"`
    echo "Usage $me <hostname>"
	exit 1
fi
curl -XPOST http://$1:9200/*/_open
