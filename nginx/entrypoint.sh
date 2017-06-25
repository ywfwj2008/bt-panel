#!/bin/bash
set -e

echo "" > /www/server/panel/data/iplist.txt

/etc/init.d/bt start
/etc/init.d/nginx start
/etc/init.d/pure-ftpd start
/etc/init.d/php-fpm-56 start
/etc/init.d/php-fpm-70 start

exec "$@"
