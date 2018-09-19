#!/bin/bash

#
# Convert xoai records from LOAR into SolrXMLDocuments, intended for later
# indexing into Solr
#

###############################################################################
# CONFIG
###############################################################################

if [[ -s "meloar.conf" ]]; then
    source "meloar.conf"
fi
pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "meloar.conf" ]]; then
    source "meloar.conf"
fi

: ${PROJECT:="$1"}
: ${XSLT:="$(pwd)/xoai2solr.xsl"}

usage() {
    echo ""
    echo "Usage: ./xoai2solr.sh <project>"
    echo ""
    echo "Where <project> is a folder with OAI-PMH-harvested records"
    exit $1
}

check_parameters() {
    if [[ "." == ".$PROJECT" ]]; then
        >&2 echo "Error: No project specified"
        usage 3
    fi
    if [[ ! -d "$PROJECT" ]]; then
        >&2 echo "Error: Folder $PROJECT does not exist"
        usage 4
    fi
    if [[ ! -d "$PROJECT/records" ]]; then
        >&2 echo "Error: No records folder $PROJECT/records"
        >&2 echo "Maybe split_harvest.sh was not executed?"
        usage 5
    fi
}

################################################################################
# FUNCTIONS
################################################################################

convert_records() {
    pushd "$PROJECT" > /dev/null
    mkdir -p solr_base
    cd records
    for RECORD in *.xml; do
        local BASE=${RECORD%.*}
        xsltproc "$XSLT" "$RECORD" | xmllint --format - | grep -v "<\?xml" > "../solr_base/${BASE}.solrxml"
    done
    cd ../solr_base
    echo "Finished producing $(find . -iname "*.solrxml" | wc -l) SolrXMLDocument to $(pwd)/"
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
convert_records
