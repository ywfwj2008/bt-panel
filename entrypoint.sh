#!/bin/bash
set -e
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# start run application
if [ -f "/etc/init.d/bt" ];then
    /etc/init.d/bt restart
fi
if [ -f "/etc/init.d/pure-ftpd" ];then
    /etc/init.d/pure-ftpd start
fi
if [ -f "/etc/init.d/php-fpm-52" ];then
    /etc/init.d/php-fpm-52 start
fi
if [ -f "/etc/init.d/php-fpm-53" ];then
    /etc/init.d/php-fpm-53 start
fi
if [ -f "/etc/init.d/php-fpm-54" ];then
    /etc/init.d/php-fpm-54 start
fi
if [ -f "/etc/init.d/php-fpm-55" ];then
    /etc/init.d/php-fpm-55 start
fi
if [ -f "/etc/init.d/php-fpm-56" ];then
    /etc/init.d/php-fpm-56 start
fi
if [ -f "/etc/init.d/php-fpm-70" ];then
    /etc/init.d/php-fpm-70 start
fi
if [ -f "/etc/init.d/php-fpm-71" ];then
    /etc/init.d/php-fpm-71 start
fi
if [ -f "/etc/init.d/php-fpm-72" ];then
    /etc/init.d/php-fpm-72 start
fi
if [ -f "/etc/init.d/nginx" ];then
    /etc/init.d/nginx start
fi
if [ -f "/etc/init.d/httpd" ];then
    /etc/init.d/httpd start
fi
if [ -f "/etc/init.d/redis" ];then
    if [ -f "/var/run/redis_6379.pid" ];then
        unlink /var/run/redis_6379.pid
    fi
    /etc/init.d/redis start
fi
if [ -f "/etc/init.d/memcached" ];then
    /etc/init.d/memcached start
fi
if [ -f "/etc/init.d/mysqld" ];then
    /etc/init.d/mysqld start
fi
if [ -f "/usr/sbin/crond" ];then
    if [ -f "/var/run/crond.pid" ];then
        unlink /var/run/crond.pid
    fi
    /usr/sbin/crond start
fi

exec "$@"
