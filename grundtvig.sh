#!/bin/bash

#
# Download & prepare grundtvig
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
: ${PRIMARY_SOURCE:="https://github.com/GVAU/xmlFilesEdit"}
: ${SECONDARY_SOURCE:="https://github.com/GVAU/xmlFilesNoEdit"}

usage() {
    echo ""
    echo "Usage: ./grundtvig.sh"
    exit $1
}

check_parameters() {
    true
}

################################################################################
# FUNCTIONS
################################################################################

git_fetch() {
    local SOURCE="$1"
    if [[ -d $(basename "$SOURCE") ]]; then
        return
    fi
    git clone "$SOURCE"
}
fetch_data() {
    git_fetch "$PRIMARY_SOURCE"
    git_fetch "$SECONDARY_SOURCE"
}

copy_data() {
    rm -rf grundtvig/0_raw_primary
    mkdir -p grundtvig/0_raw_primary
    cp $(basename "$PRIMARY_SOURCE")/*/*_txt.xml grundtvig/0_raw_primary
    
    rm -rf grundtvig/0_raw_secondary
    mkdir -p grundtvig/0_raw_secondary
    cp $(basename "$SECONDARY_SOURCE")/*.xml grundtvig/0_raw_secondary
}

remove_duplicates() {
    for P in grundtvig/0_raw_primary/*.xml; do
        local SNAME=$(sed 's/_txt.xml/.xml/' <<< $(basename "$P"))
        if [[ -s "grundtvig/0_raw_secondary/$SNAME" ]]; then
            echo "- Removing duplicate $SNAME from secondary source"
            rm "grundtvig/0_raw_secondary/$SNAME"
        fi
    done
    echo " - Removing known problem child grundtvig/0_raw_secondary/1842_477B_noLG.xml"
    rm grundtvig/0_raw_secondary/1842_477B_noLG.xml
}

split_documents() {
    for PRIORITY in primary secondary; do
        PROJECT=grundtvig SUB_SOURCE="0_raw_${PRIORITY}" SUB_DEST="1_split_${PRIORITY}" ./split_xml.sh
    done
}

generate_solr_files() {
    for PRIORITY in primary secondary; do
        PROJECT="grundtvig" XSLT="$(pwd)/tei2solr.xsl" SUB_SOURCE="1_split_${PRIORITY}" SUB_DEST="2_solr_${PRIORITY}" ./apply_xslt.sh
        pushd grundtvig/2_solr_${PRIORITY}/ > /dev/null
        for F in *.xml; do
            if [[ "primary" == "$PRIORITY" ]]; then
                local GITHUB="$PRIMARY_SOURCE/blob/master"
                YEAR=$(grep -o "^[0-9][0-9][0-9][0-9]" <<< "$F")
                if [[ "$YEAR" -le "1825" ]]; then
                    GITHUB="$GITHUB/1804-1825"
                else
                    GITHUB="$GITHUB/1826-1871"
                fi
            else
                local GITHUB="$SECONDARY_SOURCE/blob/master"
            fi
            GITHUB="$GITHUB/$(sed 's/_div[0-9]*//' <<< "${F}")"
            GITHUB=$(sed 's%/%\\/%g' <<< "$GITHUB")
            
            sed -i "s/<doc>/<doc>\n    <field name=\"id\">grundtvig_$F<\\/field>\n    <field name=\"external_resource\">$GITHUB<\\/field>/" $F
            if [[ ! -s "$F" ]]; then
                rm "$F"
            fi
        done
        popd > /dev/null
    done
    
}


###############################################################################
# CODE
###############################################################################

check_parameters "$@"
#fetch_data
#copy_data
#remove_duplicates
#split_documents
generate_solr_files

