FROM alpine:3.7

RUN apk add --no-cache mysql-client jq && \
mkdir /config && mkdir /backups

ADD backup.sh /backup.sh
ADD run.sh /run.sh
RUN chmod +x /backup.sh && \
chmod +x /run.sh

ENV DB_BACKUP_HOSTS_FILE=/config/backup_hosts.json \
    DB_BACKUP_FOLDER=/backups \
    CRON_TIME="0 0 * * *"

VOLUME /config
VOLUME /backups

CMD ["/run.sh"]
