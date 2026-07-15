#!/bin/sh

LEGO_HOME="/userdata/lego"
CRON_HOME="/userdata/cron"

if [ ! -h "/etc/init.d/S22cron" ]; then
    ln -s "${LEGO_HOME}/init.d/S22cron" "/etc/init.d/S22cron"
fi

if [ ! -h "/etc/init.d/S22renew" ]; then
    ln -s "${LEGO_HOME}/init.d/S30renew" "/etc/init.d/S22renew"
fi

LEGO_RENEW_JOB="0 1 * * 0 $LEGO_HOME/scripts/lego-renew.sh"

CRONTAB="crontab -c '${CRON_HOME}' -e root"

(${CRONTAB} -l 2>/dev/null; echo "$LEGO_RENEW_JOB") | sort -u | crontab -

echo "Lego has been configured. Please reboot to complete setup."
