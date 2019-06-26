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
: ${COLLECTION:=""} # If defined, the field collection will be added with this value
: ${SKIP_PAGES:=""} # space separated list of the pages to skip, e.g. "1 2"

. ./meloar_common.sh

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
    SKIP_PAGES_SPACED=" $SKIP_PAGES "
}

################################################################################
# FUNCTIONS
################################################################################

encode() {
    sed -e 's/\&/&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' -e 's/"/\&quot;/g' <<< "$1"
}

produce_solr_documents() {
    # TODO: Isolate external resource based on ANALYZABLE_COUNT
    local CHAPTER_COUNT=0
    echo "<update>" > "$DEST"
    while IFS=$'\n' read -r CHAPTER
    do
        local PAGE=$(jq .pageNumber <<< "$CHAPTER")
        if [[ "." != ".$PAGE" && "." != ".$SKIP_PAGES" ]]; then
            if [[ "." != .$(grep " $PAGE " <<< "$SKIP_PAGES_SPACED") ]]; then
#                >&2 echo " Skipping page $PAGE"
                continue
            fi
        fi
        CHAPTER_COUNT=$(( CHAPTER_COUNT+1 ))
        #local DEST="${DEST_BASE}_chapter_${CHAPTER_COUNT}.xml"
        sans_analyzable_externals "$RECORD" | sed -e 's/\(<field name="id">[^<]\+\)\(<\/field>\)/\1_document_'$ANALYZABLE_COUNT'_chapter_'$CHAPTER_COUNT'\2/' -e 's/<\/doc>//' -e 's/<\/add>//' -e 's/<\/doc>//' -e 's/<\/add>//' >> "$DEST"
        if [[ "." != ".$COLLECTION" ]]; then
            echo "    <field name=\"collection\">$COLLECTION</field>" >> "$DEST"
        fi
        echo "    <field name=\"chapter_id\">$CHAPTER_COUNT</field>" >> "$DEST"
        echo "    <field name=\"chapter_total\">$TOTAL_CHAPTERS</field>" >> "$DEST"
        echo "    <field name=\"chapter\">$(encode $(jq -r .heading <<< "$CHAPTER") )</field>" >> "$DEST"
        echo "    <field name=\"external_resource\">$(encode "$ANALYZABLE" )</field>" >> "$DEST"
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
        done <<< $(encode "$(jq -r .text <<< "$CHAPTER" | tr '\n' ' ')" )
#        done <<< $(encode $(jq -r .text <<< "$CHAPTER" | sed 's/\\n/\n/g') )
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

enrich_single() {
    local RECORD="$1"
    local JSON="$2"
    local ANALYZABLE_COUNT="$3"
    
    local FALLBACK_DEST="../${SUB_DEST}/${RECORD}"
    local DEST="${FALLBACK_DEST%.*}.${ANALYZABLE_COUNT}.xml"

    # We don't check fallback as that would mess up the multi-analyzable-resource handling
    if [[ -s "$DEST" ]]; then
        echo "- Skipping already enriched $RECORD due to existing $DEST"
        return
    fi
    
    if [[ "." == .$(grep '"sections"' "$JSON") ]]; then
        echo " - Could not PDF-parse. Copying as-is $RECORD"
        cp "$RECORD" "$DEST"
        return
    fi

    TOTAL_CHAPTERS=$(jq -c '.sections[]' "$JSON" | jq -c 'select(.text != "")' | wc -l)
    AUTHORS=$(jq -r '.authors' "$JSON")
    if [[ "null" == "$AUTHORS" ]]; then
        AUTHORS=""
    else
        AUTHORS=$(jq -r '.authors[]' "$JSON")
    fi

    produce_solr_documents
}

enrich() {
    pushd $PROJECT > /dev/null
    mkdir -p ${SUB_DEST}
    cd $SUB_SOURCE
    local COUNT=0
    local TOTAL=$(find . -iname "*.xml" | wc -l)
    for RECORD in *.xml; do
        COUNT=$((COUNT+1))
        local ANALYZED_BASE=$(resolve_analyzed_filename_base "$RECORD")
        local ANALYZABLES=$(get_analyzable_externals "$RECORD")

        local FOUND_ONE=false
        local ANALYZABLE_COUNT=1
        for ANALYZABLE in $ANALYZABLES; do
            local ANALYZED_RESULT="../$SUB_PDF_JSON/${ANALYZED_BASE}.${ANALYZABLE_COUNT}"
            if  [[ ! -s "$ANALYZED_RESULT" ]]; then
                >&2 echo "Warning: No analyzed data for $ANALYZABLE referred by $RECORD"
                continue
            fi
            FOUND_ONE=true
            echo -n "$COUNT/$TOTAL #$ANALYZABLE_COUNT> " #Enriching record with chapters from external PDF for ${RECORD}"
            enrich_single "$RECORD" "$ANALYZED_RESULT" $ANALYZABLE_COUNT
            ANALYZABLE_COUNT=$(( ANALYZABLE_COUNT + 1 ))
        done
        
        if [[ "false" == "$FOUND_ONE" ]]; then
            echo "$COUNT> No external analyzables available, copying record directly for ${RECORD}"
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
