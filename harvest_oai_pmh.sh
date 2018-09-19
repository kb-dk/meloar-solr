#!/bin/bash

#
# Trivial OAI-PMH harvester
#
# https://www.openarchives.org/OAI/openarchivesprotocol.html#ListRecords
#
# https://loar.kb.dk/oai/request?verb=ListRecords&metadataPrefix=oai_dc&set=com_1902_157
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

: ${REPOSITORY:="https://loar.kb.dk/oai/request"}
: ${METADATA_PREFIX:="oai_dc"}
: ${PROJECT:="loar_kb"}
: ${PROGRESS_FILE:="$PROJECT/oai-pmh.last"}
: ${SET:=""}

: ${RESTART:="false"}
    
: ${USE_RESUMPTION:="false"} # If  true, only full dumps can be used

check_parameters() {
    mkdir -p "$PROJECT"
}


################################################################################
# FUNCTIONS
################################################################################


store_last() {
    local SOURCE="$1"
    local LAST=$( cat "$SOURCE" | tr '\n' ' ' | grep -o '<record> *<header> *<identifier>[^<]*</identifier> *<datestamp>[^<]*</datestamp>' | sed 's/.*<datestamp>\([^<]*\)<\/datestamp>.*/\1/' | sort | tail -n 1 )
    if [[ "." != ".$LAST" ]]; then
        LAST=$(date -d "$LAST + 1 second" +%Y-%m-%dT%H:%M:%SZ)
        echo "$LAST" > "$PROGRESS_FILE"
    fi
    echo -n "$LAST"
}

is_empty() {
    local SOURCE="$1"
    if [[ "." == .$(grep '<error *code="noRecordsMatch">' "$SOURCE") ]]; then
        echo false
    else
        echo true
    fi
}

get_request_base() {
    local R="${REPOSITORY}?verb=ListRecords&metadataPrefix=$METADATA_PREFIX"
    if [[ "." != ".$SET" ]]; then
        R="${R}&set=${SET}"
    fi
    echo -n "$R"
}

harvest_time() {
    local LAST="dummy"
    while [[ "." != ".$LAST" ]]; do
        local REQUEST=$(get_request_base)
        if [[ ! -s "$PROGRESS_FILE" || "true" == "$RESTART" ]]; then
            local LAST="1000-01-01T00:00:00Z"
            RESTART="false"
        else
            local LAST=$(cat "$PROGRESS_FILE")
        fi
        local REQUEST="${REQUEST}&from=${LAST}"
        local D="$PROJECT/oai-pmh.$(sed 's/://g' <<< "$LAST").xml"
        echo "> $REQUEST"
        curl -s "$REQUEST" > "$D"
        local LAST=$(store_last "$D")
        if [[ "true" == $( is_empty "$D" ) ]]; then
            echo "No more records in repository at this time"
            rm "$D"
            break
        fi
    done
}

# <resumptionToken completeListSize="157" cursor="0">oai_dc/1000-01-01T00:00:00Z///100</resumptionToken>
get_resumption_token() {
    local SOURCE="$1"
    local RT=$(grep -o "<resumptionToken.*</resumptionToken." "$SOURCE")
    if [[ "." == ".$RT" ]]; then
        echo ""
    else
        sed 's/<resumptionToken.*>\([^<]*\)<\/resumptionToken./\1/' <<< "$RT"
    fi
}

harvest_resumption() {
    local PAGE=0
    local RESUMPTION=""
    while [[ ".$RESUMPTION" != "." || $PAGE -eq 0 ]]; do
        local REQUEST="${REPOSITORY}?verb=ListRecords"
        if [[ "." != ".$RESUMPTION" ]]; then
            REQUEST="${REQUEST}&resumptionToken=${RESUMPTION}"
        else
            REQUEST="${REQUEST}&metadataPrefix=$METADATA_PREFIX"
            if [[ "." != ".$SET" ]]; then
                R="${R}&set=${SET}"
            fi
        fi
        PAGE=$(( PAGE+1 ))
        local D="$PROJECT/oai-pmh.page_${PAGE}.xml"
        
        echo "${PAGE}> $REQUEST"
        curl -s "$REQUEST" > "$D"
        local RESUMPTION=$(get_resumption_token "$D")
    done
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
if [[ "true" == "$USE_RESUMPTION" ]]; then
    harvest_resumption
else
    harvest_time
fi
