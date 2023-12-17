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
EOF

# Write relevant environment variables to the cron file
env_file_path=~/env
echo "REMOTE_USER=${REMOTE_USER}" >> $env_file_path
echo "REMOTE_HOST=${REMOTE_HOST}" >> $env_file_path
echo "REMOTE_MEDIAWIKI_PATH=${REMOTE_MEDIAWIKI_PATH}" >> $env_file_path
echo "DB_USER=${DB_USER}" >> $env_file_path
echo "DB_PASSWORD=${DB_PASSWORD}" >> $env_file_path
echo "DB_NAME=${DB_NAME}" >> $env_file_path
echo "DB_HOSTNAME=${DB_HOSTNAME}" >> $env_file_path
echo "HEALTH_CHECK_URL=${HEALTH_CHECK_URL}" >> $env_file_path

# Dynamic parts - depending on the retain settings
# This will also create the crontab
TEMP_FILE=$(mktemp)

if [ "${BACKUP_HOURLY}" -gt 0 ]
then
    echo "retain	hourly	${BACKUP_HOURLY}">> /etc/rsnapshot.conf
    echo "${CRON_HOURLY} rsnapshot -V hourly" >> "${TEMP_FILE}"
fi
if [ "${BACKUP_DAILY}" -gt 0 ]
then
    echo "retain	daily	${BACKUP_DAILY}">> /etc/rsnapshot.conf
    echo "${CRON_DAILY} rsnapshot -V daily" >> "${TEMP_FILE}"
fi
if [ "${BACKUP_WEEKLY}" -gt 0 ]
then
    echo "retain	weekly	${BACKUP_WEEKLY}">> /etc/rsnapshot.conf
    echo "${CRON_WEEKLY} rsnapshot -V weekly" >> "${TEMP_FILE}"
fi
if [ "${BACKUP_MONTHLY}" -gt 0 ]
then
    echo "retain	monthly	${BACKUP_MONTHLY}">> /etc/rsnapshot.conf
    echo "${CRON_MONTHLY} rsnapshot -V monthly" >> "${TEMP_FILE}"
fi
if [ "${BACKUP_YEARLY}" -gt 0 ]
then
    echo "retain	yearly	${BACKUP_YEARLY}">> /etc/rsnapshot.conf
    echo "${CRON_YEARLY} rsnapshot -V yearly" >> "${TEMP_FILE}"
fi

# Install the crontab from the temporary file
sudo crontab -u $(whoami) "${TEMP_FILE}"

# Test the config
CONFIGTEST=$(rsnapshot configtest)
echo "rsnapshot ${CONFIGTEST}"
if [ "${CONFIGTEST}" = "Syntax OK" ]
then
    # Syntax is OK, run rsnapshot once and start cron
    echo ""
    echo "Running rsnapshot once"
    rsnapshot -V hourly
    echo ""
    echo "Starting cron"
    sudo /usr/sbin/crond -f -d 8
fi


