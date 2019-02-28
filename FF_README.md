# Fund og Fortidsminder

This is a condensed guide. See README.md for details on the individual steps.

## One time setup

```
git clone git@github.com:tokee/solrscripts.git
solrscripts/cloud_install.sh
solrscripts/cloud_start.sh
solrscripts/cloud_sync.sh solr7 meloar-conf meloar
```

## Fetch and index FF

Full reset if things goes full wrong
```
rm -r ff
```


Full harvest + enrich
```
USE_RESUMPTION="true" REPOSITORY="https://loar.kb.dk/oai/request" METADATA_PREFIX="xoai" PROJECT="ff" SET="col_1902_333" ./harvest_oai_pmh.sh
PROJECT="ff" ./split_harvest.sh
PROJECT="ff" XSLT="$(pwd)/xoai2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="ff_raw_metadata" RESOURCE_FIELD="loar_resource" RESOURCE_EXT=".xml" ./fetch_resources.sh
PROJECT="ff" XSLT="$(pwd)/ff2solr.xsl" SUB_SOURCE="ff_raw_metadata" SUB_DEST="ff_enrich" ./apply_xslt.sh
PROJECT="ff" SUB_SOURCE="ff_enrich" SUB_DEST="coordinates_converted" ./coordinate_convert.sh
PROJECT="ff" SUB_SOURCE1="solr_base" SUB_SOURCE2="coordinates_converted" SUB_DEST="ff_merged" ./merge_solrdocs.sh
```

Heavy (but needed): Fetch a JSON-breakdown of referenced PDFs, if available
```
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_CHECK_FIELD="loar_resource" RESOURCE_CHECK_EXT=".xml" RESOURCE_FIELD="external_resource" RESOURCE_EXT="" URL_PREFIX="http://teg-desktop.sb.statsbiblioteket.dk:8080/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ./fetch_resources.sh
```

Merge PDF-breakdown + index
```
PROJECT="ff" SUB_SOURCE="ff_merged" SUB_DEST="pdf_enriched" ./pdf_enrich.sh
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar ff/pdf_enriched/*
```


## Notes

Special FF-fields in Solr (`grep -o 'ff_.*' ff2solr.xsl | cut -d\" -f1)):

```
ff_parish_ss
ff_adminarea_municipality_s
ff_adminarea_museum_s
ff_adminarea_supervision_s
ff_place_name_type_s
ff_primaryobject_text_t
ff_primaryobject_year_from_i
ff_primaryobject_year_to_i
ff_primaryobject_mainperiod_s
ff_primaryobject_period_term_s
ff_primaryobject_period_publicterm_s
ff_primaryobject_type_term_s
ff_primaryobject_type_class_term_s
ff_primaryobject_type_class_explanation_s
ff_events_institution_ss
ff_events_text_ts
```
