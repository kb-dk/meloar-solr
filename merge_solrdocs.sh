#!/bin/bash

#
# Merges 2 solr documents into one
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
: ${SUB_SOURCE1:="$2"}
: ${SUB_SOURCE2:="$3"}
: ${SUB_DEST:="$4"}
: ${SUB_DEST:="merged"}

usage() {
    echo ""
    echo "Usage: ./merge_solrdocs.sh <project> <sub_source_1> <sub_source_2> <dest>"
    exit $1
}

check_parameters() {
    if [[ "." == ".$PROJECT" ]]; then
        >&2 echo "Error: No project specified"
        usage 3
    fi
    if [[ "." == ".$SUB_SOURCE1" ]]; then
        >&2 echo "Error: No sub_source_1 specified"
        usage 8
    fi
    if [[ "." == ".$SUB_SOURCE2" ]]; then
        >&2 echo "Error: No sub_source_2 specified"
        usage 9
    fi
    if [[ ! -d "$PROJECT/$SUB_SOURCE1" ]]; then
        >&2 echo "Error: No Solr Document folder $PROJECT/$SUB_SOURCE1"
        usage 5
    fi
    if [[ ! -d "$PROJECT/$SUB_SOURCE2" ]]; then
        >&2 echo "Error: No Solr Document folder $PROJECT/$SUB_SOURCE2"
        usage 6
    fi
}

################################################################################
# FUNCTIONS
################################################################################

merge_record() {
    local RECORD="$1"
    if [[ ! -s "$SUB_SOURCE1/$RECORD" ]]; then
        echo "- Record only available in $SUB_SOURCE2: $RECORD"
        cp "$SUB_SOURCE2/$RECORD" "$SUB_DEST/"
        return
    fi
    if [[ ! -s "$SUB_SOURCE2/$RECORD" ]]; then
        echo "- Record only available in $SUB_SOURCE1: $RECORD"
        cp "$SUB_SOURCE1/$RECORD" "$SUB_DEST/"
        return
    fi
    echo "- Merging record $RECORD"
    sed -e 's/<\/add>//' -e 's/<\/doc>//' "$SUB_SOURCE1/$RECORD" > "$SUB_DEST/$RECORD"
    sed -e 's/<add>//' -e 's/<doc>//' "$SUB_SOURCE2/$RECORD" >> "$SUB_DEST/$RECORD"
}

merge() {
    pushd $PROJECT > /dev/null
    mkdir -p "$SUB_DEST"
    local T=$(mktemp)
    cd $SUB_SOURCE2
    ls *.xml > "$T"
    cd ../$SUB_SOURCE1
    ls *.xml > "$T"
    cd ..

    for RECORD in $(sort "$T" | uniq); do
        merge_record "$RECORD"
    done

    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
merge

