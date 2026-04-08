FROM php:8.2-apache

# Install system packages needed by the app and PHP extensions.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libmagickwand-dev \
        libzip-dev \
        libpng-dev \
        libjpeg62-turbo-dev \
        libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
        pdo_mysql \
        gd \
        zip \
        bcmath \
    && pecl install imagick \
    && docker-php-ext-enable imagick \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

# PHP settings
RUN { \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'display_errors = Off'; \
} > /usr/local/etc/php/conf.d/custom.ini

# Replace the default Apache site with one that honors the shipped .htaccess rules.
COPY docker/apache.conf /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html

# Copy application code
COPY . /var/www/html

# Ensure the installer can write configuration and media files.
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/pp-content \
    && chmod -R 775 /var/www/html/pp-media \
    && chmod 664 /var/www/html/index.php

EXPOSE 80
