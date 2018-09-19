#!/bin/bash

#
# Enrich SolrXMLDocuments with external PDF with chapters and content
#

# TODO: Add DOC-support (doc->pdf)

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
: ${PDF_TO_CHAPTERS="http://teg-desktop.sb.statsbiblioteket.dk:8080/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url="}
: ${MAX_RECORDS:="99999999"}

usage() {
    echo ""
    echo "Usage: ./pdf_enrich.sh <project>"
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

enrich_single() {
    local T=$(mktemp)
    local RECORD="$1"
    local EXTERNAL="$2"
    local DEST="../pdf_enriched/$RECORD"
    local DEST_BASE="${DEST%.*}"
    
    local R="${PDF_TO_CHAPTERS}${EXTERNAL}"
    curl -s "$R" > "$T"

    if [[ "." == .$(grep '"sections"' "$T") ]]; then
        echo " - Could not PDF-parse $RECORD"
        cp "$RECORD" "$DEST"
        return
    fi

    CHAPTER_COUNT=0
    while IFS=$'\n' read -r CHAPTER
    do
        CHAPTER_COUNT=$(( CHAPTER_COUNT+1 ))
        local DEST="${DEST_BASE}_chapter_${CHAPTER_COUNT}"
        cat "$RECORD" | sed -e 's/\(<field name="id">[^<]\+\)\(<\/field>\)/\1_chapter_'$CHAPTER_COUNT'\2/' -e 's/<\/doc>//' >> "$DEST"
        echo "  <field name=\"chapter\">$(jq .heading <<< "$CHAPTER")</field>" >> "$DEST"
        local PAGE=$(jq .pageNumber <<< "$CHAPTER")
        if [[ "." != ".$PAGE" ]]; then
            echo "  <field name=\"page\">$PAGE</field>" >> "$DEST"
        fi
        
        while IFS=$'\n' read -r LINE
        do
            echo "  <field name=\"content\">$LINE</field>" >> "$DEST"
        done <<< $(jq .text <<< "$CHAPTER" | sed 's/\\n/\n/g')
        echo '<field name="enriched">true</field>' >> "$DEST"
        echo "</doc>" >> "$DEST"
    done <<< $(jq -c '.sections[]' "$T" | jq -c 'select(.text != "")')
    if [[ "$CHAPTER_COUNT" -eq 0 ]]; then
        echo "- No text in $RECORD"
    else
        echo "- Extracted $CHAPTER_COUNT chapters from $RECORD"
    fi
    rm "$T"
}

enrich() {
    pushd $PROJECT > /dev/null
    mkdir -p pdf_enriched
    cd $SUB_SOURCE
    COUNT=0
    for RECORD in *.solrxml; do
        local PDF=$(grep -o "<field name=\"loar_resource\">.*pdf</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/')
        if [[ "." == ".$PDF" ]]; then
            # TODO: Don't skip but make a skeleton record, marked with not having a PDF
            echo "Skipping enrichment og $RECORD as it has no PDF"
            cp "$RECORD" "../pdf_enriched/$RECORD"
            continue
        fi

        local EXTERNAL=$(grep -o "<field name=\"external_resource\">.*</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/')
        if [[ "." == ".$EXTERNAL" ]]; then
            # TODO: Don't skip but make a skeleton record, marked with not having a PDF
            echo "Error: No external resource for $RECORD with PDF, skipping"
            cp "$RECORD" "../pdf_enriched/$RECORD"
            continue
        fi

        COUNT=$((COUNT+1))
        echo "$COUNT> Fetching chapters for external PDF for ${RECORD}: $EXTERNAL"
        enrich_single "$RECORD" "$EXTERNAL"
        if [[ "$COUNT" -eq "$MAX_RECORDS" ]]; then
            break
        fi
    done
    popd > /dev/null
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
enrich
