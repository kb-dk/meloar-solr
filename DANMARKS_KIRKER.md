# Danmarks Kirker

http://danmarkskirker.natmus.dk/


## Data retrieval

A complete list can be found at
http://danmarkskirker.natmus.dk/laes-online/alle-beskrevne-kirker/

Simple extraction can be done with
```
curl 'http://danmarkskirker.natmus.dk/laes-online/alle-beskrevne-kirker/' | | grep -o '<a[^>]\+churchlink[^>]\+>' | sed 's/.*\(http[^"]\+\).*title="\([^"]\+\)".*/\1 \2/' > kirker.dat
```
but a more complete solution is `kirker_harvest.sh` which adds geo coordinates and creates files for easy ingest into http://loar.kb.dk/

## Harvesting from LOAR and indexing in MeLOAR

The records for Danmarks kirker often refers to two or more PDFs. Such records are split into chapter-based SolrDocument, sharing the same LOAR-id, but referring to different PDFs.

Harvesting from LOAR and enhancing with PDF-content is done with `kirker.sh`.
