#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
memcachedVer="1.5.11"
memcachedPhpVer="3.1.3"
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL
srcPath='/root';
Install_Memcached()
{	
	yum -y remove libmemcached libmemcached-devel
	yum install cyrus-sasl cyrus-sasl-devel libevent libevent-devel -y
	if [ ! -f "/usr/local/memcached/bin/memcached" ];then
	    groupadd memcached
    	useradd -s /sbin/nologin -g memcached memcached
		cd $srcPath
		wget $download_Url/src/memcached-${memcachedVer}.tar.gz -T 5
		tar -xzf memcached-${memcachedVer}.tar.gz
		cd memcached-${memcachedVer}
		./configure --prefix=/usr/local/memcached
		make && make install
		ln -sf /usr/local/memcached/bin/memcached /usr/bin/memcached
		wget -O /etc/init.d/memcached $download_Url/init/init.d.memcached -T 5
		chmod +x /etc/init.d/memcached
		chkconfig --add memcached
		chkconfig --level 2345 memcached on

		#if [ ! -f "/etc/init.d/iptables" ];then
			#firewall-cmd --permanent --zone=public --add-port=11211/tcp
			#firewall-cmd --permanent --zone=public --add-port=11211/udp
			#firewall-cmd --reload
		#else
			#/sbin/iptables -A INPUT -p tcp --dport 11211 -j ACCEPT
			#/sbin/iptables -A INPUT -p udp --dport 11211 -j ACCEPT
			#service iptables save
			#service iptables restart
		#fi

		cd $srcPath
		wget $download_Url/src/libmemcached-1.0.18.tar.gz -T 5
		tar -zxf libmemcached-1.0.18.tar.gz
		cd libmemcached-1.0.18
		./configure --prefix=/usr/local/libmemcached --with-memcached
		make && make install

		/etc/init.d/memcached start

		cd $srcPath
		rm -rf memcached*
		rm -rf libmemcached*
	fi
	
	if [ ! -d /www/server/php/$version ];then
		return;
	fi
	
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'memcached.so'`
	if [ "${isInstall}" != "" ];then
		echo "php-$vphp 已安装过memcached,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
		
	case "${version}" in 
		'52')
		extFile='/www/server/php/52/lib/php/extensions/no-debug-non-zts-20060613/memcached.so'
		;;
		'53')
		extFile='/www/server/php/53/lib/php/extensions/no-debug-non-zts-20090626/memcached.so'
		;;
		'54')
		extFile='/www/server/php/54/lib/php/extensions/no-debug-non-zts-20100525/memcached.so'
		;;
		'55')
		extFile='/www/server/php/55/lib/php/extensions/no-debug-non-zts-20121212/memcached.so'
		;;
		'56')
		extFile='/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/memcached.so'
		;;
		'70')
		extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/memcached.so'
		;;
		'71')
		extFile='/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/memcached.so'
		;;
		'72')
		extFile='/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/memcached.so'
		;;
		'73')
		extFile='/www/server/php/73/lib/php/extensions/no-debug-non-zts-20180731/memcached.so'
		;;
	esac

	if [ ! -f "${extFile}" ];then
		cd $srcPath
		if [ "${version}" -ge "70" ];then
			wget $download_Url/src/memcached-${memcachedPhpVer}.tgz -T 5
			tar -xvf memcached-${memcachedPhpVer}.tgz
			cd memcached-${memcachedPhpVer}
			
			/www/server/php/$version/bin/phpize
			./configure --with-php-config=/www/server/php/$version/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached --enable-sasl
			make && make install
			cd $srcPath
			rm -f memcached-${memcachedPhpVer}${memcachedPhpVer}.tgz
			rm -rf memcached-${memcachedPhpVer}
		else
			wget $download_Url/src/memcached-2.2.0.tgz -T 5
			tar -zxf memcached-2.2.0.tgz
			cd memcached-2.2.0
			/www/server/php/$version/bin/phpize
			./configure --with-php-config=/www/server/php/$version/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached --enable-sasl
			make && make install
			cd $srcPath
			rm -rf memcached*
		fi
	fi
	
	if [ ! -f "$extFile" ];then
		echo 'error';
		exit 0;
	fi
	
	echo "extension=memcached.so" >> /www/server/php/$version/etc/php.ini
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}


Uninstall_Memcached()
{
	if [ ! -d /www/server/php/$version ];then
		/etc/init.d/memcached stop
		pkill -9 memcached
		chkconfig --del memcached
		chkconfig --level 2345 memcached off
		rm -f /etc/init.d/memcached
		rm -rf /usr/local/memcached
		return;
	fi
	
	if [ ! -f "/www/server/php/$version/bin/php-config" ];then
		echo "php-$vphp 未安装,请选择其它版本!"
		echo "php-$vphp not install, Plese select other version!"
		return
	fi
	
	isInstall=`cat /www/server/php/$version/etc/php.ini|grep 'memcached.so'`
	if [ "${isInstall}" = "" ];then
		echo "php-$vphp 未安装memcached,请选择其它版本!"
		echo "php-$vphp not install memcached, Plese select other version!"
		return
	fi
		
	sed -i '/memcached.so/d'  /www/server/php/$version/etc/php.ini
	service php-fpm-$version reload
	echo '==============================================='
	echo 'successful!'
}
Update_memcached(){
	cd $srcPath
	wget $download_Url/src/memcached-${memcachedVer}.tar.gz -T 5
	tar -xzf memcached-${memcachedVer}.tar.gz
	cd memcached-${memcachedVer}
	./configure --prefix=/usr/local/memcached
	make

	/etc/init.d/memcached stop
	make install

	cd $srcPath
	wget $download_Url/src/libmemcached-1.0.18.tar.gz -T 5
	tar -zxf libmemcached-1.0.18.tar.gz
	cd libmemcached-1.0.18
	./configure --prefix=/usr/local/libmemcached --with-memcached
	make && make install
	
	/etc/init.d/memcached start
	rm -f /usr/local/memcached/version_check.pl
	cd $srcPath
	rm -f libmemcached-1.0.18.tar.gz
	rm -f memcached-${memcachedVer}.tar.gz
	rm -rf memcached-${memcachedVer}
	rm -rf lbmemcached-1.0.18

	for version in 52 53 54 55 56 70 71 72 73
	do
		case "${version}" in 
			'52')
			extFile='/www/server/php/52/lib/php/extensions/no-debug-non-zts-20060613/memcached.so'
			;;
			'53')
			extFile='/www/server/php/53/lib/php/extensions/no-debug-non-zts-20090626/memcached.so'
			;;
			'54')
			extFile='/www/server/php/54/lib/php/extensions/no-debug-non-zts-20100525/memcached.so'
			;;
			'55')
			extFile='/www/server/php/55/lib/php/extensions/no-debug-non-zts-20121212/memcached.so'
			;;
			'56')
			extFile='/www/server/php/56/lib/php/extensions/no-debug-non-zts-20131226/memcached.so'
			;;
			'70')
			extFile='/www/server/php/70/lib/php/extensions/no-debug-non-zts-20151012/memcached.so'
			;;
			'71')
			extFile='/www/server/php/71/lib/php/extensions/no-debug-non-zts-20160303/memcached.so'
			;;
			'72')
			extFile='/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/memcached.so'
			;;
			'73')
			extFile='/www/server/php/72/lib/php/extensions/no-debug-non-zts-20170718/memcached.so'
			;;
		esac

		if [ -f "${extFile}" ];then
			cd $srcPath
			rm -f ${extFile}
			if [ "${version}" == "70" ]  || [ "${version}" == '71' ] || [ "${version}" == '72' ];then
				wget $download_Url/src/memcached-${memcachedPhpVer}.tgz -T 5
				tar -xvf memcached-${memcachedPhpVer}.tgz
				cd memcached-${memcachedPhpVer}
				
				/www/server/php/$version/bin/phpize
				./configure --with-php-config=/www/server/php/$version/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached --disable-memcached-sasl
				make && make install
				cd $srcPath
				rm -f memcached-3.0.4.tgz
				rm -rf memcached-3.0.4
			else
				wget $download_Url/src/memcached-2.2.0.tgz -T 5
				tar -zxf memcached-2.2.0.tgz
				cd memcached-2.2.0
				/www/server/php/$version/bin/phpize
				./configure --with-php-config=/www/server/php/$version/bin/php-config --enable-memcached --with-libmemcached-dir=/usr/local/libmemcached --disable-memcached-sasl
				make && make install
				cd $srcPath
				rm -rf memcached*
			fi
			/etc/init.d/php-fpm-${version} reload
		fi
	done
}

actionType=$1
version=$2
vphp=${version:0:1}.${version:1:1}
if [ "$actionType" == 'install' ];then
	Install_Memcached
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Memcached
elif [ "${actionType}" == "update" ]; then
	Update_memcached
fi
