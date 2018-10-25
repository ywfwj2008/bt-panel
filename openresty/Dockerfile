FROM ywfwj2008/bt-php:5.9
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master

WORKDIR /tmp

# install openresty
RUN bash /www/server/panel/install/install_soft.sh 0 install nginx openresty && \
    rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
