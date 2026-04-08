#!/bin/sh

# Fix permissions so PHP-FPM can write config files
chmod -R 777 /app 2>/dev/null || true

# Start PHP-FPM in background
php-fpm -D

# Process nginx template: substitute PORT and nginx paths
PORT="${PORT:-80}"
NGINX_CONF="/tmp/nginx.conf"

# Find the Nix store nginx config directory
MIME_DIR=$(find /nix/store -name "mime.types" -path "*/conf/*" 2>/dev/null | head -1 | xargs dirname 2>/dev/null)
if [ -z "$MIME_DIR" ]; then
    MIME_DIR="/etc/nginx"
fi

# Replace template variables
sed -e "s|\${PORT}|$PORT|g" \
    -e "s|\$!{nginx}/conf|$MIME_DIR|g" \
    /app/nginx.template.conf > "$NGINX_CONF"

# Start nginx in foreground
exec nginx -c "$NGINX_CONF" -g 'daemon off;'
