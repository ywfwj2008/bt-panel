#!/bin/bash
set -e
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# reset memory
Mem=`free -m | awk '/Mem:/{print $2}'`
if [ "$Mem" -le 640 ];then
    MEMORY_LIMIT=64
elif [ "$Mem" -gt 640 -a "$Mem" -le 1280 ];then
    MEMORY_LIMIT=128
elif [ "$Mem" -gt 1280 -a "$Mem" -le 2500 ];then
    MEMORY_LIMIT=192
elif [ "$Mem" -gt 2500 -a "$Mem" -le 3500 ];then
    MEMORY_LIMIT=256
elif [ "$Mem" -gt 3500 -a "$Mem" -le 4500 ];then
    MEMORY_LIMIT=320
elif [ "$Mem" -gt 4500 -a "$Mem" -le 8000 ];then
    MEMORY_LIMIT=384
elif [ "$Mem" -gt 8000 ];then
    MEMORY_LIMIT=448
fi

# start run application
if [ -f "/etc/init.d/bt" ];then
    /etc/init.d/bt start
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
if [ -f "/etc/init.d/php-fpm-72" ];then
    /etc/init.d/nginx start
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

exec "$@"
