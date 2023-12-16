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
cmd_cp		/bin/cp
cmd_rm		/bin/rm
cmd_rsync	/usr/bin/rsync
cmd_ssh		/usr/bin/ssh
ssh_args	-i /ssh-id -o StrictHostKeychecking=no ${BACKUP_SSH_ARGS}
verbose		1
lockfile	/var/run/rsnapshot.pid
retain		alpha	${BACKUP_NUM_VERSIONS}
backup		${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_MEDIAWIKI_PATH}	${BACKUP_NAME}/ ${BACKUP_OPTS}
EOF

# Test config
cat /etc/rsnapshot.conf
rsnapshot configtest

echo ""
echo "Create database backup"
execute_ssh_command "mysqldump -h ${DB_HOSTNAME} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} | gzip -c > ${REMOTE_MEDIAWIKI_PATH}/database_backup.sql.gz" \
     "SSH command to create database backup failed"

echo ""
echo "Downloading files and database backup"
rsnapshot -V alpha
