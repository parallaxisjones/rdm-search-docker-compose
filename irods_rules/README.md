# iRODS rules for creating/updating RDM objects in ElasticSearch

## requirements

- [irods_microservice_plugis_curl](https://github.com/donders-research-data-management/irods_microservice_plugins_curl): iRODS cURL microservices with additional support on `PUT` and `DELETE` operations.

## rules

1. `reindexCollections.r`: rule for reindexing RDM collections

## usage

Reindex collections which are failed in previous indexing operation:

```bash
$ irule -F reindexCollections.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="false"'
``` 

Reindex all collections:

```bash
$ irule -F reindexCollections.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="true"'
``` 

with `<elastic-server>` replaced by the actual Elastic server.
