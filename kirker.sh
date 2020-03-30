#!/bin/bash

#
# Harvest Danmarks Kirker from LOAR, enhance with PDF content and prepare for
# Solr indexing
#

# TODO: Index extra PDFs
# TODO: Add collection generally

###############################################################################
# CONFIG
###############################################################################

if [[ -s "kirke.conf" ]]; then
    source "kirke.conf"
fi
pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "kirke.conf" ]]; then
    source "kirke.conf"
fi
: ${PROJECT:="kirker"}
#: ${REPOSITORY:="https://loar.kb.dk/oai/request"}
#: ${REPOSITORY:="https://dspace-stage.statsbiblioteket.dk/oai/request"}
: ${REPOSITORY:="https://loar.kb.dk/oai/request"}
: ${LOAR_SET:="col_1902_4298"}
: ${LOAR_PREFIX:="oai_dc"}

usage() {
    echo ""
    echo "Usage: ./kirker.sh"
    exit $1
}

check_parameters() {
    mkdir -p "$PROJECT"
}

################################################################################
# FUNCTIONS
################################################################################


###############################################################################
# CODE
###############################################################################

check_parameters "$@"

USE_RESUMPTION="true" REPOSITORY="$REPOSITORY" METADATA_PREFIX="$LOAR_PREFIX" PROJECT="$PROJECT" SET="$LOAR_SET" ./harvest_oai_pmh.sh
PROJECT="$PROJECT" ./split_harvest.sh
PROJECT="$PROJECT" XSLT="$(pwd)/oai_dc2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh

PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" RESOURCE_NAME_FIELD="case" RESOURCE_NAME_PRUNE_REGEXP="kirke_" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" URL_PREFIX="http://miaplacidus.statsbiblioteket.dk:9831/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ALLOW_MULTI="true" ./fetch_resources.sh
PROJECT="$PROJECT" SUB_SOURCE="solr_base" SUB_PDF_JSON="pdf_json" SUB_DEST="solr_ready" RESOURCE_NAME_FIELD="case" RESOURCE_NAME_PRUNE_REGEXP="kirke_" EXTERNAL_ANALYZED_RESOURCE_REGEXP="<field[^<]*external_resource.*pdf" COLLECTION="kirker" ./pdf_enrich.sh

#solrscripts/cloud_stop.sh
#rm -r cloud/7.3.0/
#solrscripts/cloud_install.sh
#solrscripts/cloud_start.sh
#solrscripts/cloud_sync.sh solr7 meloar-conf kirker

cloud/7.3.0/solr1/bin/post -p 9595 -c kirker1 kirker/solr_ready/*
