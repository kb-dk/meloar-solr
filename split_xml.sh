#!/bin/bash

#
# Takes an XML with header, X body-elements and footer and creates X documents
# with header, body-element and footer.
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
: ${SUB_SOURCE:="$3"}
: ${SUB_DEST:="$4"}

: ${ELEMENT_START_REGEXP:="<div.*"}
: ${ELEMENT_END_REGEXP:="</div>"}
: ${BODY_START_REGEXP:="<body.*"}

usage() {
    echo "Usage: ./split_xml.sh <project>"
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
        usage 2
    fi
    if [[ ! -d "$PROJECT/$SUB_SOURCE" ]]; then
        >&2 echo "Error: Data source folder $PROJECT/$SUB_SOURCE does not exist"
        usage 4
    fi
    if [[ "." == ".$SUB_DEST" ]]; then
        >&2 echo "Error: No SUB_DEST specified"
        usage 5
    fi
    mkdir -p "$PROJECT/$SUB_DEST"
    
}

################################################################################
# FUNCTIONS
################################################################################

split_xml() {
    pushd "$PROJECT" > /dev/null
    local HEADER=$(mktemp)
    local FOOTER=$(mktemp)
    local BODY=$(mktemp)

    # Source files
    while read -r FILE; do
        grep -m 1 -B 99999 "$BODY_START_REGEXP" $FILE | head -n -1 > $HEADER
        grep -A 99999 "$BODY_START_REGEXP" $FILE | grep -B 9999 "$ELEMENT_END_REGEXP" > $BODY
        
        (cat $FILE ; echo "" )| tac | grep -m 1 -B 9999 "$ELEMENT_END_REGEXP" | tac | tail -n +2 > $FOOTER

        mkdir -p temp_split
        csplit -s --prefix temp_split/ -n 5 $BODY "/$ELEMENT_START_REGEXP/" "{*}"
        cat temp_split/00000 >> $HEADER
        rm temp_split/00000
        
        local DEST_BASE=$(basename $FILE)
        local DEST_BASE="${DEST_BASE%%.*}"

        # Source parts
        COUNTER=1
        while read PART; do
            local DEST_FILE="${SUB_DEST}/${DEST_BASE}_div${COUNTER}.xml"
            cat $HEADER > "$DEST_FILE"
            grep -B 9999 "$ELEMENT_END_REGEXP" $PART >> "$DEST_FILE"
            cat $FOOTER >> "$DEST_FILE"
            COUNTER=$((COUNTER+1))
        done <<< $(ls temp_split/*)
        echo "- $DEST_FILE ($((COUNTER-1)) divs)"
        rm -r temp_split
#    done <<< $(echo 0_raw/1842_477B_noLG.xml)
    done <<< $(find $SUB_SOURCE -type f)

    rm $HEADER $FOOTER
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
split_xml
