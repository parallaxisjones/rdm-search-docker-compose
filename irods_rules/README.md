# iRODS rules for creating/updating RDM objects in ElasticSearch

## requirements

- [irods_microservice_plugis_curl](https://github.com/donders-research-data-management/irods_microservice_plugins_curl): iRODS cURL microservices with additional support on `PUT` and `DELETE` operations.

- [rdm-irods-rules](https://github.com/donders-research-data-management/rdm-irods-rules): RDM rule set.

## server rules

Server rules are in the file `rdm-elastic.re`.  To install it, simply do

```bash
$ cat rdm-elastic.re >> /etc/irods/rdm.re
```

### repetitive indexing

```bash
$ irule -F indexCollectionsAsync.r
$ irule -F indexUsersAsync.r
```

## client rules
1. `indexCollections.r`: rule for reindexing RDM collections
1. `indexUsers.r`: rule for reindexing RDM users 

### usage: reindex collection

Reindex collections which are failed in previous indexing operation:

```bash
$ irule -F indexCollections.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="false"'
``` 

Reindex all collections:

```bash
$ irule -F indexCollections.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="true"'
``` 

with `<elastic-server>` replaced by the actual Elastic server.

### usage: reindex object 

Reindex users which are failed in previous indexing operation:

```bash
$ irule -F reindexUsers.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="false"'
``` 

Reindex all users:

```bash
$ irule -F reindexUsers.r '*elasticIndexURL="http://<elastic-server>:9200/rdm"' '*full="true"'
``` 

with `<elastic-server>` replaced by the actual Elastic server.
