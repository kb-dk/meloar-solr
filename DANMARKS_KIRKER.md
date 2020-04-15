# Danmarks Kirker

http://danmarkskirker.natmus.dk/


## Data retrieval of kirker for later ingest into LOAR

A complete list can be found at
http://danmarkskirker.natmus.dk/laes-online/alle-beskrevne-kirker/

Simple extraction can be done with
```
curl 'http://danmarkskirker.natmus.dk/laes-online/alle-beskrevne-kirker/' | | grep -o '<a[^>]\+churchlink[^>]\+>' | sed 's/.*\(http[^"]\+\).*title="\([^"]\+\)".*/\1 \2/' > kirker.dat
```
but a more complete solution is `kirker_harvest.sh` which adds geo coordinates and creates files for easy ingest into [LOAR](http://loar.kb.dk/).
The result of `kirker_harvest.sh` is stored in the folder `kirker/xml/`.

## Harvesting from LOAR and indexing into Solr

The records for Danmarks kirker often refers to two or more PDFs. Such records are split into chapter-based SolrDocument, sharing the same LOAR-id, 
but referring to different PDFs.

Harvesting from LOAR and enhancing with PDF-content is done with `kirker.sh`.

## Resolving missing coordinates

Not all coordinates can be resolved. Check which did not work with

`grep -L place_coordinates kirker/xml/*`
