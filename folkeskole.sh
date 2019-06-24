#!/bin/bash

#
# Download & prepare folkeskole
#

###############################################################################
# CONFIG
###############################################################################

pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "folkeskole.conf" ]]; then
    source "folkeskole.conf"
fi
: ${PROJECT:="folkeskole"}
: ${REPOSITORY:="https://dspace-stage.statsbiblioteket.dk/oai/request"}

: ${PDF_URL:="http://miaplacidus.statsbiblioteket.dk:9951/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url="}
: ${OCR_URL:="http://miaplacidus.statsbiblioteket.dk:9951/loarindexer/services/ocr/pdf?url="}
: ${BLACKLIST:="$(pwd)/folkeskole.blacklist"}
: ${RECORD_CALLBACK:="$(pwd)/ocr_service.sh"}

usage() {
    echo ""
    echo "Usage: ./folkeskole.sh"
    exit $1
}

check_parameters() {
    true
}
#1902/9068

################################################################################
# FUNCTIONS
################################################################################


###############################################################################
# CODE
###############################################################################

check_parameters "$@"

PROJECT="$PROJECT" USE_RESUMPTION="true" REPOSITORY="$REPOSITORY" METADATA_PREFIX="oai_dc" PROJECT="$PROJECT" SET="com_1902_9068" ./harvest_oai_pmh.sh
PROJECT="$PROJECT" ./split_harvest.sh
PROJECT="$PROJECT" XSLT="$(pwd)/oai_dc2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh

PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" RESOURCE_NAME_FIELD="case" RESOURCE_NAME_PRUNE_REGEXP="folkeskole_" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" URL_PREFIX="$PDF_URL" ALLOW_MULTI="true" ./fetch_resources.sh

PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" URL_PREFIX="$OCR_URL" ALLOW_MULTI="true" OVERWRITE_IF_NO_TEXT="true" BLACKLIST="$BLACKLIST" RECORD_CALLBACK="$RECORD_CALLBACK" ./fetch_resources.sh

PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_PDF_JSON="pdf_json" SUB_DEST="solr_ready" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" COLLECTION="folkeskole" ./pdf_enrich.sh

PROJECT="$PROJECT" ./prepare_solr.sh
source cloud.conf
$CLOUD/$VERSION/solr1/bin/post -p $SOLR_BASE_PORT -c "$PROJECT" $PROJECT/solr_ready/*
