FROM nginx:latest

# Arguments for user and group IDs, passed from docker-compose.
ARG HOST_UID
ARG HOST_GID

# Update existing user and group to match the host.
# This ensures that Nginx runs with the same permissions as the host user,
# avoiding file access issues with mounted volumes.
RUN usermod -u ${HOST_UID} nginx && \
    groupmod -g ${HOST_GID} nginx

# The rest of the Nginx configuration and setup continues as normal.
