#! /bin/sh

# Entry point for rsnapshot backup
# This will create the config file (using environment variables), and then run rsnapshot

# Function to execute an SSH command and check for errors
execute_ssh_command() {
    local command="$1"
    local error_message="$2"

    ssh -i /ssh-id -o StrictHostKeychecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$command"
    local ssh_exit_status=$?

    if [ $ssh_exit_status -ne 0 ]; then
        echo "Error: $error_message (Exit status: $ssh_exit_status)"
        exit 1
    fi
}

# First part of rsnapshot config
cat > /etc/rsnapshot.conf <<EOF
config_version	1.2
snapshot_root	/snapshots/
no_create_root	1
cmd_cp			/bin/cp
cmd_rm			/bin/rm
cmd_rsync		/usr/bin/rsync
cmd_ssh			/usr/bin/ssh
cmd_preexec		/pre_exec.sh
cmd_postexec	/post_exec.sh
ssh_args		-i /ssh-id -o StrictHostKeychecking=no ${BACKUP_SSH_ARGS}
verbose			1
lockfile		/var/run/rsnapshot.pid
backup			${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_MEDIAWIKI_PATH}	${BACKUP_NAME}/ ${BACKUP_OPTS}
retain			startup	3
EOF

# create empty crontab for root
# empty file, otherwise the cronjobs will be added with every container start.
> /etc/crontabs/root

# Dynamic parts - depending on the retain settings
# This will also create the crontab
if [ "${BACKUP_HOURLY}" -gt 0 ]
then
    echo "retain	hourly	${BACKUP_HOURLY}">> /etc/rsnapshot.conf
    echo "${CRON_HOURLY} rsnapshot hourly" >> /etc/crontabs/root
fi
if [ "${BACKUP_DAILY}" -gt 0 ]
then
    echo "retain	daily	${BACKUP_DAILY}">> /etc/rsnapshot.conf
    echo "${CRON_DAILY} rsnapshot daily" >> /etc/crontabs/root
fi
if [ "${BACKUP_WEEKLY}" -gt 0 ]
then
    echo "retain	weekly	${BACKUP_WEEKLY}">> /etc/rsnapshot.conf
    echo "${CRON_WEEKLY} rsnapshot weekly" >> /etc/crontabs/root
fi
if [ "${BACKUP_MONTHLY}" -gt 0 ]
then
    echo "retain	monthly	${BACKUP_MONTHLY}">> /etc/rsnapshot.conf
    echo "${CRON_MONTHLY} rsnapshot monthly" >> /etc/crontabs/root
fi
if [ "${BACKUP_YEARLY}" -gt 0 ]
then
    echo "retain	yearly	${BACKUP_YEARLY}">> /etc/rsnapshot.conf
    echo "${CRON_YEARLY} rsnapshot yearly" >> /etc/crontabs/root
fi

# Test the config
CONFIGTEST=$(rsnapshot configtest)
echo "rsnapshot ${CONFIGTEST}"
if [ "${CONFIGTEST}" = "Syntax OK" ]
then
    # Syntax is OK, run rsnapshot once and start cron
    echo ""
    echo "Running rsnapshot once"
    rsnapshot startup
    echo ""
    echo "Starting cron"
    /usr/sbin/crond -f
fi


