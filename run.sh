#!/bin/sh

# Set Cron
if [ -n "${NO_CRON}" ]; then
    echo "NO_CRON set, running once..."
    ./backup.sh
else
    echo "${CRON_TIME} /backup.sh" > /crontab.conf
    crontab  /crontab.conf
    echo "Running cron job. Config: ${CRON_TIME}"
    exec crond -f
fi
