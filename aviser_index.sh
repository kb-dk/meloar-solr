#!/bin/bash

#
# Index the files from aviser.sh and mark the files that fails.
#

if [[ -s aviser.conf ]]; then
    . aviser.conf
fi

: ${AVISER_NEW:="aviser/new"}
: ${AVISER_FAILED:="aviser/failed"}
: ${AVISER_INDEXED:="aviser/indexed"}

: ${COLLECTION:="aviser"}

mkdir -p "$AVISER_INDEXED"
mkdir -p "$AVISER_FAILED"

index() {
    find "$AVISER_NEW" -iname "*.xml" | while read -r DOC_FILE; do
        REPLY=$(cloud/7.3.0/solr1/bin/post -p 9595 -c aviser $DOC_FILE 2>&1)
        if [[ "." == ".$(grep 'IOException' <<< "$REPLY")" ]]; then
            echo " - $DOC_FILE"
            mv "$DOC_FILE" "$AVISER_INDEXED/"
        else
            echo " -  $DOC_FILE failed, moved to $AVISER_FAILED"
            mv "$DOC_FILE" "$AVISER_FAILED/"
        fi
        echo "$REPLY"
    done
}

index
