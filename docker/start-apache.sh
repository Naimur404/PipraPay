#!/bin/sh
set -e

mkdir -p /var/run/apache2 /run/apache2 /var/lock/apache2

exec apache2-foreground