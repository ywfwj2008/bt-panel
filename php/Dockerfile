FROM ywfwj2008/bt-panel:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
    PHP_56_PATH=/www/server/php/56 \
    PHP_70_PATH=/www/server/php/70

WORKDIR /tmp

# install php5.6
RUN wget http://ftp.gnu.org/gnu/bison/bison-2.7.1.tar.gz \
    && tar -zxvf bison-2.7.1.tar.gz \
    && cd bison-2.7.1 \
    && ./configure --prefix=/usr \
    && make && make install \
    && cd /tmp \
    && bash /www/server/panel/install/install_soft.sh 0 install php 5.6 \
    && bash /www/server/panel/install/install_soft.sh 1 install fileinfo 56 \
    && bash /www/server/panel/install/install_soft.sh 1 install opcache 56 \
    && wget http://pecl.php.net/get/redis-4.2.0.tgz \
    && ${PHP_56_PATH}/bin/pecl install redis-4.2.0.tgz \
    && ${PHP_56_PATH}/bin/pecl install memcached-2.2.0 \
    && echo "extension=memcached.so" >> ${PHP_56_PATH}/etc/php.ini \
    && rm -rf /tmp/*

# install php7.0
RUN wget http://ftp.gnu.org/gnu/bison/bison-3.2.4.tar.gz \
    && tar -zxvf bison-3.2.4.tar.gz \
    && cd bison-3.2.4 \
    && ./configure --prefix=/usr \
    && make && make install \
    && cd /tmp \
    && bash /www/server/panel/install/install_soft.sh 0 install php 7.0 \
    && bash /www/server/panel/install/install_soft.sh 1 install fileinfo 70 \
    && bash /www/server/panel/install/install_soft.sh 1 install opcache 70 \
    && wget http://pecl.php.net/get/redis-4.2.0.tgz \
    && ${PHP_70_PATH}/bin/pecl install redis-4.2.0.tgz \
    && wget http://pecl.php.net/get/memcached-3.1.3.tgz \
    && ${PHP_70_PATH}/bin/pecl install memcached-3.1.3.tgz \
    && rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
