#! /bin/sh

# This script is executed before rsnapshot is run and creates a database backup.

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

echo ""
echo "Create database backup"
execute_ssh_command "mysqldump -h ${DB_HOSTNAME} -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME} | gzip -c > ${REMOTE_MEDIAWIKI_PATH}/database_backup.sql.gz" \
     "SSH command to create database backup failed"
