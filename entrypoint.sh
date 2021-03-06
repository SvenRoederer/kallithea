#!/bin/bash

CFG_FILE=/opt/kallithea/cfg/production.ini
KALLITHEA_VERSION=$(pip3 show kallithea | grep ^Version: | cut -d " " -f 2)
[ -z ${DB_TYPE} ] && DB_TYPE=sqlite

if [ ! -f "${CFG_FILE}" ]
then
    echo "-- creating initial config-file for db-type ${DB_TYPE} --"
    kallithea-cli config-create ${CFG_FILE} host=0.0.0.0 database_engine=${DB_TYPE}
    sed -i "s#^cache_dir = .*#cache_dir = /opt/kallithea/data/cache#g" ${CFG_FILE}
    sed -i "s#^index_dir = .*#index_dir = /opt/kallithea/data/index#g" ${CFG_FILE}
    sed -i "s#^beaker.cache.data_dir = .*#beaker.cache.data_dir = /opt/kallithea/data/breaker-cache/data#g" ${CFG_FILE}
    sed -i "s#^beaker.cache.lock_dir = .*#beaker.cache.lock_dir = /opt/kallithea/data/breaker-cache/lock#g" ${CFG_FILE}
case ${DB_TYPE} in
      sqlite)
        export DB_NAME=/opt/kallithea/data/kallithea.db
        sed -i "s#^sqlalchemy\.url = .*#sqlalchemy.url = sqlite://${DB_NAME}?timeout=60#g" ${CFG_FILE}
        ;;
      postgres)
        sed -i "s#^sqlalchemy\.url = .*#sqlalchemy.url = postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT:-5432}/${DB_NAME}#g" ${CFG_FILE}
        ;;
      mysql)
        sed -i "s#^sqlalchemy\.url = .*#sqlalchemy.url = mysql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT:-3306}/${DB_NAME}#g" ${CFG_FILE}
        { echo "patching db-model for MySQL"; cd /usr/local/lib/python3.7/dist-packages/kallithea; patch -p 1 </opt/kallithea/kallithea060_mysql.patch; }
        ;;
    esac
fi

# setup userid and fix permission for repos
if [ -n ${REPO_UID} ]
then
    echo "-- creating username repos with uid ${REPO_UID} --"
    export REPO_USER=repos
    getent >/dev/null passwd kallithea || adduser \
      --system --no-create-home --disabled-password --disabled-login --ingroup www-data --uid ${REPO_UID} ${REPO_USER}
else
    echo "-- creating default username repos --"
    export REPO_USER=www-data
fi
chown ${REPO_USER} /opt/kallithea/repos

if [ ! -f /opt/kallithea/data/.kallithea_installed ]
then
    echo "-- populating initial database --"
    if [ ${DB_TYPE} = sqlite ] && [ ! -f "${DB_NAME}" ]
    then
        kallithea-cli db-create \
          --user=admin --email=admin@admin.com --password=Administrator \
          --repos=/opt/kallithea/repos --force-yes \
          -c ${CFG_FILE}
    fi
    if [ ${DB_TYPE} = postgres ] || [ ${DB_TYPE} = mysql ]
    then
        kallithea-cli db-create \
          --user=admin --email=admin@admin.com --password=Administrator \
          --repos=/opt/kallithea/repos --force-no \
          -c ${CFG_FILE}
    fi
    echo ${KALLITHEA_VERSION} >/opt/kallithea/data/.kallithea_installed
fi
[ -f /opt/kallithea/stamp_frontend-built ] || { kallithea-cli front-end-build; touch /opt/kallithea/stamp_frontend-built; }

chown www-data:www-data /opt/kallithea/
chown -R www-data:www-data /opt/kallithea/cfg
chmod -R o-rx /opt/kallithea/cfg

# repos and sqlite-db
chown -R ${REPO_USER}:www-data /opt/kallithea/data

# start web-server
gearbox serve -c ${CFG_FILE} --user=${REPO_USER}
