FROM ywfwj2008/lbnp:latest
MAINTAINER ywfwj2008 <ywfwj2008@163.com>

WORKDIR /tmp

# expose port
EXPOSE 8888 80 443 21 20 888 3306 9001 25

# Set the entrypoint script.
ADD ${REMOTE_PATH}/lbnp.sh /entrypoint.sh
RUN chmod 777 /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

#Define the default command.
CMD ["/etc/init.d/bt", "start"]
