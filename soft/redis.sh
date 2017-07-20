#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Install_Redis()
{
	CN='125.88.182.172'
	HK='103.224.251.79'
	HK2='103.224.251.67'
	US='128.1.164.196'
	sleep 0.5;
	CN_PING=`ping -c 1 -w 1 $CN|grep time=|awk '{print $7}'|sed "s/time=//"`
	HK_PING=`ping -c 1 -w 1 $HK|grep time=|awk '{print $7}'|sed "s/time=//"`
	HK2_PING=`ping -c 1 -w 1 $HK2|grep time=|awk '{print $7}'|sed "s/time=//"`
	US_PING=`ping -c 1 -w 1 $US|grep time=|awk '{print $7}'|sed "s/time=//"`

	echo "$HK_PING $HK" > ping.pl
	echo "$HK2_PING $HK2" >> ping.pl
	echo "$US_PING $US" >> ping.pl
	echo "$CN_PING $CN" >> ping.pl
	nodeAddr=`sort -n -b ping.pl|sed -n '1p'|awk '{print $2}'`
	if [ "$nodeAddr" == "" ];then
		nodeAddr=$HK
	fi

	Download_Url=http://$nodeAddr:5880
	
	
    runPath=/root

    if [ ! -f '/www/server/redis/src/redis-server' ];then
    	cd /www/server
		wget $Download_Url/src/redis-3.2.9.tar.gz -T 5
		tar zxvf redis-3.2.9.tar.gz
		mv redis-3.2.9 redis
		cd redis
		make

		echo "#!/bin/sh
# chkconfig: 2345 55 25
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

REDISPORT=6379
EXEC=/www/server/redis/src/redis-server
CLIEXEC=/www/server/redis/src/redis-cli

PIDFILE=/var/run/redis_\$REDISPORT.pid
CONF=\"/www/server/redis/redis.conf\"

redis_start(){
	if [ -f \$PIDFILE ]
	then
			echo \"\$PIDFILE exists, process is already running or crashed\"
	else
			echo \"Starting Redis server...\"
			nohup \$EXEC \$CONF >> /www/server/redis/logs.pl 2>&1 &
	fi
}
redis_stop(){
	if [ ! -f \$PIDFILE ]
	then
			echo \"\$PIDFILE does not exist, process is not running\"
	else
			PID=\$(cat \$PIDFILE)
			echo \"Stopping ...\"
			\$CLIEXEC -p \$REDISPORT shutdown
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
		chmod +x /etc/init.d/redis
		chkconfig --add redis
		chkconfig --level 2345 redis on
		/etc/init.d/redis start
		rm -f /www/server/redis-3.2.9.tar.gz
		cd $runPath
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
	
	case "${version}" in 
		'52')
		extFile='/www/server/php/52/lib/php/extensions/no-debug-non-zts-20060613/redis.so'
		;;
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
	esac

	if [ ! -f "${extFile}" ];then		
		if [ "${version}" == '52' ];then
			rVersion='2.2.7'
		else
			rVersion='3.1.1'
		fi
		
		wget $Download_Url/src/redis-$rVersion.tgz -T 5
		tar zxvf redis-$rVersion.tgz
		rm -f redis-$rVersion.tgz
		cd redis-$rVersion
		/www/server/php/$version/bin/phpize
		./configure --with-php-config=/www/server/php/$version/bin/php-config
		make && make install
		rm -rf redis-$rVersion
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
	if [ ! -d /www/server/php/$version ];then
		/etc/init.d/redis stop
		pkill -9 redis
		chkconfig --del redis
		chkconfig --level 2345 redis off
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
actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Install_Redis
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Redis
fi
