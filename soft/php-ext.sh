#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

PHP_INSTALL_DIR=/www/server/php/70
LIBMEMCACHED_VERSION=1.0.18
MEMCACHED_PECL_VERSION=3.0.3
EVENT_VERSION=2.3.0
SWOOLE_VERSION=2.0.7

# install php-memcache
# git clone https://github.com/websupport-sk/pecl-memcache.git
# cd pecl-memcache
wget -c --no-check-certificate http://mirrors.linuxeye.com/oneinstack/src/pecl-memcache-php7.tgz && \
tar xzf pecl-memcache-php7.tgz && \
cd pecl-memcache-php7 && \
$PHP_INSTALL_DIR/bin/phpize && \
./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config && \
make && make install && \
echo "extension=memcache.so" > $PHP_INSTALL_DIR/etc/php.d/ext-memcache.ini && \
rm -rf /tmp/*

# install php-memcached
wget -c --no-check-certificate https://launchpad.net/libmemcached/1.0/$LIBMEMCACHED_VERSION/+download/libmemcached-$LIBMEMCACHED_VERSION.tar.gz && \
tar xzf libmemcached-$LIBMEMCACHED_VERSION.tar.gz && \
cd libmemcached-$LIBMEMCACHED_VERSION && \
sed -i "s@lthread -pthread -pthreads@lthread -lpthread -pthreads@" ./configure && \
./configure && \
make && make install && \
cd .. && \
wget -c --no-check-certificate http://pecl.php.net/get/memcached-$MEMCACHED_PECL_VERSION.tgz && \
tar xzf memcached-$MEMCACHED_PECL_VERSION.tgz && \
cd memcached-$MEMCACHED_PECL_VERSION && \
$PHP_INSTALL_DIR/bin/phpize && \
./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config && \
make && make install && \
echo "extension=memcached.so" >> $PHP_INSTALL_DIR/etc/php.d/ext-memcached.ini && \
echo "memcached.use_sasl=1" >> $PHP_INSTALL_DIR/etc/php.d/ext-memcached.ini && \
rm -rf /tmp/*

# install php-redis
$PHP_INSTALL_DIR/bin/pecl install redis && \
echo "extension=redis.so" > $PHP_INSTALL_DIR/etc/php.ini

# install php-swoole
$PHP_INSTALL_DIR/bin/pecl install swoole && \
echo "extension=swoole.so" > $PHP_INSTALL_DIR/etc/php.ini

# install event
wget -c --no-check-certificate http://pecl.php.net/get/event-$EVENT_VERSION.tgz && \
tar xzf event-$EVENT_VERSION.tgz && \
cd event-$EVENT_VERSION && \
$PHP_INSTALL_DIR/bin/phpize && \
./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config --with-event-openssl=no --enable-event-sockets --with-event-extra && \
make && make install && \
echo "extension=event.so" > $PHP_INSTALL_DIR/etc/php.d/ext-event.ini && \
rm -rf /tmp/*

# install ioncube and sg11
phpExtensionDir=$(${PHP_INSTALL_DIR}/bin/php-config --extension-dir) && \
wget -c http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -P /tmp && \
tar xzf /tmp/ioncube_loaders_lin_x86-64.tar.gz && \
/bin/cp /tmp/ioncube/ioncube_loader_lin_7.0.so ${phpExtensionDir}/ioncube_loader.so && \
wget -c https://github.com/ywfwj2008/docker-php/raw/master/loaders.linux-x86_64.tar.gz -P /tmp && \
tar xzf /tmp/loaders.linux-x86_64.tar.gz && \
/bin/cp /tmp/ixed.7.0.lin ${phpExtensionDir}/ixed.lin && \
rm -rf /tmp/*
