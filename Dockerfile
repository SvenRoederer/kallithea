FROM debian:buster-slim
MAINTAINER Peter Grace <pete.grace@gmail.com>

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install libapache2-mod-wsgi-py3 git mercurial python3-pip npm \
      python3-pastescript python3-sqlalchemy python3-bcrypt python3-mako \
      python3-decorator python3-waitress python3-bleach python3-dulwich \
      python-ldap python3-click python3-alembic \
      python3-psycopg2 python3-mysqldb && \
    apt-get clean
RUN pip3 install \
      mercurial backlash gearbox WebHelpers2 paginate-sqlalchemy paginate ipaddr \
      gearbox TurboGears2 tgext.routes celery beaker
RUN npm install npm@latest -g
RUN pip3 install kallithea==0.6.0
RUN mkdir -p /opt/kallithea/data \
      && mkdir -p /opt/kallithea/repos \
      && mkdir -p /opt/kallithea/cfg

ADD ./entrypoint.sh /entrypoint.sh
ADD ./kallithea060_mysql.patch /opt/kallithea/kallithea060_mysql.patch

CMD ["/entrypoint.sh"]
VOLUME ["/opt/kallithea/repos","/opt/kallithea/data","/opt/kallithea/cfg"]
EXPOSE 5000
