#!/bin/bash

#
# Download metadata from kb.dk image collections
#
# http://www.kb.dk/pamphlets/dasmaa/2008/feb/partiprogrammer/subject254/da?itemsPerPage=40&orderBy=notBefore&page=1
#

###############################################################################
# CONFIG
###############################################################################

: ${COLLECTION:="$1"}
: ${PROJECT:="noname"}
: ${SUB_DEST:="kb_meta"}

# Sample value. Should be overwritten
: ${SEARCH_URL_PREFIX:="http://www.kb.dk/cop/syndication/pamphlets/dasmaa/2008/feb/partiprogrammer/subject254"}

: ${PAGE_SIZE:=40}
: ${KB_LANGUAGE:=da}
: ${SEARCH_URL_INFIX:="${KB_LANGUAGE}/?itemsPerPage=$PAGE_SIZE&orderBy=notBefore&"}
: ${MAX_META:="999999999"}

usage() {
    echo ""
    echo "Usage: ./download_kb_image_metadata.sh"
    exit $1
}

check_parameters() {
    if [[ -z "$COLLECTION" ]]; then
        >&2 echo "Error: No COLLECTION specified"
        usage 2
    fi
    mkdir -p "$PROJECT/$SUB_DEST"
}

################################################################################
# FUNCTIONS
################################################################################

download_collection() {
    local PAGE=1
    local HITS="-1"
    while [ $(( (PAGE-1)*PAGE_SIZE )) -lt $MAX_META ]; do
        local URL="${SEARCH_URL_PREFIX}${SEARCH_URL_INFIX}page=${PAGE}"
        T="$PROJECT/$SUB_DEST/page_${PAGE}.xml"
        if [ ! -s "$T" ]; then
            echo "  - Fetching page ${PAGE}: $URL"
            curl -s -m 60 "$URL" | xmllint --format - > $T
        else
            echo " - Browse page $PAGE already fetched"
        fi
        if [ "$HITS" -eq "-1" ]; then
            local HITS=$( grep totalResults < $T | sed 's/.*>\([0-9]*\)<.*/\1/' )
            if [[ -z "$HITS" ]]; then
                >&2 echo "Error: Unable to locate totalResults in $URL"
                exit 3
            fi
            echo " - Total hits: $HITS"
        fi
        if [ $(( PAGE*PAGE_SIZE )) -ge "$HITS" ]; then
            break
        fi
        PAGE=$(( PAGE+1 ))
    done
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"

download_collection
