# meloar-solr

## Search backend for the MeLOAR project

Indexes PDFs referenced in Open Access records from [LOAR](https://loar.kb.dk/) together with LOAR metadata and provides section-oriented search.


## Basic setup

Fetch `solrscripts` for easy setup of Solr:

```
git clone git@github.com:tokee/solrscripts.git
```

Install Solr
```
solrscripts/cloud_install.sh
```

Start Solr
```
solrscripts/cloud_start.sh
```

Upload the MeLOAR configuration and create a collection
```
solrscripts/cloud_sync.sh solr7 meloar-conf meloar
```

An empty collection should now be available at http://localhost:9595/solr/#/meloar/query


## Sample index

Index 2 fake records, each with 3 sections:
```
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar samples/*
```

Inspect by performing a search in http://localhost:9595/solr/#/meloar/query


## Fetching of LOAR data

Fetch all from official LOAR OAI-PMH
```
REPOSITORY="https://loar.kb.dk/oai/request" METADATA_PREFIX="oai_dc" PROJECT="loar_kb" ./harvest_oai_pmh.sh
```
Results are stored in `loar_kb`. To update the harvest, re-run the command; it will continue from last time.


Fetch specific collection from stage LOAR OAI-PMH ("Arkæologiske undersøgelser"). Only available at the Royal Danish Library.
```
REPOSITORY="https://dspace-stage.statsbiblioteket.dk/oai/request" METADATA_PREFIX="oai_dc" PROJECT="loar_stage_kb" SET="com_1902_357" ./harvest_oai_pmh.sh
```


## Fetching of other sources

If the OAI-PMH source does not support the timestamp based `from`-parameter, only full harvests are possible:
```
USE_RESUMPTION="true" REPOSITORY="http://www.kulturarv.dk/ffrepox/OAIHandler" METADATA_PREFIX="ff" PROJECT="ff_slks" ./harvest_oai_pmh.sh
```
(this fetches 20K records in pages of 250 records)

Results are stored in a folder named from the `PROJECT`-parameter.

## Indexing LOAR data

