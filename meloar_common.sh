#!/bin/bash

#
# Shared setup and functions for MeLOAR-scripts
#

###############################################################################
# CONFIG
###############################################################################

# Optional field for resource destination file name resolving
# If blank, the input file name is used
: ${RESOURCE_NAME_FIELD:=""}

# Optional pruning of resource file name. Will be used with sed
: ${RESOURCE_NAME_PRUNE_REGEXP:=""} 

# Grep-expression for extracting analyzable resources
: ${EXTERNAL_ANALYZED_RESOURCE_REGEXP:="<field[^<]*external_resource.*pdf"}

################################################################################
# FUNCTIONS
################################################################################

# Input: Record file
resolve_analyzed_filename_base() {
    local RECORD=$(basename "$1")
    local DEST="$1"
    if [[ "." != ".$RESOURCE_NAME_FIELD" ]]; then
        local DEST=$(grep "<field name=\"$RESOURCE_NAME_FIELD\">[^<]\+</field>" "$RECORD" | head -n 1 | sed 's/.*>\([^<]\+\)<.*/\1/')
    fi
    if [[ "." != ".$RESOURCE_NAME_PRUNE_REGEXP" ]]; then
        local DEST=$(sed "s/$RESOURCE_NAME_PRUNE_REGEXP//" <<< "$DEST")
    fi
    if [[ "." == ".$DEST" ]]; then
        >&2 echo "Error: Could not derive resource filename from field '${RESOURCE_NAME_FIELD}'. Using fallback to record name: ${RECORD}"
        local DEST="${RECORD}"
    fi
    echo "$DEST"
}

# TODO: Merge with RESOURCE_EXT from fetch_resouces
# Input: Record file
get_analyzable_externals() {
    local RECORD="$1"
    grep "$EXTERNAL_ANALYZED_RESOURCE_REGEXP" "$RECORD" | sed 's/.*>\([^<]\+\)<.*/\1/'
}
sans_analyzable_externals() {
    local RECORD="$1"
    grep -v "$EXTERNAL_ANALYZED_RESOURCE_REGEXP" "$RECORD"
}
