#!/bin/bash

#
# Enrich ff SolrXMLDocuments with external data
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

usage() {
    echo ""
    echo "Usage: ./ff_enrich.sh <project>"
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
        >&2 echo "Error: No records folder $PROJECT/$SUB_SOURCE"
        usage 5
    fi
}

################################################################################
# FUNCTIONS
################################################################################

enrich() {
    echo "Enrich not implemented yet. TODO: Location from separate XML"
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
enrich
