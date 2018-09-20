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

## Harvesting & indexing LOAR data

Fetch data
```
USE_RESUMPTION="true" REPOSITORY="https://dspace-stage.statsbiblioteket.dk/oai/request" METADATA_PREFIX="xoai" PROJECT="ff" SET="com_1902_357" ./harvest_oai_pmh.sh
```

Split into single records
```
PROJECT="ff" ./split_harvest.sh
```

Create basic SolrXMLDocuments for the records
```
PROJECT="ff" XSLT="$(pwd)/xoai2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh
```

Fetch extra XML resources for the records
```
./fetch_external.sh
```

Create representations of the extra XML resources (ff-specific process) and merge them into the basic SolrXMLDocuments
```
PROJECT="ff" XSLT="$(pwd)/ff2solr.xsl" SUB_SOURCE="resources" SUB_DEST="ff_enrich" ./apply_xslt.sh
PROJECT="ff" XSLT="$(pwd)/merge_solrdocs.sh" SUB_SOURCE1="solr_base" SUB_SOURCE2="ff_enrich" DEST="ff_merged" ./merge_solrdocs.sh
```

Enrich the Solr Documents with the content from external PDFs, if available
```
PROJECT="ff" SUB_SOURCE="ff_merged" ./pdf_enrich.sh
```

Index the generated documents into Solr
```
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar ff/pdf_enriched/*
```
