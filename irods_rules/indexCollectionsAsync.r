indexCollectionsAsync {
    delay('<EF>10m REPEAT FOR EVER</EF>') {
        rdmIndexAllCollections(*elasticIndexURL, *full);
    }
}
INPUT *elasticIndexURL=$"http://agaatvlinder.uci.ru.nl:9200/rdm",*full=$'false'
OUTPUT ruleExecOut
