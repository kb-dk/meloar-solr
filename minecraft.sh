#!/bin/bash

#
# Harvest Minecraft maps from LOAR
#
# Bash line for mapping CSV with coordinates to LOAR records (remember to adjust path):
# (head -n 2 minecraft_filelist.csv ; tail -n+3 minecraft_filelist.csv  | while read -r LINE; do echo -n "${LINE}," ; grep "identifier.*doi"  "$(grep -m 1 -l "$(cut -d, -f6,7 <<< "$LINE")" /home/te/projects/meloar-solr/minecraft/records/*.xml)" | sed 's/.*>\(.*\)<.*/\1/' ; done) | tee jorn.csv
# 
#
#
: ${PROJECT:="minecraft"}
: ${REPOSITORY:="https://loar.kb.dk/oai/request"}

usage() {
    echo ""
    echo "Usage: ./minecraft.sh"
    exit $1
}

check_parameters() {
    mkdir -p "$PROJECT"
}

################################################################################
# FUNCTIONS
################################################################################


###############################################################################
# CODE
###############################################################################

check_parameters "$@"

USE_RESUMPTION="true" REPOSITORY="$REPOSITORY" METADATA_PREFIX="oai_dc" PROJECT="$PROJECT" SET="col_1902_8118" ./harvest_oai_pmh.sh
PROJECT="$PROJECT" ./split_harvest.sh
PROJECT="$PROJECT" XSLT="$(pwd)/oai_dc2solr.xsl" SUB_SOURCE="records" SUB_DEST="solr_base" ./apply_xslt.sh
