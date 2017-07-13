#!/bin/bash
set -e

if [ -f "/etc/init.d/bt" ];then
    /etc/init.d/bt start
fi
if [ -f " /etc/init.d/nginx" ];then
    /etc/init.d/nginx start
fi
if [ -f "/etc/init.d/pure-ftpd" ];then
    /etc/init.d/pure-ftpd start
fi
if [ -f "/etc/init.d/php-fpm-56" ];then
    /etc/init.d/php-fpm-56 start
fi
if [ -f "/etc/init.d/php-fpm-70" ];then
    /etc/init.d/php-fpm-70 start
fi
if [ -f "/etc/init.d/mysqld" ];then
    /etc/init.d/mysqld start
fi

exec "$@"
