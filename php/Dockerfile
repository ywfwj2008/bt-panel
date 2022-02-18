FROM ywfwj2008/bt-panel:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
#    BISON2_VERSION=2.7.1 \
    BISON3_VERSION=3.8.2 \
#    MEMCACHED2_VERSION=2.2.0 \
    MEMCACHED3_VERSION=3.1.5 \
#    REDIS4_VERSION=4.3.0 \
    REDIS5_VERSION=5.3.7 \
#    PHP_56_PATH=/www/server/php/56 \
    PHP_74_PATH=/www/server/php/74

WORKDIR /tmp

# install php5.6
#RUN wget http://ftp.igh.cnrs.fr/pub/gnu/bison/bison-${BISON2_VERSION}.tar.gz \
#    && tar -zxvf bison-${BISON2_VERSION}.tar.gz \
#    && cd bison-${BISON2_VERSION} \
#    && ./configure --prefix=/usr \
#    && make && make install \
#    && cd /tmp \
#    && bash /www/server/panel/install/install_soft.sh 0 install php 5.6 \
#    && sed -i 's/disable_functions =.*/disable_functions = system/g' ${PHP_56_PATH}/etc/php.ini \
#    && bash /www/server/panel/install/install_soft.sh 1 install fileinfo 56 \
#    && bash /www/server/panel/install/install_soft.sh 1 install opcache 56 \
#    && bash /www/server/panel/install/install_soft.sh 1 install imagemagick 56 \
#    && pecl channel-update pecl.php.net \
#    && ${PHP_56_PATH}/bin/pecl install channel://pecl.php.net/redis-${REDIS4_VERSION} \
#    && ${PHP_56_PATH}/bin/pecl install channel://pecl.php.net/memcached-${MEMCACHED2_VERSION} \
#    && echo "extension=memcached.so" >> ${PHP_56_PATH}/etc/php.ini \
#    && sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,proc_open,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${PHP_56_PATH}/etc/php.ini \
#    && rm -rf /tmp/*

# install php7.4
RUN wget http://ftp.igh.cnrs.fr/pub/gnu/bison/bison-${BISON3_VERSION}.tar.gz \
    && tar -zxvf bison-${BISON3_VERSION}.tar.gz \
    && cd bison-${BISON3_VERSION} \
    && ./configure --prefix=/usr \
    && make && make install \
    && cd /tmp \
    && bash /www/server/panel/install/install_soft.sh 0 install php 7.4 \
    && bash /www/server/panel/install/install_soft.sh 1 install fileinfo 74 \
    && bash /www/server/panel/install/install_soft.sh 1 install opcache 74 \
#    && bash /www/server/panel/install/install_soft.sh 1 install imagemagick 74 \
    && wget http://pecl.php.net/get/redis-${REDIS5_VERSION}.tgz \
    && ${PHP_74_PATH}/bin/pecl install redis-${REDIS5_VERSION}.tgz \
    && wget http://pecl.php.net/get/memcached-${MEMCACHED3_VERSION}.tgz \
    && ${PHP_74_PATH}/bin/pecl install memcached-${MEMCACHED3_VERSION}.tgz \
    && rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001 25

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
