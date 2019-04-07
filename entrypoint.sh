#!/bin/bash
set -e
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# reset memory
Mem=`free -m | awk '/Mem:/{print $2}'`
if [ $Mem -le 640 ]; then
  Memory_limit=64
elif [ $Mem -gt 640 -a $Mem -le 1280 ]; then
  Memory_limit=128
elif [ $Mem -gt 1280 -a $Mem -le 2500 ]; then
  Memory_limit=192
elif [ $Mem -gt 2500 -a $Mem -le 3500 ]; then
  Memory_limit=256
elif [ $Mem -gt 3500 -a $Mem -le 4500 ]; then
  Memory_limit=320
elif [ $Mem -gt 4500 -a $Mem -le 8000 ]; then
  Memory_limit=384
elif [ $Mem -gt 8000 ]; then
  Memory_limit=448
fi

sed -i '/session    required   pam_loginuid.so/c\#session    required   pam_loginuid.so' /etc/pam.d/crond
sed -i "s@^memory_limit.*@memory_limit = ${Memory_limit}M@" ${PHP_70_PATH}/etc/php.ini
sed -i "s@^opcache.memory_consumption.*@opcache.memory_consumption=${Memory_limit}@" ${PHP_70_PATH}/etc/php.ini
if [ $Mem -le 3000 ]; then
  sed -i "s@^pm.max_children.*@pm.max_children = $(($Mem/3/20))@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.start_servers.*@pm.start_servers = $(($Mem/3/30))@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = $(($Mem/3/40))@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = $(($Mem/3/20))@" ${PHP_70_PATH}/etc/php-fpm.conf
elif [ $Mem -gt 3000 -a $Mem -le 4500 ]; then
  sed -i "s@^pm.max_children.*@pm.max_children = 50@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.start_servers.*@pm.start_servers = 30@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 20@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 50@" ${PHP_70_PATH}/etc/php-fpm.conf
elif [ $Mem -gt 4500 -a $Mem -le 6500 ]; then
  sed -i "s@^pm.max_children.*@pm.max_children = 60@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.start_servers.*@pm.start_servers = 40@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 30@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 60@" ${PHP_70_PATH}/etc/php-fpm.conf
elif [ $Mem -gt 6500 -a $Mem -le 8500 ]; then
  sed -i "s@^pm.max_children.*@pm.max_children = 70@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.start_servers.*@pm.start_servers = 50@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 40@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 70@" ${PHP_70_PATH}/etc/php-fpm.conf
elif [ $Mem -gt 8500 ]; then
  sed -i "s@^pm.max_children.*@pm.max_children = 80@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.start_servers.*@pm.start_servers = 60@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.min_spare_servers.*@pm.min_spare_servers = 50@" ${PHP_70_PATH}/etc/php-fpm.conf
  sed -i "s@^pm.max_spare_servers.*@pm.max_spare_servers = 80@" ${PHP_70_PATH}/etc/php-fpm.conf
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
