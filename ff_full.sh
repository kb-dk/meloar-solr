#!/bin/bash

#
# Harvest, transform, enrich & index of Fund og Fortidsminder from LOAR
# 
USE_RESUMPTION="true" REPOSITORY="https://loar.kb.dk/oai/request" METADATA_PREFIX="xoai" PROJECT="ff" SET="col_1902_333" ./harvest_oai_pmh.sh
#USE_RESUMPTION="true" REPOSITORY="https://dspace-stage.statsbiblioteket.dk/oai/request" METADATA_PREFIX="xoai" PROJECT="ff" SET="com_1902_357" ./harvest_oai_pmh.sh
PROJECT="ff" ./split_harvest.sh
PROJECT="ff" XSLT="$(pwd)/xoai2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="ff_raw_metadata" RESOURCE_FIELD="loar_resource" RESOURCE_EXT=".xml" ./fetch_resources.sh
PROJECT="ff" XSLT="$(pwd)/ff2solr.xsl" SUB_SOURCE="ff_raw_metadata" SUB_DEST="ff_enrich" ./apply_xslt.sh

PROJECT="ff" SUB_SOURCE="ff_enrich" SUB_DEST="coordinates_converted" ./coordinate_convert.sh
PROJECT="ff" SUB_SOURCE1="solr_base" SUB_SOURCE2="coordinates_converted" SUB_DEST="ff_merged" ./merge_solrdocs.sh

#PROJECT="ff" SUB_SOURCE1="solr_base" SUB_SOURCE2="ff_enrich" SUB_DEST="ff_merged" ./merge_solrdocs.sh
#PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_CHECK_FIELD="loar_resource" RESOURCE_CHECK_EXT=".xml" RESOURCE_FIELD="external_resource" RESOURCE_EXT="" URL_PREFIX="http://teg-desktop.sb.statsbiblioteket.dk:8080/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ./fetch_resources.sh
PROJECT="ff" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_CHECK_FIELD="loar_resource" RESOURCE_CHECK_EXT=".xml" RESOURCE_FIELD="external_resource" RESOURCE_EXT="" URL_PREFIX="http://miaplacidus.statsbiblioteket.dk:9831/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ./fetch_resources.sh

PROJECT="ff" SUB_SOURCE="ff_merged" SUB_PDF_JSON="pdf_json" SUB_DEST="pdf_enriched" ./pdf_enrich.sh
./nuke_and_reindex.sh
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar ff/pdf_enriched/*

