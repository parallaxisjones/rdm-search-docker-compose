indexCollections {
    rdmIndexAllCollections(*elasticIndexURL, *full);
}

INPUT *elasticIndexURL=$"http://agaatvlinder.uci.ru.nl:9200/rdm",*full=$'false'
OUTPUT ruleExecOut
