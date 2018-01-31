FROM alpine:3.7

RUN apk add --no-cache mysql-client jq && \
mkdir /data/config -p && mkdir /data/backups

ADD backup.sh /data/backup.sh
ENV DB_BACKUP_HOSTS_FILE=/data/config/backup_hosts.json \
    DB_BACKUP_FOLDER=/data/backups

VOLUME /data/config
VOLUME /data/backups

ENTRYPOINT "./data/backup.sh"
