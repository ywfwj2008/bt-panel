FROM ywfwj2008/bt-panel:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master

WORKDIR /tmp

# install php
RUN bash /www/server/panel/install/install_soft.sh 0 install php 5.6 && \
    bash /www/server/panel/install/install_soft.sh 0 install php 7.0 && \
    bash /www/server/panel/install/install_soft.sh 0 install swoole 56 && \
    bash /www/server/panel/install/install_soft.sh 0 install swoole 70 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 56 && \
    bash /www/server/panel/install/install_soft.sh 0 install fileinfo 70 && \
    rm -rf /tmp/*

RUN /usr/bin/composer self-update

# expose port
EXPOSE 8888 80 443 21 20 888

# Set the entrypoint script.
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
