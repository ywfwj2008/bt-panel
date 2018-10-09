FROM ywfwj2008/bt-panel:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
    LIBMEMCACHED_VERSION=1.0.18 \
    MEMCACHED_PECL_VERSION=2.2.0 \
    MEMCACHED_PHP7_PECL_VERSION=3.0.4 \
    PHP_56_PATH=/www/server/php/56 \
    PHP_70_PATH=/www/server/php/70
    PHP_71_PATH=/www/server/php/71
    PHP_72_PATH=/www/server/php/72

WORKDIR /tmp

# install php5.6
RUN bash /www/server/panel/install/install_soft.sh 0 install php 5.6 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 56 && \
    rm -rf /tmp/*

# install php7.0
RUN bash /www/server/panel/install/install_soft.sh 0 install php 7.0 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 70 && \
    rm -rf /tmp/*

# install php7.1
RUN bash /www/server/panel/install/install_soft.sh 0 install php 7.1 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 71 && \
    rm -rf /tmp/*

# install php7.2
RUN bash /www/server/panel/install/install_soft.sh 0 install php 7.2 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 72 && \
    rm -rf /tmp/*

# install php-redis
RUN ${PHP_70_PATH}/bin/pecl install redis && \
    ${PHP_71_PATH}/bin/pecl install redis && \
    ${PHP_72_PATH}/bin/pecl install redis && \
    ${PHP_56_PATH}/bin/pecl install redis && \
    echo "extension=redis.so" >> ${PHP_56_PATH}/etc/php.ini && \
    rm -rf /tmp/*

# install php-memcached
RUN wget -c --no-check-certificate https://launchpad.net/libmemcached/1.0/${LIBMEMCACHED_VERSION}/+download/libmemcached-${LIBMEMCACHED_VERSION}.tar.gz && \
    wget -c https://src.fedoraproject.org/cgit/rpms/libmemcached.git/plain/libmemcached-build.patch && \
    tar xzf libmemcached-${LIBMEMCACHED_VERSION}.tar.gz && \
    patch -d libmemcached-${LIBMEMCACHED_VERSION} -p0 < libmemcached-build.patch && \
    cd libmemcached-${LIBMEMCACHED_VERSION} && \
    ./configure && \
    make && make install && \
    cd .. && \
    ${PHP_70_PATH}/bin/pecl install memcached && \
    ${PHP_71_PATH}/bin/pecl install memcached && \
    ${PHP_72_PATH}/bin/pecl install memcached && \
    ${PHP_56_PATH}/bin/pecl install memcached-${MEMCACHED_PECL_VERSION} && \
    echo "extension=memcached.so" >> ${PHP_56_PATH}/etc/php.ini && \
    rm -rf /tmp/*

RUN /usr/bin/composer self-update

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001 25

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
