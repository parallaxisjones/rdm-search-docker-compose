#!/bin/sh
ELASTIC_ENDPOINT="http://elasticsearch:9200"

elasticsearch_post_startup() {
  echo Put index templates  
  curl -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/_template/filebeat" -d @/config/indices/templates/filebeat.template.json
  echo Put index mappings
  # curl -s -w "\n" -XDELETE "${ELASTIC_ENDPOINT}/rdm"
  if !(curl -s -f "${ELASTIC_ENDPOINT}/rdm" &> /dev/null); then
    echo Create index rdm
    curl  -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/rdm" -d @/config/indices/rdm/settings.json
  fi
  echo Close index rdm 
  curl -s -w "\n" -XPOST "${ELASTIC_ENDPOINT}/rdm/_close"
  echo Updating analyzers for rdm
  curl -s -w "\n" -XPUT  "${ELASTIC_ENDPOINT}/rdm/_settings" -d @/config/indices/rdm/analyzers.json
  echo Open index rdm
  curl -s -w "\n" -XPOST "${ELASTIC_ENDPOINT}/rdm/_open"
 
  # Create collection version mapping by adding the parent field to the regular collection mapping json
  cp -f /config/indices/rdm/mappings/collection.json /tmp/collection_version.json
  sed -i '1s/.*/{"_parent": {"type": "collection"},/' /tmp/collection_version.json
  echo Put collection version mapping
  curl -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/rdm/_mapping/collection_version" -d @/tmp/collection_version.json
  echo Put collection mapping
  #curl -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/rdm/_mapping/collection_version" -d '{{"_parent": {"type": "collection"}}'
  curl -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/rdm/_mapping/collection" -d @/config/indices/rdm/mappings/collection.json
  echo Put user mapping
  curl -s -w "\n" -XPUT "${ELASTIC_ENDPOINT}/rdm/_mapping/user" -d @/config/indices/rdm/mappings/user.json
}

COUNTER=1
while [ $COUNTER -lt 30 ]; do
  if curl -s ${ELASTIC_ENDPOINT}/_cluster/health | grep -E "yellow|green" &> /dev/null; then    
    elasticsearch_post_startup
	exit 0 &> /dev/null
  else	
    let COUNTER=COUNTER+1
    echo "Waiting for Elastic Search"
	sleep 20
  fi
done 
echo Elastic did not start properly after 20 attempts. No post startup initialization performed.