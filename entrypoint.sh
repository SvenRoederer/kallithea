#!/bin/bash
if [ ! -f "/opt/kallithea/production.ini" ]
then
    kallithea-cli config-create /opt/kallithea/production.ini host=0.0.0.0
fi
if [ ! -f "/opt/kallithea/kallithea.db" ]
then
    kallithea-cli db-create \
      --user=admin --email=admin@admin.com --password=Administrator \
      --repos=/opt/kallithea/repos --force-yes \
      -c /opt/kallithea/production.ini
    kallithea-cli front-end-build
fi
getent >/dev/null passwd kallithea || adduser \
    --system --uid 119 --disabled-password --disabled-login --ingroup www-data kallithea
chown kallithea:www-data /opt/kallithea/
chown kallithea:www-data /opt/kallithea/kallithea.db
#chown -R kallithea:www-data /opt/kallithea/repos
#chown -R kallithea:www-data /opt/kallithea/data

# start web-server
gearbox serve -c /opt/kallithea/production.ini --user=kallithea
