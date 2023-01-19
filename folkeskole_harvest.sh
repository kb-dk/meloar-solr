#!/bin/bash

#
# Screen scrapes Folkeskole for a description of the material, producing a txt
# file for each processed folkeskole. These files are intended for ingest into
# loar.kb.dk by an administrator.
#
# The script relies on a list of IDs for documents available at
# https://library.au.dk/materialer/saersamlinger/skolelove/
# The IDs are not secret, but are derived from a CSV svar cannot be shared due
# to copyright legislation. To extract the IDs from the CSV, run
# cut -d$'\t' -f1 skolelove.csv | grep '[0-9]\+' > folkeskole.ids
#

###############################################################################
# CONFIG
###############################################################################

if [[ -s "folkeskole.conf" ]]; then
    source "folkeskole.conf"
fi
pushd ${BASH_SOURCE%/*} > /dev/null
if [[ -s "folkeskole.conf" ]]; then
    source "folkeskole.conf"
fi
: ${PROJECT:="folkeskole"}
: ${DELAY_BETWEEN_REQUESTS:="0"}
: ${FORCE_DOWNLOAD:="false"} # If true, the webpages are fetched even if that were fetched previously

usage() {
    echo ""
    echo "Usage: ./folkeskole_harvest.sh"
    exit $1
}

check_parameters() {
    mkdir -p "$PROJECT/description"
    mkdir -p "$PROJECT/description_raw"
}

################################################################################
# FUNCTIONS
################################################################################

# Download webpages with descriptions.
get_raw_pages() {
    echo "Fecthing raw webpages for $(wc -l < folkeskole.ids) IDs"
    local FIRST=true
    while read -r ID; do
        DEST="$PROJECT/description_raw/${ID}.html"
        if [[ -s "$DEST" ]]; then
            if [[ "true" != "$FORCE_DOWNLOAD" ]]; then
                # echo " - Skipping ID $ID as destination exists: $DEST"
                continue
            fi
            echo " - Deleting previously fetched page for ID $ID as FORCE_DOWNLOAD==true"
        fi
        if [[ "true" == "$FIRST" ]]; then
            FIRST=false
        else
            sleep $DELAY_BETWEEN_REQUESTS
        fi
        echo " - Fetching webpage for ID $ID to $DEST"
        curl -s 'https://library.au.dk/materialer/saersamlinger/skolelove/?tx_lfskolelov_pi1[lawid]='$ID > "$DEST"
    done < folkeskole.ids
}

# Iterate previously downloaded webpages and extract the descriptions.
extract_descriptions() {
    echo "Extracting descriptions from $(find $PROJECT/description_raw -iname "*.html" | wc -l) webpages"
    while read -r ID; do
        SRC="$PROJECT/description_raw/${ID}.html"
        DEST="$PROJECT/description/${ID}.txt"
        if [[ ! -s "$SRC" ]]; then
            echo " - Unable to extract description for ID $ID as source does not exists: $SRC"
            continue
        fi
        cat "$SRC" | sed 's%</p>%</p>\n%g' | grep -m 1 -A 999999 "history.back()" | tail -n+2 | grep -B 999999 "history.back()" | sed 's/<[^>]*>//g' > "$DEST"
    done < folkeskole.ids
}

# Remove files without descriptions and pack it the ones left as a ZIP.
cleanup() {
    find $PROJECT/description/ -size -10b -iname "*.txt" -exec rm "{}" \;
    local ZIP="folkeskole_description_$(date +%Y%m%d).zip"
    if [[ -s "$ZIP" ]]; then
        rm "$ZIP"
    fi
    zip -qr "$ZIP" "$PROJECT/description/"
    echo "$ZIP"
}

###############################################################################
# CODE
###############################################################################

check_parameters "$@"
get_raw_pages
extract_descriptions
ZIP=$(cleanup)

echo "Done. $(find $PROJECT/description/ -iname "*.txt" | wc -l) descriptions in $PROJECT/description/ packed as $ZIP"
