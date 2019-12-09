We gebruiken tegenwoordig de officiële Docker Compose van CKAN zelf om CKAN te deployen.

- `git clone git@github.com:ckan/ckan.git`
- `cd ckan`
- Gebruik de laatste versie van ckan, b.v. `git checkout tags/ckan-2.8.3`
- Kopieer de `docker-compose.yml` uit onze repository over `ckan/contrib/docker/docker-compose.yml`
- Kopieer `.env.template` naar `.env` en edit `.env`:
    - Add `COMPOSE_PROJECT_NAME=osf-dataportaal`
    - Set `CKAN_SITE_URL=https://data.openstate.eu/`
    - Vul onze SMTP gegevens in o.a. `CKAN_SMTP_MAIL_FROM=developers@openstate.eu`
    - Verander de `POSTGRES_PASSWORD`
- Kopieer de `contrib/docker/_data` folder van een oude installatie naar deze nieuwe installatie (de `resources` folder bevat de datasets en de `storage` folder de uploads zoals logo's en er worden dagelijks backups van de `ckan` en `datastore` databases gemaakt)
- `sudo docker-compose up -d`
    - Run `sudo docker-compose ps` en als `osf-dataportaal_ckan_1` niet up is run dan `sudo docker-compose restart ckan` (dit kan gebeuren als de database nog niet klaar was)
- Clean de nieuwe database:
    - `sudo docker exec osf-dataportaal_db_1 psql -U ckan -c 'DROP extension postgis cascade;'`
    - `sudo docker exec osf-dataportaal_ckan_1 /usr/local/bin/ckan-paster --plugin=ckan db clean -c /etc/ckan/production.ini`
- Importeer de databases:
    - Als ze er nog niet staan, kopieer dan de laatste dagelijkse database backup bestanden `latest-ckan-postgresdump-daily.sql.gz` en `latest-datastore-postgresdump-daily.sql.gz` (of dump een nieuwe) vanaf de oude installatie naar `contrib/docker/_data`
    - `gunzip` beide bestanden
    - Laad beide bestanden in Postgres (NB: het inladen van het datastore bestand duurt lang)
        - `sudo docker exec -it osf-dataportaal_ckan_1 psql -U ckan -h db -f /var/lib/ckan/latest-ckan-postgresdump-daily.sql ckan`
            - Vul het Postgres wachtwoord uit `.env` in
        - `sudo docker exec -it osf-dataportaal_ckan_1 psql -U ckan -h db -f /var/lib/ckan/latest-datastore-postgresdump-daily.sql datastore`
            - Vul het Postgres wachtwoord uit `.env` in
- Activeer de datastore en datapusher (gebaseerd op https://docs.ckan.org/en/2.8/maintaining/installing/install-from-docker-compose.html#datastore-and-datapusher):
    - NB: volgens mij is deze command overbodig, mocht het niet werken, run deze command dan wel (verwijder het anders): `sudo docker exec -it osf-dataportaal_db_1 sh /docker-entrypoint-initdb.d/00_create_datastore.sh`
    - Edit het ini-bestand `sudo docker exec -it osf-dataportaal_ckan_1 vim /etc/ckan/production.ini`:
        - Voeg aan de `ckan.plugins` optie `datastore datapusher` toe
        - Uncomment de `ckan.datapusher.formats` optie
- Herindexeer: `sudo docker exec osf-dataportaal_ckan_1 /usr/local/bin/ckan-paster --plugin=ckan search-index rebuild -c /etc/ckan/production.ini`
- Installeer de schema.org/dcat extension
    - `sudo docker exec -it osf-dataportaal_ckan_1 bash`
    - `. /usr/lib/ckan/venv/bin/activate`
    - `pip install -e git+https://github.com/ckan/ckanext-dcat.git#egg=ckanext-dcat`
    - `cd /usr/lib/ckan/venv/src/`
    - `pip install -r ckanext-dcat/requirements.txt`
    - `vim /etc/ckan/production.ini` and add `dcat dcat_json_interface structured_data` to `ckan.plugins`
    - CTRL + D to exit the container
    - `sudo docker restart osf-dataportaal_ckan_1`

Daily backups:
If the `contrib/docker/_data` directory doesn't contain the file `backup.sh`, then copy it there from this repository.
Add the following line to the crontab to create daily backups of the `ckan` and `datastore` databases:
`20 5 * * * (cd /home/projects/ckan/contrib/docker/_data && sudo ./backup.sh)`

Notes:
- Als je geen bestand kan uploaden (test bv. met een kleine plaatje oid), zorg dan dat de `resources` en `storage` folders van `ckan:ckan` zijn:
    - `sudo docker exec -it --user root osf-dataportaal_ckan_1 bash`
    - `cd /var/lib/ckan`
    - `chown -R ckan:ckan resources/`
    - `chown -R ckan:ckan storage/`
