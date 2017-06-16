#!/bin/sh  
elasticsearch_post_startup() {
  echo Initializing
  curl -XPUT "http://elasticsearch:9200/_template/filebeat" -d @/config/indices/templates/filebeat.template.json
}

COUNTER=1
while [ $COUNTER -lt 30 ]; do
  if curl -s elasticsearch:9200/_cluster/health | grep -E "yellow|green" &> /dev/null; then    
    elasticsearch_post_startup
	exit 0 &> /dev/null
  else	
    let COUNTER=COUNTER+1
    echo "Waiting for Elastic Search"
	sleep 20
  fi
done 
echo Elastic did not start properly after 20 attempts. No post startup initialization performed.