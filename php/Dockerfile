FROM ywfwj2008/bt-panel:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
    LIBMEMCACHED_VERSION=1.0.18 \
    MEMCACHED_PECL_VERSION=3.0.4 \

WORKDIR /tmp

# install php5.6
RUN bash /www/server/panel/install/install_soft.sh 0 install php 5.6 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 56 && \
    #bash /www/server/panel/install/install_soft.sh 0 install swoole 56 && \
    #install php-redis
    /www/server/php/56/bin/pecl install redis && \
    echo "extension=redis.so" >> /www/server/php/56/etc/php.ini && \
    rm -rf /tmp/*

# install php7.0
RUN bash /www/server/panel/install/install_soft.sh 0 install php 7.0 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 70 && \
    #bash /www/server/panel/install/install_soft.sh 0 install swoole 70 && \
    /www/server/php/70/bin/pecl install redis && \
    rm -rf /tmp/*

RUN /usr/bin/composer self-update

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
