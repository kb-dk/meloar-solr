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
: ${SUB_PDF_JSON:="pdf_json"}
: ${SUB_DEST:="pdf_enriched"}
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
    if [[ ! -d "$PROJECT/$SUB_SOURCE/" ]]; then
        >&2 echo "Error: No records folder $PROJECT/$SUB_SOURCE"
        usage 5
    fi
    if [[ ! -d "$PROJECT/$SUB_PDF_JSON/" ]]; then
        >&2 echo "Error: No PDF_JSON folder $PROJECT/$SUB_PDF_JSON"
        usage 6
    fi
}

################################################################################
# FUNCTIONS
################################################################################

encode() {
    sed -e 's/\&/&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' <<< "$1"
}

enrich_single() {
    local JSON="../$SUB_PDF_JSON/$RECORD"
    local RECORD="$1"
    local EXTERNAL="$2"
    local DEST="../${SUB_DEST}/$RECORD"
    local DEST_BASE="${DEST%.*}"

    if [[ -s "$DEST" || -s "${DEST_BASE}_chapter_1.xml" ]]; then
        echo "- Skipping already enriched $RECORD"
        return
    fi
    
    if [[ "." == .$(grep '"sections"' "$JSON") ]]; then
        echo " - Could not PDF-parse. Copying as-is $RECORD"
        cp "$RECORD" "$DEST"
        return
    fi

    local TOTAL_CHAPTERS=$(jq -c '.sections[]' "$JSON" | jq -c 'select(.text != "")' | wc -l)
    local AUTHORS=$(jq -r '.authors[]' "$JSON")
    CHAPTER_COUNT=0

    echo "<update>" > "$DEST"
    while IFS=$'\n' read -r CHAPTER
    do
        CHAPTER_COUNT=$(( CHAPTER_COUNT+1 ))
#        local DEST="${DEST_BASE}_chapter_${CHAPTER_COUNT}.xml"
        cat "$RECORD" | sed -e 's/\(<field name="id">[^<]\+\)\(<\/field>\)/\1_chapter_'$CHAPTER_COUNT'\2/' -e 's/<\/doc>//' -e 's/<\/add>//' -e 's/<\/doc>//' -e 's/<\/add>//' >> "$DEST"
        echo "    <field name=\"chapter_id\">$CHAPTER_COUNT</field>" >> "$DEST"
        echo "    <field name=\"chapter_total\">$TOTAL_CHAPTERS</field>" >> "$DEST"
        echo "    <field name=\"chapter\">$(encode $(jq -r .heading <<< "$CHAPTER") )</field>" >> "$DEST"
        local PAGE=$(jq .pageNumber <<< "$CHAPTER")
        if [[ "." != ".$PAGE" ]]; then
            echo "    <field name=\"page\">$PAGE</field>" >> "$DEST"
        fi
        IFS=$'\n'
        for AUTHOR in $AUTHORS; do
            echo "    <field name=\"author\">$AUTHOR</field>" >> "$DEST"
        done
    
        while IFS=$'\n' read -r LINE
        do
            echo "    <field name=\"content\">$LINE</field>" >> "$DEST"
        done <<< $(encode $(jq -r .text <<< "$CHAPTER" | sed 's/\\n/\n/g') )
        echo '    <field name="enriched">true</field>' >> "$DEST"
        echo '  </doc>' >> "$DEST"
        echo '</add>' >> "$DEST"
    done <<< $(jq -c '.sections[]' "$JSON" | jq -c 'select(.text != "")')
    echo "</update>" >> "$DEST"
    if [[ "$CHAPTER_COUNT" -eq 0 ]]; then
        echo "- No text in $RECORD"
    else
        echo "- Extracted $CHAPTER_COUNT chapters from $RECORD"
    fi
}

enrich() {
    pushd $PROJECT > /dev/null
    mkdir -p ${SUB_DEST}
    cd $SUB_SOURCE
    COUNT=0
    local TOTAL=$(find . -iname "*.xml" | wc -l)
    for RECORD in *.xml; do
        COUNT=$((COUNT+1))

        if [[ -s "../$SUB_PDF_JSON/$RECORD" ]]; then
            echo -n "$COUNT/$TOTAL> " #Enriching record with chapters from external PDF for ${RECORD}"
            enrich_single "$RECORD"
        else
            echo "$COUNT> No PDF JSON available, copying record directly for ${RECORD}"
            cp "$RECORD" "../$SUB_DEST"
        fi
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
