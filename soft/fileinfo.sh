#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Install_Fileinfo()
{
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'fileinfo.so'`
	if [ "${isInstall}" != "" ];then
		echo "php-$vphp 已安装过Fileinfo,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	if [ ! -d "/www/server/php/$version/src/ext/fileinfo" ];then
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
		mkdir -p /www/server/php/$version/src
		wget -O ext-$version.zip $Download_Url/install/ext/ext-$version.zip
		unzip -o ext-$version.zip -d /www/server/php/$version/src/ > /dev/null
		mv /www/server/php/$version/src/ext-$version /www/server/php/$version/src/ext
		rm -f ext-$version.zip
	fi
	
	case "${version}" in 
		'52')
		extFile='/www/server/php/52/lib/php/extensions/no-debug-non-zts-20060613/fileinfo.so'
		;;
		'53')
		extFile='/www/server/php/53/lib/php/extensions/no-debug-non-zts-20090626/fileinfo.so'
		;;
		'54')
		extFile='/www/server/php/54/lib/php/extensions/no-debug-non-zts-20100525/fileinfo.so'
		;;
		'55')
		extFile='/www/server/php/55/lib/php/extensions/no-debug-non-zts-20121212/fileinfo.so'
		;;
		'56')
		extFile='/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/fileinfo.so'
		;;
		'70')
		extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/fileinfo.so'
		;;
		'71')
		extFile='/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/fileinfo.so'
		;;
	esac
		
	if [ ! -f "${extFile}" ];then
		cd /www/server/php/$version/src/ext/fileinfo
		/www/server/php/$version/bin/phpize
		./configure --with-php-config=/www/server/php/$version/bin/php-config
		make && make install
	fi
	
	if [ ! -f "${extFile}" ];then
		echo 'error';
		exit 0;
	fi

	echo -e "extension = $extFile" >> /www/server/php/$version/etc/php.ini
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}

Uninstall_Fileinfo()
{
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'fileinfo.so'`
	if [ "${isInstall}" = "" ];then
		echo "php-$vphp 未安装Fileinfo,请选择其它版本!"
		echo "php-$vphp not install Fileinfo, Plese select other version!"
		return
	fi

	sed -i '/fileinfo.so/d' /www/server/php/$version/etc/php.ini

	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}

actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Install_Fileinfo
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Fileinfo
fi