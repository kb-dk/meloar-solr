#!/bin/bash
solrscripts/cloud_stop.sh
rm -r cloud/7.3.0/
solrscripts/cloud_install.sh
solrscripts/cloud_start.sh
solrscripts/cloud_sync.sh solr7 meloar-conf meloar
cloud/7.3.0/solr1/bin/post -p 9595 -c meloar ff/pdf_enriched/*
