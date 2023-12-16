FROM alpine
LABEL maintainer="Max Frei <maxfrei@web.de>"

# Install rsnapshot
RUN apk add --no-cache rsnapshot

ARG USER=appuser

# Set default values for environment variables
ENV BACKUP_NAME=localhost
ENV BACKUP_OPTS=
ENV BACKUP_NUM_VERSIONS=1


# Copy the entrypoint script
ADD entry.sh /entry.sh

# Use a non-root user to run the container
RUN adduser -D ${USER}

# make /etc/rsnapshot.conf available for any user
RUN touch /etc/rsnapshot.conf && \
    chown -R ${USER}:${USER} /etc/rsnapshot.conf && \
    touch /var/run/rsnapshot.pid && \
    chmod 777 /var/run/rsnapshot.pid && \
    chmod 777 /var/run && \
    mkdir /snapshots && \
    chown -R ${USER}:${USER} /snapshots
VOLUME /snapshots

# Set the default user
USER ${USER}

# Run the entrypoint script
ENTRYPOINT ["/entry.sh"]
