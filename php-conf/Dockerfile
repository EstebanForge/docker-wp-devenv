FROM wordpress:php8.3-fpm

# Arguments for user and group IDs, passed from docker-compose.
ARG HOST_UID
ARG HOST_GID

# Update existing user and group to match the host.
# This ensures that files created inside the container have the correct ownership on the host.
RUN usermod -u ${HOST_UID} www-data && \
  groupmod -g ${HOST_GID} www-data

# Install dependencies (only what's needed).
RUN apt-get update && apt-get install -y mariadb-client && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy custom PHP INI for MySQLi SSL settings
COPY php-conf/disable-mysql-ssl.ini /usr/local/etc/php/conf.d/disable-mysql-ssl.ini
COPY php-conf/custom.ini /usr/local/etc/php/conf.d/custom.ini

# Copy zz-gem-path.conf to PHP-FPM pool directory
COPY php-conf/zz-gem-path.conf /usr/local/etc/php-fpm.d/zz-gem-path.conf

# Install Ruby, RubyGems, mail gem, and catchmail for Mailpit
RUN apt-get update && apt-get install -y ruby rubygems && rm -rf /var/lib/apt/lists/*
RUN gem install mail
RUN curl -Lso /usr/local/bin/catchmail https://raw.githubusercontent.com/sj26/mailcatcher/main/bin/catchmail \
    && chmod +x /usr/local/bin/catchmail

# Copy and set permissions for catchmail wrapper script
COPY php-conf/catchmail-wrapper.sh /usr/local/bin/catchmail-wrapper.sh
RUN chmod +x /usr/local/bin/catchmail-wrapper.sh

# Install Xdebug
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Set working directory
WORKDIR /var/www/html

# Expose port for Xdebug
EXPOSE 9003
