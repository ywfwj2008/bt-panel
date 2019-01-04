#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
redis_version=5.0.0
runPath=/root
node_Check(){
	public_file=/www/server/panel/install/public.sh
	if [ ! -f $public_file ];then
		wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
	fi
	. $public_file

	download_Url=$NODE_URL
}
Service_On(){
	if [ -f "/usr/bin/yum" ];then
		chkconfig --add redis
		chkconfig --level 2345 redis on
	elif [ -f "/usr/bin/apt" ]; then
		update-rc.d redis defaults
	fi
}
Service_Off(){
	if [ -f "/usr/bin/yum" ];then
		chkconfig --del redis
		chkconfig --level 2345 redis off
	elif [ -f "/usr/bin/apt" ]; then
		update-rc.d redis remove
	fi
}

ext_Path(){
	case "${version}" in 
		'53')
		extFile='/www/server/php/53/lib/php/extensions/no-debug-non-zts-20090626/redis.so'
		;;
		'54')
		extFile='/www/server/php/54/lib/php/extensions/no-debug-non-zts-20100525/redis.so'
		;;
		'55')
		extFile='/www/server/php/55/lib/php/extensions/no-debug-non-zts-20121212/redis.so'
		;;
		'56')
		extFile='/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/redis.so'
		;;
		'70')
		extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/redis.so'
		;;
		'71')
		extFile='/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/redis.so'
		;;
		'72')
		extFile='/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/redis.so'
		;;
		'73')
		extFile='/www/server/php/73/lib/php/extensions/no-debug-non-zts-20180731/redis.so'
		;;
	esac
}
Install_Redis()
{
	node_Check
    if [ ! -f '/www/server/redis/src/redis-server' ];then
    	cd /www/server
		wget $download_Url/src/redis-$redis_version.tar.gz -T 5
		tar zxvf redis-$redis_version.tar.gz
		mv redis-$redis_version redis
		cd redis
		make

		echo "#!/bin/sh
# chkconfig: 2345 56 26
# description: Redis Service

### BEGIN INIT INFO
# Provides:          Redis
# Required-Start:    \$all
# Required-Stop:     \$all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts Redis
# Description:       starts the BT-Web
### END INIT INFO

# Simple Redis init.d script conceived to work on Linux systems
# as it does use of the /proc filesystem.

CONF=\"/www/server/redis/redis.conf\"
REDISPORT=\$(cat \$CONF |grep port|grep -v '#'|awk '{print \$2}')
REDISPASS=\$(cat \$CONF |grep requirepass|grep -v '#'|awk '{print \$2}')
if [ \"\$REDISPASS\" != \"\" ];then
	REDISPASS=\" -a \$REDISPASS\"
fi
if [ -f "/www/server/redis/start.pl" ];then
	STARPORT=\$(cat /www/server/redis/start.pl)
else
	STARPORT="6379"
fi
EXEC=/www/server/redis/src/redis-server
CLIEXEC=\"/www/server/redis/src/redis-cli -p \$STARPORT\$REDISPASS\"
PIDFILE=/var/run/redis_6379.pid

redis_start(){
	if [ -f \$PIDFILE ]
	then
			echo \"\$PIDFILE exists, process is already running or crashed\"
	else
			echo \"Starting Redis server...\"
			nohup \$EXEC \$CONF >> /www/server/redis/logs.pl 2>&1 &
			echo \${REDISPORT} > /www/server/redis/start.pl
	fi
}
redis_stop(){
	if [ ! -f \$PIDFILE ]
	then
			echo \"\$PIDFILE does not exist, process is not running\"
	else
			PID=\$(cat \$PIDFILE)
			echo \"Stopping ...\"
			\$CLIEXEC shutdown
			while [ -x /proc/\${PID} ]
			do
				echo \"Waiting for Redis to shutdown ...\"
				sleep 1
			done
			echo \"Redis stopped\"
	fi
}


case \"\$1\" in
    start)
		redis_start
        ;;
    stop)
        redis_stop
        ;;
	restart|reload)
		redis_stop
		sleep 0.3
		redis_start
		;;
    *)
        echo \"Please use start or stop as first argument\"
        ;;
esac
" > /etc/init.d/redis
		
		ln -sf /www/server/redis/src/redis-cli /usr/bin/redis-cli
		chmod +x /etc/init.d/redis
		Service_On
		/etc/init.d/redis start
		rm -f /www/server/redis-$redis_version.tar.gz
		cd $runPath
		echo $redis_version > /www/server/redis/version.pl
	fi
	
	if [ ! -d /www/server/php/$version ];then
		return;
	fi
	
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'redis.so'`
	if [ "${isInstall}" != "" ];then
		echo "php-$vphp 已安装过Redis,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	ext_Path

	if [ ! -f "${extFile}" ];then		
		if [ "${version}" == '52' ];then
			rVersion='2.2.7'
		else
			rVersion='4.2.0'
		fi
		
		wget $download_Url/src/redis-$rVersion.tgz -T 5
		tar zxvf redis-$rVersion.tgz
		rm -f redis-$rVersion.tgz
		cd redis-$rVersion
		/www/server/php/$version/bin/phpize
		./configure --with-php-config=/www/server/php/$version/bin/php-config
		make && make install
		cd ../
		rm -rf redis-$rVersion*
	fi
	
	if [ ! -f "${extFile}" ];then
		echo 'error';
		exit 0;
	fi
	
	echo -e "\n[redis]\nextension = ${extFile}\n" >> /www/server/php/$version/etc/php.ini
	
	
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}

Uninstall_Redis()
{
	if [ ! -d /www/server/php/$version/bin ];then
		pkill -9 redis
		rm -f /var/run/redis_6379.pid
		Service_Off
		rm -f /usr/bin/redis-cli
		rm -f /etc/init.d/redis
		rm -rf /www/server/redis
		return;
	fi
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'redis.so'`
	if [ "${isInstall}" = "" ];then
		echo "php-$vphp 未安装Redis,请选择其它版本!"
		echo "php-$vphp not install Redis, Plese select other version!"
		return
	fi
	
	sed -i '/redis.so/d' /www/server/php/$version/etc/php.ini
	
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}
Update_redis(){
	node_Check
	cd /www/server
	wget $download_Url/src/redis-$redis_version.tar.gz -T 5
	tar zxvf redis-$redis_version.tar.gz
	rm -f redis-$redis_version.tar.gz
	mv redis-$redis_version redis2
	cd redis2
	make
	/etc/init.d/redis stop
	sleep 1
	cd ..
	rm -rf /www/server/redis
	mv redis2 redis
	rm -f /usr/bin/redis-cli
	ln -sf /www/server/redis/src/redis-cli /usr/bin/redis-cli
	/etc/init.d/redis start
	rm -f /www/server/redis/version_check.pl
	echo $redis_version > /www/server/redis/version.pl
}
actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Install_Redis
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Redis
elif [ "${actionType}" == "update" ]; then
	Update_redis
fi
