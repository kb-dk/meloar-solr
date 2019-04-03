#!/bin/bash

#
# Screen scrapes Danmarks Kirker and adds geo coordinates
#

###############################################################################
# CONFIG
###############################################################################

if [[ -s "kirke.conf" ]]; then
    source "kirke.conf"
fi
pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "kirke.conf" ]]; then
    source "kirke.conf"
fi
: ${CHURCH_LIST_URL:="http://danmarkskirker.natmus.dk/laes-online/alle-beskrevne-kirker/"}
: ${PROJECT:="kirker"}
: ${OPENSTREETMAP_PROVIDER:="https://nominatim.openstreetmap.org"}

usage() {
    echo ""
    echo "Usage: ./kirker_harvest.sh"
    exit $1
}

check_parameters() {
    mkdir -p "$PROJECT"
    mkdir -p "$PROJECT/geo"
}

################################################################################
# FUNCTIONS
################################################################################

# URL name
get_church_urls() {
    if [[ ! -s "$PROJECT/kirker_urls.dat" ]]; then
        curl "$CHURCH_LIST_URL" | grep -o '<a[^>]\+churchlink[^>]\+>' | sed 's/.*\(http[^"]\+\).*title="\([^"]\+\)".*/\1 \2/' > "$PROJECT/kirker_urls.dat"
    fi
}

qualified_paragraph() {
    local FILE="$1"
    local CLASS="$2"
    grep -o "<p class=\"${CLASS}\">[^<]*</p>" < "$FILE" | sed -e 's/.*<p[^<]*>\([^<]*\)<.*/\1/'
}

add_json() {
    local JSON="$1"
    local KEY="$2"
    local VALUES="$3"
    while read -r VALUE; do
        if [[ "." != ".$VALUE" ]]; then
            JSON="${JSON}, $KEY:\"$VALUE\""
        fi
    done <<< $(sed 's/"/\\"/g' <<< "$VALUES")
    echo "$JSON"
}

add_xml() {
    local XML="$1"
    local KEY="$2"
    local VALUES="$3"
    while read -r VALUE; do
        if [[ "." != ".$VALUE" ]]; then
            XML="${XML}    <field name=\"$KEY\">$VALUE</field>"$'\n'
        fi
    done <<< $(sed 's/"/\\"/g' <<< "$VALUES")
    echo "$XML"
}

resolve_coordinates() {
    local QUERY="$1"
    local QUERY=$(sed -e 's/Skt./Sankt/' -e 's/†//' -e 's/ /+/g' <<< "$QUERY")
    local DEST="$2"
    if [[ ! -s "$DEST" || ".[]" == .$(cat "$DEST") ]]; then
        curl -s "${OPENSTREETMAP_PROVIDER}/search?format=json&q=${QUERY}" > "$DEST"
        if [[ ! -s "$DEST" || ".[]" == .$(cat "$DEST") ]]; then
            >&2 echo "Unable to resolve coordinates with '${OPENSTREETMAP_PROVIDER}/search?format=json&q=${QUERY}'"
            rm -f "$DEST"
            echo -n ""
            return
        fi
    fi
    jq -r '.[0].lon, .[0].lat' < "$DEST" | tr '\n' ',' | sed 's/,$//'
}  

get_single_church_metadata() {
    local CHURCH_URL="$1"
    local CHURCH_BASE=$(sed -e 's%/$%%' -e 's%.*/\([^/]*\)/\([^/]*\)$%\1_\2%' <<< "$CHURCH_URL")
    local CHURCH_RAW="$PROJECT/raw/${CHURCH_BASE}.html"
    local CHURCH_JSON="$PROJECT/json/${CHURCH_BASE}.json"
    local CHURCH_XML="$PROJECT/xml/${CHURCH_BASE}.xml"
    local CHURCH_OSM="$PROJECT/osm/${CHURCH_BASE}.json"

    mkdir -p "$PROJECT/raw"
    mkdir -p "$PROJECT/osm"
   
    # Download HTML
    if [[ ! -s "$CHURCH_RAW" ]]; then
        echo "- Downloading $CHURCH_URL to $CHURCH_RAW"
        curl -s "$CHURCH_URL" > "$CHURCH_RAW"
    fi

    # Extract meta-data
    local PDF=$(grep -o '<a[^>]\+filelink[^>]\+>' < "$CHURCH_RAW" | grep -o 'http[^"]\+')
    local TITLE=$(grep -o '<title>.*</title>' < "$CHURCH_RAW" | sed -e 's/<title>\(.*\)<\/title>/\1/' -e 's/\(.*\) -.*/\1/')

    local HERRED=$(qualified_paragraph "$CHURCH_RAW" "township")
    local AMT=$(qualified_paragraph "$CHURCH_RAW" "county")
    local ADDRESS=$(qualified_paragraph "$CHURCH_RAW" "address")
    local ZIP_CITY=$(qualified_paragraph "$CHURCH_RAW" "zipcity")
    local ZIP_ONLY=$(grep -o "[0-9][0-9][0-9][0-9]" <<< "$ZIP_CITY")
    local COORDINATES=$(resolve_coordinates "${TITLE}, ${ZIP_ONLY}" "$CHURCH_OSM")
    
    if [[ "1" == "2" ]]; then
        #{id:"kirke_soenderjyllands-amt_arrild-kirke", title:"Arrild Kirke", external_resource:"http://danmarkskirker.natmus.dk/uploads/tx_tcchurchsearch/Sjyll_0031-0046.pdf", external_resource:"http://danmarkskirker.natmus.dk/uploads/tx_tcchurchsearch/Sjyll_2613-2652.pdf", external_resource:"http://danmarkskirker.natmus.dk/uploads/tx_tcchurchsearch/Sjyll_1264-1280_01.pdf", place_name:"Hviding Herred", place_name:"Tønder Amt", place_name:"Arnumvej 24, Arrild"}
        mkdir -p "$PROJECT/json"
        local JSON="{id:\"kirke_${CHURCH_BASE}\""
        JSON=$(add_json "$JSON" "title" "$TITLE")
        JSON=$(add_json "$JSON" "external_resource" "$PDF")
        JSON=$(add_json "$JSON" "place_name" "$HERRED")
        JSON=$(add_json "$JSON" "place_name" "$AMT")
        JSON=$(add_json "$JSON" "place_name" "$ADDRESS")
        JSON="${JSON}}"
        echo "$JSON" | tee "$CHURCH_JSON"
    else
        mkdir -p "$PROJECT/xml"
        local XML="<add>"$'\n'"  <doc>"$'\n'
        XML="${XML}    <field name=\"id\">kirke_${CHURCH_BASE}</field>"$'\n'
        XML=$(add_xml "$XML" "title" "$TITLE")$'\n'
        XML=$(add_xml "$XML" "external_resource" "$PDF")$'\n'
        XML=$(add_xml "$XML" "place_name" "$HERRED")$'\n'
        XML=$(add_xml "$XML" "place_name" "$AMT")$'\n'
        XML=$(add_xml "$XML" "place_name" "$ADDRESS")$'\n'
        XML=$(add_xml "$XML" "place_name" "$ZIP_CITY")$'\n'
        XML=$(add_xml "$XML" "place_coordinates" "$COORDINATES")$'\n'
        XML="${XML}  </doc>"$'\n'"</add>"$'\n'
        echo " - Created XML metadata $CHURCH_XML with coordinates $COORDINATES"
        echo "$XML" > "$CHURCH_XML"
    fi
}

get_all_church_metadata() {
    get_church_urls
    while read -r CHURCH_URL; do 
        get_single_church_metadata $(cut -d\  -f1 <<< "$CHURCH_URL")
    done < "$PROJECT/kirker_urls.dat"
}


###############################################################################
# CODE
###############################################################################

check_parameters "$@"
get_all_church_metadata
echo "Screen scraped and geo coordinate enhanced meta data available at $PROJECT/xml/"

#PROJECT="$PROJECT" SUB_SOURCE="xml" SUB_DEST="pdf_json" RESOURCE_FIELD="external_resource" RESOURCE_EXT=".pdf" URL_PREFIX="http://miaplacidus.statsbiblioteket.dk:9831/loarindexer/services/pdfinfo?isAllowed=y&sequence=1&url=" ALLOW_MULTI="true" ./fetch_resources.sh
#PROJECT="$PROJECT" SUB_SOURCE="xml" SUB_PDF_JSON="pdf_json" SUB_DEST="solr_ready" ./pdf_enrich.sh
