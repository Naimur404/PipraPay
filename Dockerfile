FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    imagemagick \
    imagemagick-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    curl-dev \
    $PHPIZE_DEPS

# Install PHP extensions (tokenizer, mbstring, curl are already built-in)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo \
        pdo_mysql \
        gd \
        fileinfo \
        zip \
        bcmath \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# Clean up build deps
RUN apk del $PHPIZE_DEPS imagemagick-dev

# Replace the default PHP-FPM pool config so we do not define the same pool twice.
RUN rm -f /usr/local/etc/php-fpm.d/www.conf \
    && { \
        echo '[global]'; \
        echo 'daemonize = no'; \
        echo 'error_log = /proc/self/fd/2'; \
        echo '[www]'; \
        echo 'user = www-data'; \
        echo 'group = www-data'; \
        echo 'listen = /run/php-fpm.sock'; \
        echo 'listen.owner = www-data'; \
        echo 'listen.group = www-data'; \
        echo 'listen.mode = 0660'; \
        echo 'pm = dynamic'; \
        echo 'pm.max_children = 20'; \
        echo 'pm.start_servers = 5'; \
        echo 'pm.min_spare_servers = 3'; \
        echo 'pm.max_spare_servers = 10'; \
        echo 'catch_workers_output = yes'; \
        echo 'clear_env = no'; \
    } > /usr/local/etc/php-fpm.d/www.conf

# PHP settings
RUN { \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 300'; \
    echo 'display_errors = Off'; \
} > /usr/local/etc/php/conf.d/custom.ini

# Copy nginx config
COPY docker/nginx.conf /etc/nginx/http.d/default.conf

# Ensure nginx runs as www-data so it can talk to the PHP-FPM socket.
RUN sed -i 's/^user nginx;/user www-data;/' /etc/nginx/nginx.conf

# Set working directory
WORKDIR /app

# Copy application code
COPY . /app

# Set permissions
RUN chown -R www-data:www-data /app \
    && chmod -R 755 /app \
    && chmod -R 777 /app/pp-content \
    && chmod -R 777 /app/pp-media \
    && mkdir -p /run/nginx /run

# Startup script
COPY docker/start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
