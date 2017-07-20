#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Swoole_Version='1.9.14'

Install_Swoole()
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

    case "${version}" in 
    	'53')
    	extFile='/www/server/php/53/lib/php/extensions/no-debug-non-zts-20090626/swoole.so'
    	;;
    	'54')
    	extFile='/www/server/php/54/lib/php/extensions/no-debug-non-zts-20100525/swoole.so'
    	;;
    	'55')
    	extFile='/www/server/php/55/lib/php/extensions/no-debug-non-zts-20121212/swoole.so'
    	;;
    	'56')
    	extFile='/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/swoole.so'
    	;;
    	'70')
    	extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/swoole.so'
    	;;
    	'71')
    	extFile='/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/swoole.so'
    	;;
    esac

    if [ ! -f "${extFile}" ];then
    	wget $Download_Url/src/swoole-$Swoole_Version.tgz
    	tar -zxvf swoole-$Swoole_Version.tgz
    	cd swoole-$Swoole_Version
    	/www/server/php/$version/bin/phpize
		./configure --with-php-config=/www/server/php/$version/bin/php-config
		make && make install
		cd ../
		rm -rf swoole*
   	fi

   	if [ ! -f "${extFile}" ];then
   		echo 'error';
   		exit 0;
   	fi
   	
   	echo -e "\n[swoole]\nextension = swoole.so\n" >> /www/server/php/$version/etc/php.ini

   	service php-fpm-$version reload
}



Uninstall_Swoole()
{
	sed -i '/swoole/d' /www/server/php/$version/etc/php.ini	
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}

actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Install_Swoole
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Swoole
fi
