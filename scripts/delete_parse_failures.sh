#!/bin/bash
if [ "$#" -ne 3 ]; then
    me=`basename "$0"`
    echo "Usage $me <host:port> <date> <days to go back>"
	exit 1
fi

DATE=`date --date=$2`
for i in $(seq 1 $3)
do
   index_date=`date +%Y.%m.%d -d "$DATE $i days ago"`
   #echo `date -d "$index +%Y-%m-%d"`
   index=filebeat-$index_date
      
   echo curl -s -XPOST http://$1/$index/_delete_by_query --data @delete_parse_failures.json
   curl -s -XPOST http://$1/$index/_delete_by_query --data @delete_parse_failures.json
   echo 
   echo curl -s -XPOST http://$1/$index/_forcemerge?only_expunge_deletes=true
   curl -s -XPOST http://$1/$index/_forcemerge?only_expunge_deletes=true
   echo 
   echo 
done