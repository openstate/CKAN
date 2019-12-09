#!/bin/bash

## Backup Postgres
sudo docker exec osf-dataportaal_db_1 pg_dump -U ckan ckan | gzip > latest-ckan-postgresdump-daily.sql.gz
cp -p latest-ckan-postgresdump-daily.sql.gz `(date +%A)`-ckan-postgresdump-daily.sql.gz

sudo docker exec osf-dataportaal_db_1 pg_dump -U ckan datastore | gzip > latest-datastore-postgresdump-daily.sql.gz
cp -p latest-datastore-postgresdump-daily.sql.gz `(date +%A)`-datastore-postgresdump-daily.sql.gz
