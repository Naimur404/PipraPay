FROM php:8.2-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
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

# Configure PHP-FPM to listen on 127.0.0.1:9000 (already default)
# Increase limits
RUN { \
    echo '[global]'; \
    echo 'daemonize = no'; \
    echo '[www]'; \
    echo 'listen = 127.0.0.1:9000'; \
    echo 'pm = dynamic'; \
    echo 'pm.max_children = 20'; \
    echo 'pm.start_servers = 5'; \
    echo 'pm.min_spare_servers = 3'; \
    echo 'pm.max_spare_servers = 10'; \
} > /usr/local/etc/php-fpm.d/zz-custom.conf

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

# Copy supervisord config
COPY docker/supervisord.conf /etc/supervisord.conf

# Set working directory
WORKDIR /app

# Copy application code
COPY . /app

# Set permissions
RUN chown -R www-data:www-data /app \
    && chmod -R 755 /app \
    && chmod -R 777 /app/pp-content \
    && chmod -R 777 /app/pp-media \
    && mkdir -p /run/nginx

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
