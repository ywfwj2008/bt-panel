FROM ywfwj2008/bt-php:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

ENV REMOTE_PATH=https://github.com/ywfwj2008/bt-panel/raw/master

WORKDIR /tmp

# install tengine
RUN bash /www/server/panel/install/install_soft.sh 0 install nginx -Tengine2.2.0

# expose port
EXPOSE 8888 80 443 21 20

# Set the entrypoint script.
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
