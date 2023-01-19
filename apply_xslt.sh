#!/bin/bash

#
# Generic XSLT handler
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
: ${XSLT:="$2"}
: ${SUB_SOURCE:="$3"}
: ${SUB_DEST:="$4"}
REQUIREMENTS="xsltproc"

usage() {
    echo ""
    echo "Usage: ./apply_xslt.sh <project> <xslt> <sub_source> <sub_dest>"
    echo ""
    echo "Where <project> is a folder with OAI-PMH-harvested records"
    exit $1
}

check_requirements() {
    for REQ in $REQUIREMENTS; do
        if [[ -z $(which $REQ) ]]; then
            >&2 echo "Error: '$REQ' not available, please install it"
            exit 11
        fi
    done
}

check_parameters() {
    check_requirements
    if [[ "." == ".$PROJECT" ]]; then
        >&2 echo "Error: No project specified"
        usage 3
    fi
    if [[ "." == ".$XSLT" ]]; then
        >&2 echo "Error: No xslt specified"
        usage 7
    fi
    if [[ "." == ".$SUB_SOURCE" ]]; then
        >&2 echo "Error: No sub_source  specified"
        usage 8
    fi
    if [[ "." == ".$SUB_DEST" ]]; then
        >&2 echo "Error: No sub_dest specified"
        usage 9
    fi
    if [[ ! -d "$PROJECT" ]]; then
        >&2 echo "Error: Project folder $PROJECT does not exist"
        usage 4
    fi
    if [[ ! -s "$XSLT" ]]; then
        >&2 echo "Error: XSLT $XSLT could not be accessed"
        usage 4
    fi
    if [[ ! -d "$PROJECT/$SUB_SOURCE" ]]; then
        >&2 echo "Error: No records folder $PROJECT/$SUB_SOURCE"
        usage 5
    fi
}

################################################################################
# FUNCTIONS
################################################################################

convert_records() {
    pushd "$PROJECT" > /dev/null
    mkdir -p "$SUB_DEST"
    cd "$SUB_SOURCE"
    for RECORD in *.xml; do
        if [[ ! -s "$RECORD" ]]; then
            >&2 echo " - Skipping $RECORD as it is empty"
            continue
        fi
        local BASE=${RECORD%.*}
        xsltproc "$XSLT" "$RECORD" | xmllint --format - | grep -v '<[?]xml ' > "../${SUB_DEST}/${BASE}.xml"
    done
    cd "../$SUB_DEST"
    echo "Finished transforming $(find . -iname "*.xml" | wc -l) records to $(pwd)/"
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
convert_records
