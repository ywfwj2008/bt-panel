FROM centos:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master

WORKDIR /tmp

# run install script
ADD ${REMOTE_PATH}/install.sh /tmp/install.sh
RUN chmod 777 install.sh && \
    bash install.sh && \
    rm -rf /tmp/*

# expose port
EXPOSE 8888 80 443 21 20

# Set the entrypoint script.
#ADD ${REMOTE_PATH}/entrypoint.sh /entrypoint.sh
#RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/usr/bin/bt", "start"]

#Define the default command.
#CMD ["/usr/bin/bt" "start"]
