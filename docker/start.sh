#!/bin/sh
set -e

# Ensure directories exist
mkdir -p /run/nginx /run

# Start PHP-FPM in background
php-fpm &

# Wait for PHP-FPM socket to be ready
echo "Waiting for PHP-FPM..."
for i in $(seq 1 30); do
    if [ -S /run/php-fpm.sock ]; then
        echo "PHP-FPM is ready."
        break
    fi
    sleep 1
done

if [ ! -S /run/php-fpm.sock ]; then
    echo "ERROR: PHP-FPM socket not found after 30s"
    exit 1
fi

# Start nginx in foreground
echo "Starting nginx..."
exec nginx -g "daemon off;"
