#!/bin/bash

#
# Ensures Solr is running, that a config is uploaded. Then creates a timestamped
# collection and an alias pointing to that collection.
#

###############################################################################
# CONFIG
###############################################################################

pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "meloar.conf" ]]; then
    source "meloar.conf"
fi

: ${SOLR_SCRIPTS:="solrscripts"}

: ${SOLR_CONFIG_FOLDER:="solr7/"}
: ${SOLR_CONFIG_NAME:="meloar_conf_1.1.0"}

: ${PROJECT:="$1"}

usage() {
    echo ""
    echo "Usage: ./prepare_solr.sh <project>"
    exit $1
}

check_parameters() {
    if [[ -z "$PROJECT" ]]; then
        >&2 echo "Error: No project specified"
        usage 2
    fi
    INDEX="${PROJECT}_$(date +"%Y%m%d-%H%M")"
}

################################################################################
# FUNCTIONS
################################################################################

prepare_solr() {
    $SOLRSCRIPTS/cloud_install.sh
    $SOLRSCRIPTS/cloud_start.sh
    $SOLRSCRIPTS/cloud_sync.sh "$SOLR_CONFIG_FOLDER" "$SOLR_CONFIG_NAME" "$INDEX"
    $SOLRSCRIPTS/cloud_alias.sh "$COLLECTION" "$INDEX"
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
prepare_solr
