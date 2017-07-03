# ElasticSearch Mapping files for RDM objects

- Collection: collection.json
- User: user.json
- Eventlog: eventlog.json

## create index

```bash
$ curl -XPUT http://<elastic-server>:9200/rdm
```

## create mapping for collection

```bash
$ curl -XPUT -H 'Content-Type: application/json' -d @collection.json http://<elastic-server>:9200/rdm/_mapping/collection
```

## create mapping for user 

```bash
$ curl -XPUT -H "Content-Type: application/json" -d @user.json http://<elastic-server>:9200/rdm/_mapping/user
```
