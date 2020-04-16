# meloar-solr

## Prerequisites

 - bash
 - jq
 - curl
 - cs2cs
 - Java 1.8+

## About

The overall goal for the MeLOAR project is to provide freetext search of publicly available documents (primarily PDFs) in collections without an existing discovery system. [LOAR](https://loar.kb.dk/) is used for preserving data (PDFs, Word documents etc.) as well as metadata from the collections. The discovery interface is available at [KBLabs](https://labs.statsbiblioteket.dk/meloar/fof/).

This repository (`meloar-solr`) contains scripts for 2 purposes:

1. Harvesting of metadata from specific sources for later ingest into LOAR
1. Harvesting of metadata from LOAR for specific collections, transforming them and indexing them into Solr

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


# General LOAR ➝ Solr

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


## Fetching of other sources, using OAI-PMH

If the OAI-PMH source does not support the timestamp based `from`-parameter, only full harvests are possible:
```
USE_RESUMPTION="true" REPOSITORY="http://www.kulturarv.dk/ffrepox/OAIHandler" METADATA_PREFIX="ff" PROJECT="ff_slks" ./harvest_oai_pmh.sh
```
(this fetches 20K records in pages of 250 records)

Results are stored in a folder named from the `PROJECT`-parameter.

## Harvesting & indexing LOAR data (Fund og Fortidsminder)

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

Fetch extra ff-metadata XML resources for the records and transform them
```
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="ff_raw_metadata" RESOURCE_FIELD="loar_resource" RESOURCE_EXT=".xml" ./fetch_resources.sh
PROJECT="ff" XSLT="$(pwd)/ff2solr.xsl" SUB_SOURCE="ff_raw_metadata" SUB_DEST="ff_enrich" ./apply_xslt.sh
```

Convert coordinates to OpenStreetMap/Solr/Google standard WGS 84
```
PROJECT="ff" SUB_SOURCE="ff_enrich" SUB_DEST="coordinates_converted" ./coordinate_convert.sh
```

Merge the extra ff-metadata into the basic SolrXMLDocuments
```
PROJECT="ff" SUB_SOURCE1="solr_base" SUB_SOURCE2="coordinates_converted" SUB_DEST="ff_merged" ./merge_solrdocs.sh
```

Fetch a JSON-breakdown of referenced PDFs, if available
```
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_CHECK_FIELD="loar_resource" RESOURCE_CHECK_EXT=".xml" RESOURCE_FIELD="external_resource" RESOURCE_EXT="" URL_PREFIX="http://teg-desktop.sb.statsbiblioteket.dk:8080/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ./fetch_resources.sh
```

Enrich the merged Solr Documents with the content from external PDFs, if available
```
PROJECT="ff" SUB_SOURCE="ff_merged" SUB_DEST="pdf_enriched" ./pdf_enrich.sh
```

Index the generated documents into Solr
```
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar ff/pdf_enriched/*
```

## Specific projects

### Fund og Fortidsminder

Open Access PDFs detailing Danish archeological findings, originally available at [Fund og fortidsminder](http://www.kulturarv.dk/fundogfortidsminder/). Published using MeLOAR at [MELOAR - Fund &amp; fortidsminder](https://labs.statsbiblioteket.dk/meloar/fof/).

The documents have authoritative geo-coordinates.

Ingested into LOAR without the use of scripts from `meloar-solr`. Data were fetched directly. The project [meloar-transform](https://github.com/statsbiblioteket/meloar-transform) was used to transform the data to a LOAR-friendly format, and they were then ingested by a LOAR administrator.

Indexed into Solr using `ff_full.sh` with corresponding `FF_README.md`.

### Danmarks kirker

Public available PDFs detailing Danish churches, originally available at [Danmarks Kirker](http://danmarkskirker.natmus.dk/). Published using MeLOAR at [MELOAR - Kirker](https://labs.statsbiblioteket.dk/meloar/kirker/).

The documents does not have authoritative metadata, but most of them can be geographically placed from the church names.

Ingested into LOAR with the script `kirker_harvest.sh`. That is *fetched* using the script `kirker_harvest.sh`. The project [meloar-transform](https://github.com/statsbiblioteket/meloar-transform) was used to transform the data to a LOAR-friendly format, and they were then ingested by a LOAR administrator.

Indexed into Solr using `kirker.sh` with corresponding `DANMARKS_KIRKER.md`.

### Grundtvig

*Currently defunct*

Open Access TEI-XML files detailing the work of N. F. S. Grundtvig, original location at GitHub does not exist anymore. Possibly moved to [grundtvig-data](https://github.com/centre-for-humanities-computing/grundtvig-data/tree/master/Data/version110)? Not published under MeLOAR. Does not use LOAR.

Indexed into Solr using `grundtvig.sh` with corresponding `GRUNDTVIG.md`.

### Folkeskole

Open Access documents with regulations and similar regarding Danish public school, original location [AU Library: Skolelove](https://library.au.dk/materialer/saersamlinger/skolelove/). Published using MeLOAR at [MELOAR - Folkeskole](https://labs.statsbiblioteket.dk/meloar/folkeskole/).

Core data delivered as one-time Excel. The project [meloar-transform](https://github.com/statsbiblioteket/meloar-transform) was used to transform the data to a LOAR-friendly format, and they were then ingested by a LOAR administrator.

Document-specific metadata and (sometimes) PDF is available at e.g. [https://library.au.dk/materialer/saersamlinger/skolelove/?tx_lfskolelov_pi1[lawid]=25](https://library.au.dk/materialer/saersamlinger/skolelove/?tx_lfskolelov_pi1[lawid]=25).

Extraction of the descriptions on the pages is handled by the script `folkeskole_harvest.sh`. Note that only some of the documents have a description.


Indexed into Solr using `folkeskole.sh`. No explicit README.

### Partiprogrammer

Open Access scanned political material from [Digitale samlinger - Partiprogrammer](http://www5.kb.dk/pamphlets/dasmaa/2008/feb/partiprogrammer/subject254/da/). Published under MeLOAR at [MELOAR - Partiprogrammer](https://labs.statsbiblioteket.dk/meloar/partiprogrammer/#/), but bypassing LOAR.

The documents originates from images, so OCR is performed. Currently the OCR-step is done by an internal service at the Royal Danish Library.

OCR'ed and indexed into Solr using `partiprogrammer.md`. No explicit README.

