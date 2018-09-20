#!/bin/bash

#
# Fetches external resources defined in SolrXMLDocuments
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
: ${SUB_SOURCE:="solr_base"}
: ${SUB_DEST:="resources"}
: ${RESOURCE_FIELD:="loar_resource"}
: ${RESOURCE_EXT:=".xml"}

usage() {
    echo ""
    echo "Usage: ./fetch_resources.sh <project>"
    echo ""
    echo "Where <project> is a folder with OAI-PMH-harvested records"
    exit $1
}

check_parameters() {
    if [[ "." == ".$PROJECT" ]]; then
        >&2 echo "Error: No project specified"
        usage 3
    fi
    if [[ ! -d "$PROJECT/$SUB_SOURCE" ]]; then
        >&2 echo "Error: No Solr Document folder $PROJECT/$SUB_SOURCE"
        usage 5
    fi
}

################################################################################
# FUNCTIONS
################################################################################

fetch_external() {
    pushd $PROJECT > /dev/null
    mkdir -p "$SUB_DEST"
    cd $SUB_SOURCE
    for RECORD in *.xml; do
        local DEST="../$SUB_DEST/${RECORD}"
        if [[ -s "$DEST" ]]; then
            echo "- Already fetched resource for $RECORD"
            continue
        fi
        local RESOURCE=$(grep "<field name=\"$RESOURCE_FIELD\">[^<]\+${RESOURCE_EXT}</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/')
        if [[ "." == ".$RESOURCE" ]]; then
            echo "- No $RESOURCE_FIELD with extension $RESOURCE_EXT in $RECORD"
            continue
        fi
        if [[ $(wc -l <<< "$RESOURCE") -gt 1 ]]; then
            echo "- Multiple $RESOURCE_FIELD with extension $RESOURCE_EXT in $RECORD - only the first will be fetched"
            echo "$RESOURCE"
            RESOURCE=$(head -n 1 <<< "$RESOURCE")
        fi
        echo "- Fetching resource for $RECORD: $RESOURCE"
        curl -L -s "$RESOURCE" > "$DEST"
    done
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
fetch_external
