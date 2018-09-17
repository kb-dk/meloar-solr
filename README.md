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

An empty collection should now be available at http://localhost:9000/solr/#/meloar/query


## Sample index

Index 2 fake records, each with 3 sections:
```
solrscripts/cloud/7.3.0/solr1/bin/post -p 9000 -c meloar5 samples/*
```

Inspect by performing a search in http://localhost:9000/solr/#/meloar/query


## Fetching of LOAR data


## Indexing LOAR data

