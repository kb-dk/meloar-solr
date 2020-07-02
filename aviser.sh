#!/bin/bash

#
# Only works internally @ KB and with SSH-keys to the newspapers
#

if [[ -s aviser.conf ]]; then
    . aviser.conf
fi

: ${AREMOTE:="username@server"}
: ${AROOT:="aviser_remote/"}

prepare() {
    local REMOTE="${AREMOTE}:/sbftp-home/infomed2/"
    if [[ $(ls aviser_remote | wc -l) -gt 3 ]]; then
        echo "Already mounted $REMOTE"
    else
        echo "Mounting remote drive $REMOTE"
        mkdir -p aviser_remote
        sshfs $REMOTE aviser_remote
    fi
    mkdir -p aviser
}

# TODO: Split into separate fields on paragraphs
clean() {
    local CONTENT="$1"
    # <bodytext>&lt;p id="p1"&gt;? Katjas mor spørger
    # &lt;p id="p1"&gt;? Katjas mor spørger
    sed -e 's/.*<[^>]*>\([^<]*\)<[^>]*>.*/\1/' -e 's/&lt;p id="p[0-9]*"&gt;/\n/g' -e 's/&lt;\/p&gt;//g' -e 's/&lt;br \/&gt;/\n/g' <<< "$CONTENT"
}

add_date_fields() {
    local SFILE="$1"
    # <publishdate>20110612</publishdate>
    local SFIELD="$1"
    local D=$(grep -m 1 "<$SFIELD>" < "$SFILE" | grep -o "[0-9]*")
    sed 's/\([0-9][0-9][0-9][0-9]\)\([0-9][0-9]\)\([0-9][0-9]\)/<field name="ctime">\1-\2-\3T00:00:00Z<\/field>\n<field name="year">\1<\/year>\n/' <<< "$D"
}    
    
add_field() {
    local SFILE="$1"
    local SFIELD="$2"
    local DFIELD="$3"
    grep "<$SFIELD>" < "$SFILE" | while read -r FCONTENT; do
        echo "<field name=\"$DFIELD\">$(clean "$FCONTENT")</field>"
    done
}

# 20110612_jydskevestkystensoenderborg_article_e2bc77ba.xml
article() {
    local ARTICLE="$1"
    local PNAME="$2"
    local ADOC="$3"
#    echo "   - $(basename $ARTICLE)"

    if [[ ! -s "$ARTICLE" ]]; then
        echo "Skipping empty file: $ARTICLE"
        return
    fi
    
    local AFILE=$(basename "$ARTICLE")
    local ADATE=$(cut -d_ -f1 <<< "$AFILE")

    #    echo "$AFILE $ADATE"
    xmllint --format "$ARTICLE" > t_article.xml

    echo '<doc>' >> "$ADOC"
    echo '<field name="collection">aviser</field>' >> "$ADOC"
    echo "<field name=\"source_xml_s\">$ARTICLE</field>" >> "$ADOC"

    
    add_field t_article.xml filename id >> "$ADOC"
    add_field t_article.xml pagefile external_resource >> "$ADOC"
    add_field t_article.xml pagenumber page >> "$ADOC"
    add_field t_article.xml sectionname chapter >> "$ADOC"
    # Yes, it's a big hack to ask for the value field here
    add_field t_article.xml value keyword >> "$ADOC"
    add_field t_article.xml headline title >> "$ADOC"
    add_field t_article.xml bodytext content >> "$ADOC"
    add_date_fields t_article.xml publishdate >> "$ADOC"

    echo '</doc>' >> "$ADOC"
}

#lemvigfolkeblad
paper() {
    local PFOLDER="$1"
    local PNAME="$2"
    local ADOC="$3"
#    echo -n "."
    echo "  - Paper $PNAME"
    find "${PFOLDER}/articles/" -iname "*.xml" | while read -r ARTICLE; do
        article "$ARTICLE" "$PNAME" "$ADOC"
    done
}

#dl_20110612_rt2
delivery() {
    local AFOLDER="$1"
    local ADOC="$2"
    echo " - Delivery $AFOLDER -> $ADOC"
    
    echo "<add>" > "$ADOC"
    find "$AFOLDER" ! -path "$AFOLDER"  -maxdepth 1 -type d | while read -r PFOLDER; do
        PNAME=$(sed 's%.*/\([^/]\+\)$%\1%' <<< "$PFOLDER")
        paper "$PFOLDER" "$PNAME" "$ADOC"
    done
    echo "</add>" >> "$ADOC"
#    echo ""
}

root_folders() {
    echo "Iterating folders starting from $AROOT"
    IFS=$'\n'
    find $AROOT -maxdepth 2 -iname "dl_[12][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_rt[1-9]*" | while read -r AFOLDER; do
        FNAME=$(sed 's%.*/\([^/]\+\)$%\1%' <<< "$AFOLDER")
        local ADOC="aviser/${FNAME}.xml"
        if [[ ! -s "$ADOC" ]]; then
            # aviser_remote/dl_20120728_rt2 dl_20120728_rt2.xml
            delivery "$AFOLDER" "$ADOC"
        else
            echo " - Already exists: $ADOC"
        fi
    done
}

prepare
root_folders
