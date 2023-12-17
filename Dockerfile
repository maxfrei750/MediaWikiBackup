FROM alpine
LABEL maintainer="Max Frei <maxfrei@web.de>"

# Install rsnapshot
RUN apk add --no-cache rsnapshot tzdata curl sudo

ARG USER=appuser
RUN echo "${USER} ALL=(ALL) NOPASSWD: /usr/sbin/crond, /usr/bin/crontab" >> /etc/sudoers

# Set default values for environment variables
ENV BACKUP_NAME=localhost
ENV BACKUP_OPTS=
ENV BACKUP_HOURLY=3
ENV BACKUP_DAILY=3
ENV BACKUP_WEEKLY=3
ENV BACKUP_MONTHLY=3
ENV BACKUP_YEARLY=3
ENV CRON_HOURLY="0 * * * *"
ENV CRON_DAILY="30 23 * * *"
ENV CRON_WEEKLY="0 23 * * 0"
ENV CRON_MONTHLY="30 22 1 * *"
ENV CRON_YEARLY="0 22 1 1 *"

# Copy the entrypoint script
ADD entry.sh /entry.sh

# Copy the script to create a database backup.
ADD pre_exec.sh /pre_exec.sh
ADD post_exec.sh /post_exec.sh

# Use a non-root user to run the container
RUN adduser -D ${USER}

# make /etc/rsnapshot.conf available for any user
RUN touch /etc/rsnapshot.conf && \
    chmod 777 /etc/rsnapshot.conf  && \
    touch /var/run/rsnapshot.pid && \
    chmod 777 /var/run/rsnapshot.pid && \
    chmod 777 /var/run && \
    mkdir /snapshots && \
    chown -R ${USER}:${USER} /snapshots && \
    chmod 777 /snapshots && \
    touch var/spool/cron/crontabs/${USER} && \
    chown ${USER}:${USER} /var/spool/cron/crontabs/${USER} && \
    chmod 777 /var/spool/cron/crontabs/${USER}
VOLUME /snapshots

# Set the default user
USER ${USER}

# Run the entrypoint script
ENTRYPOINT ["/entry.sh"]
