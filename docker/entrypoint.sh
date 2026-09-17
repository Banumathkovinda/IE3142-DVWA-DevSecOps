#!/bin/bash
set -e

# If config.inc.php is missing (e.g. shadowed by a volume mount), generate it from template
if [ ! -f /var/www/html/config/config.inc.php ]; then
    echo "[DVWA Entrypoint] Initializing config.inc.php from template..."
    cp /var/www/html/config/config.inc.php.dist /var/www/html/config/config.inc.php
    chown www-data:www-data /var/www/html/config/config.inc.php 2>/dev/null || true
fi

# Ensure uploads and config directories are writable
chown -R www-data:www-data /var/www/html/hackable/uploads 2>/dev/null || true

# Execute Apache in foreground
exec apache2-foreground "$@"
