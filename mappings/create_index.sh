#!/bin/bash

if [ $# -ne 1 ]; then

    echo "$0 <elasticIndexURL>"
    echo
    echo "example:"
    echo
    echo "$0 http://agaatvlinder.uci.ru.nl:9200/rdm"
    exit 1
fi 

URL_INDEX=$1

echo "DELETE $URL_INDEX ..."
curl -XDELETE $URL_INDEX
echo
echo "PUT $URL_INDEX ..."
curl -XPUT -H "Content-Type: application/json" -d @mapping.json $URL_INDEX
echo
