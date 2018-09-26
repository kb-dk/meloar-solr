#!/bin/bash

#
# read coordinates from SolrXMLDocuments and transforms them to another
# coordinate system
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
: ${SUB_SOURCE:="ff_enrich"}
: ${SUB_DEST:="coordinates_converted"}
: ${SOURCE_COORDINATE_SYSTEM:=""} # If not defined the source coord-system field below must be defined
: ${SOURCE_COORDINATE_SYSTEM_FIELD:="gml_region_s"} # Must be in format EPSG:xxxx where xxxx is the system
: ${SOURCE_COORDINATE_FIELD:="gml_dimensions_s"}
: ${SOURCE_COORDINATE_DELIMITER:=";"}
: ${DESTINATION_COORDINATE_SYSTEM:="4326"} # EPSG:4326 WGS 84. Used by OpenStreetMap & Google et al
: ${DESTINATION_DATUM:="WGS84"}
: ${DESTINATION_FIELD:="place_coordinates"}

: ${EPSGIO:="https://epsg.io"} # Deprecated in favor of cs2cs
: ${MAX_RECORDS:="9999999999"}

usage() {
    echo ""
    echo "Usage: ./coordinate_convert.sh <project>"
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
}

################################################################################
# FUNCTIONS
################################################################################

field_content() {
    local RECORD="$1"
    local FIELD="$2"
    grep "<field name=\"$FIELD\">[^<]\+</field>" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/'
}

convert_single() {
    local RECORD="$1"
    local DEST_FILE="../${SUB_DEST}/$RECORD"
    if [[ -s "$DEST_FILE" ]]; then
        echo "Already converted coordinates for $RECORD"
        return
    fi
    
    local SOURCE_SYSTEM="$SOURCE_COORDINATE_SYSTEM"
    if [[ "." == ".$SOURCE_COORDINATE_SYSTEM" ]]; then
        SOURCE_SYSTEM=$(field_content "$RECORD" "$SOURCE_COORDINATE_SYSTEM_FIELD" | cut -d: -f2)
        if [[ "." == ".$SOURCE_SYSTEM" ]]; then
            >&2 echo "Unable to locate coordinate system in field $SOURCE_COORDINATE_SYSTEM_FIELD for $RECORD"
            cp "$RECORD" "../$SUB_DEST"
            return
        fi
    fi
    SOURCE_COORDINATES=$(field_content "$RECORD" "$SOURCE_COORDINATE_FIELD")
    if [[ "." == ".$SOURCE_COORDINATE_FIELD" ]]; then
        >&2 echo "Unable to locate coordinates in field $SOURCE_COORDINATE_FIELD for $RECORD"
        cp "$RECORD" "../$SUB_DEST"
        return
    fi
    
    local X=$(cut -d$SOURCE_COORDINATE_DELIMITER -f1 <<< "$SOURCE_COORDINATES")
    local Y=$(cut -d$SOURCE_COORDINATE_DELIMITER -f2 <<< "$SOURCE_COORDINATES")
    local CONVERT_URL="${EPSGIO}/trans?x=${X}&y=${Y}&s_srs=${SOURCE_SYSTEM}&t_srs=${DESTINATION_COORDINATE_SYSTEM}"

    # echo "549065 6154006" | cs2cs +init=epsg:25832 +to -f '%.8f'  +init=epsg:4326 +datum=WGS84 -
    # 9.7772986055.52963824 0.00000000
    local CXY=$(echo "$X $Y" | cs2cs +init=epsg:${SOURCE_SYSTEM} +to -f '%.8f'  +init=epsg:${DESTINATION_COORDINATE_SYSTEM} +datum=${DESTINATION_DATUM} -)
    local CX=$(cut -d$'\t' -f1 <<< "$CXY")
    local CY=$(cut -d$'\t' -f2 <<< "$CXY" | cut -d\  -f1)

#    local JSON=$(curl -s "$CONVERT_URL")
#    local CX=$(jq -r .x <<< "$JSON")
#    local CY=$(jq -r .y <<< "$JSON")
    if [[ "." == ".$CX" ]]; then
        >&2 echo "Fatal: Unable to convert coordinates ${X},${Y} for $RECORD with call $CONVERT_URL"
        exit 11
    fi
    echo "Converted ${X},${Y} to ${CX},${CY} for $RECORD"
    cat "$RECORD" | sed -e 's/<\/doc>//' -e 's/<\/add>//' > "$DEST_FILE"
    echo "    <field name=\"${DESTINATION_FIELD}\">${CX},${CY}</field>" >> "$DEST_FILE"
    echo "  </doc>" >> "$DEST_FILE"
    echo "</add>" >> "$DEST_FILE"
}

convert_all() {
    pushd $PROJECT > /dev/null
    mkdir -p ${SUB_DEST}
    cd $SUB_SOURCE
    COUNT=0
    local TOTAL=$(find . -iname "*.xml" | wc -l)
    for RECORD in *.xml; do
        COUNT=$((COUNT+1))
        echo -n "$COUNT/$TOTAL> "
        convert_single "$RECORD"

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
convert_all
