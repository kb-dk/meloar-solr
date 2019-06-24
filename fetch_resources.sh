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
: ${RESOURCE_EXT:=""}
: ${RESOURCE_CHECK_FIELD:=""}
: ${RESOURCE_CHECK_EXT:=""}
: ${URL_PREFIX:=""}
: ${URL_POSTFIX:=""}
: ${TIMEOUT:="600"} # curl timeout in seconds
: ${ALLOW_MULTI:="false"}

: ${OVERWRITE_IF_NO_TEXT:="true"}
: ${NO_TEXT_LIMIT:="10"} # The amount of text that is considered "no text"
: ${BLACKLIST:=""}
: ${RECORD_CALLBACK:=""}

. ./meloar_common.sh

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
    local TOTAL=$(find . -iname "*.xml" | wc -l)
    local COUNT=0
    for RECORD in *.xml; do
        COUNT=$(( COUNT+1 ))

        if [[ "." != ".$BLACKLIST" && "." != .$(grep -f "$BLACKLIST" <<< "$RECORD") ]]; then
            echo "$COUNT/$TOTAL> Skipping blacklisted $RECORD"
            continue
        fi
        
        local DEST=../$SUB_DEST/$(resolve_analyzed_filename_base "$RECORD")
        local EXISTING=""
        if [[ -s "$DEST" ]]; then
            local EXISTING="$DEST"
        elif [[ -s "${DEST}.1" ]]; then
            local EXISTING="${DEST}.1"
        fi
        if [[ -s "$EXISTING" ]]; then
            if [[ "true" == "$OVERWRITE_IF_NO_TEXT" && $(jq -r '.sections[].text' "$EXISTING" | tr -d '\n' | tr -d ' ' | wc -c) -le "$NO_TEXT_LIMIT" ]]; then
                echo "$COUNT/$TOTAL> Overwriting previously fetched resource ${DEST}* for $RECORD as it does not contain any text"
            else
                echo "$COUNT/$TOTAL> Already fetched ${EXISTING}* for $RECORD"
                continue
            fi
        fi

        if [[ . != ."$RECORD_CALLBACK" ]]; then
            $RECORD_CALLBACK "$RECORD"
        fi
        
        if [[ "." != ".$RESOURCE_CHECK_FIELD" ]]; then
            local RESOURCE_CHECK=$(grep "<field name=\"$RESOURCE_CHECK_FIELD\">[^<]\+${RESOURCE_CHECK_EXT}</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/')
            if [[ "." == ".$RESOURCE_CHECK" ]]; then
                echo "$COUNT/$TOTAL> No $RESOURCE_CHECK_FIELD check field with extension $RESOURCE_CHECK_EXT in $RECORD"
                continue
            fi
        fi
        local RESOURCE=$(grep "<field name=\"$RESOURCE_FIELD\">[^<]\+${RESOURCE_EXT}</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/')
        if [[ "." == ".$RESOURCE" ]]; then
            echo "$COUNT/$TOTAL> No $RESOURCE_FIELD field with extension $RESOURCE_EXT in $RECORD"
            continue
        fi

        if [[ "$ALLOW_MULTI" == "false" ]]; then
            if [[ $(wc -l <<< "$RESOURCE") -gt 1 ]]; then
                echo "$COUNT/$TOTAL> Multiple $RESOURCE_FIELD with extension $RESOURCE_EXT in $RECORD - only the first will be fetched"
                echo "$RESOURCE"
                RESOURCE=$(head -n 1 <<< "$RESOURCE")
            fi
            local URL="$URL_PREFIX$RESOURCE$URL_POSTFIX"
            echo "$COUNT/$TOTAL> Fetching resource for $RECORD: $URL"
            curl -m $TIMEOUT -L -s "$URL" > "${DEST}.1"
            if [[ ! -s "${DEST}.1" ]]; then
                >&2 echo "Error: Unable to fetch $URL"
                rm -r "${DEST}.1"
            fi
        else
            local RCOUNT=1
            while read -r RES; do
                local URL="$URL_PREFIX$RES${URL_POSTFIX}"
                local CDEST="${DEST}.$RCOUNT"
                echo "$COUNT/$TOTAL> Fetching resource $CDEST for $RECORD: $URL"
                curl -m $TIMEOUT -L -s "$URL" > "$CDEST"
                if [[ ! -s "$CDEST" ]]; then
                    >&2 echo "Error: Unable to fetch $URL"
                    rm -r "$CDEST"
                fi
                RCOUNT=$((RCOUNT+1))
            done <<< "$RESOURCE"
        fi
    done
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
fetch_external
