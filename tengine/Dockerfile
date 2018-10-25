FROM ywfwj2008/bt-php:5.9
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master \
    JEMALLOC_VERSION=5.1.0

WORKDIR /tmp

# install jemalloc
# 查看jemalloc状态  lsof -n | grep jemalloc
RUN wget -c --no-check-certificate https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2 && \
    tar xjf jemalloc-${JEMALLOC_VERSION}.tar.bz2 && \
    cd jemalloc-${JEMALLOC_VERSION} && \
    ./configure && \
    make && make install && \
    echo '/usr/local/lib' > /etc/ld.so.conf.d/local.conf && \
    ldconfig && \
    rm -rf /tmp/*

# install tengine
RUN bash /www/server/panel/install/install_soft.sh 0 install nginx && \
    rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
