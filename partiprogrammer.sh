#!/bin/bash

#
# Download & prepare pertiprogrammer from
# http://www.kb.dk/pamphlets/dasmaa/2008/feb/partiprogrammer/subject254/da?itemsPerPage=40&orderBy=notBefore&page=1
#

###############################################################################
# CONFIG
###############################################################################

pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "partiprogrammer.conf" ]]; then
    source "partiprogrammer.conf"
fi
: ${PROJECT:="partiprogrammer"}
: ${SEARCH_URL_PREFIX:="http://www.kb.dk/cop/syndication/pamphlets/dasmaa/2008/feb/partiprogrammer/subject254"}

: ${OCR_URL:="http://miaplacidus.statsbiblioteket.dk:9951/loarindexer/services/ocr/pdf?url="}
: ${BLACKLIST:="$(pwd)/partiprogrammer.blacklist"}
: ${OCR_START:="$(pwd)/ocr_service.sh"}

usage() {
    echo ""
    echo "Usage: ./partiprogrammer.sh"
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

#PROJECT="$PROJECT" COLLECTION="partiprogrammer" SEARCH_URL_PREFIX="$SEARCH_URL_PREFIX" SUB_DEST="kb_meta"  ./download_kb_image_metadata.sh

#PROJECT="$PROJECT" SUB_SOURCE="kb_meta" SUB_DEST="records" BODY_START_REGEXP="<item.*" ELEMENT_START_REGEXP="<item.*" ELEMENT_END_REGEXP="</item>" SKIP_HEADER="true" SKIP_FOOTER="true" ./split_xml.sh

#PROJECT="$PROJECT" XSLT="$(pwd)/kb2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh

PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" URL_PREFIX="$OCR_URL" ALLOW_MULTI="true" RECORD_CALLBACK="$OCR_START" ./fetch_resources.sh

exit


PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" RESOURCE_NAME_FIELD="case" RESOURCE_NAME_PRUNE_REGEXP="folkeskole_" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" URL_PREFIX="$PDF_URL" ALLOW_MULTI="true" ./fetch_resources.sh


PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_PDF_JSON="pdf_json" SUB_DEST="solr_ready" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" COLLECTION="folkeskole" ./pdf_enrich.sh

PROJECT="$PROJECT" ./prepare_solr.sh
source cloud.conf
$CLOUD/$VERSION/solr1/bin/post -p $SOLR_BASE_PORT -c "$PROJECT" $PROJECT/solr_ready/*
