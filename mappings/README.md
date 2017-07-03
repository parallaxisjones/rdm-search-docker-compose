# ElasticSearch Mapping files for RDM objects

- `mapping.json`: mapping file for the `rdm` index of elastic

## create index

```bash
$ curl -XPUT -d @mapping.json http://<elastic-server>:9200/rdm
```
