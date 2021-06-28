FROM centos:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=http://test.yiwuwei.com/ywfwj2008/bt \
    NGINX_VERSION=1.6.1

WORKDIR /tmp

# install bt panel
ADD ${REMOTE_PATH}/install_6.0.sh /tmp/install.sh
RUN chmod 777 install.sh \
    && bash install.sh \
    && rm -rf /tmp/*

# install pure-ftpd and nginx
RUN cd /www/server/panel/install \
    && wget -O lib.sh http://download.bt.cn/install/0/lib.sh \
    && bash lib.sh \
    && bash install_soft.sh 0 install pureftpd \
    && bash install_soft.sh 0 install nginx ${NGINX_VERSION} \
    && rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001 25

# Set the entrypoint script.
ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["/etc/init.d/bt", "start"]
