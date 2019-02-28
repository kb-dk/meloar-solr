# Grundtvig

The Grundtvig-data are not (yet) in MeLOAR and the meta-data besides the content itself are currently poor.

# Source

De redigerede filer ligger her:
https://github.com/GVAU/xmlFilesEdit
 
Dette repræsenterer version 1.13 af grundtvigsværker.dk og består af to mapper, ”1804-1825” og ”1826-1871”. Der ligger små 1.700 filer fordelt i disse to mapper.
Der er tale om tekster (*txt.xml) med tilhørende punktkommentarer (*com.xml), indledninger (*intro.xml), tekstredegørelser (*txr.xml) og variantfiler (*v*.xml og *ms*.xml).
 
Alle de uredigerede filer (altså korpus minus de redigerede filer) ligger her:
https://github.com/GVAU/xmlFilesNoEdit

## Format TEI (Text Encoding Initiative)

- https://tei-c.org/
- https://github.com/TEIC/Stylesheets

## How to

Get the material

```
git clone https://github.com/GVAU/xmlFilesNoEdit.git
```

Generate Solr files
```
mkdir -p grundtvig/0_raw
cp xmlFilesNoEdit/*.xml grundtvig/0_raw/
PROJECT=grundtvig SUB_SOURCE="0_raw" SUB_DEST="1_split" ./split_xml.sh
PROJECT="grundtvig" XSLT="$(pwd)/tei2solr.xsl" SUB_SOURCE="1_split" SUB_DEST="2_solr" ./apply_xslt.sh
pushd grundtvig/2_solr/ ; for F in *.xml; do sed -i "s/<doc>/<doc>\n    <field name=\"id\">grundtvig_$F<\\/field>\n    <field name=\"external_resource\">https:\\/\\/github.com\\/GVAU\\/xmlFilesNoEdit\\/blob\\/master\\/$(sed 's/_div[0-9]*//' <<< "${F}")<\\/field>/" $F ; done ; popd 
```

Setup Solr
```
solrscripts/cloud_stop.sh
rm -r cloud/7.3.0/
solrscripts/cloud_install.sh
solrscripts/cloud_start.sh
```

Create collection and index
```
solrscripts/cloud_sync.sh solr7 meloar-conf grundtvig
cloud/7.3.0/solr1/bin/post -p 9595 -c grundtvig grundtvig/2_solr/*
```

## Consider

The repository https://github.com/TEIC/Stylesheets.git holds XSLTs ofr general TEI handling

Some of the Grundtvig-files are messy (< 10%). Dates and titles are sore points, but a few has a fundamental different XML structure

