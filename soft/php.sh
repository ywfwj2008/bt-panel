#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

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
Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/php
php_path=$Root_Path/server/php
mysql_dir=$Root_Path/server/mysql
mysql_config="${mysql_dir}/bin/mysql_config"
Is_64bit=`getconf LONG_BIT`
run_path='/root'
apacheVersion=`cat /var/bt_apacheVersion.pl`

lib_install='/www/server/rpm.pl'
if [ ! -f "${lib_install}" ];then
    wget -O lib.sh ${Download_Url}/install/1/lib.sh && sh lib.sh
fi

php_55='5.5.38'
php_56='5.6.31'
php_70='7.0.21'
php_71='7.1.7'

Set_PHP_FPM_Opt()
{
    if [[ ${MemTotal} -gt 1024 && ${MemTotal} -le 2048 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 30#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 5#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 30#" ${php_setup_path}/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 2048 && ${MemTotal} -le 4096 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 50#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 10#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 10#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 50#" ${php_setup_path}/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 4096 && ${MemTotal} -le 8192 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 80#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 15#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 15#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 80#" ${php_setup_path}/etc/php-fpm.conf
    elif [[ ${MemTotal} -gt 8192 ]]; then
        sed -i "s#pm.max_children.*#pm.max_children = 100#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.start_servers.*#pm.start_servers = 20#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.min_spare_servers.*#pm.min_spare_servers = 20#" ${php_setup_path}/etc/php-fpm.conf
        sed -i "s#pm.max_spare_servers.*#pm.max_spare_servers = 100#" ${php_setup_path}/etc/php-fpm.conf
    fi
}


Export_PHP_Autoconf()
{
    export PHP_AUTOCONF=/usr/local/autoconf-2.13/bin/autoconf
    export PHP_AUTOHEADER=/usr/local/autoconf-2.13/bin/autoheader
}

Ln_PHP_Bin()
{
    ln -sf ${php_setup_path}/bin/php /usr/bin/php
    ln -sf ${php_setup_path}/bin/phpize /usr/bin/phpize
    ln -sf ${php_setup_path}/bin/pear /usr/bin/pear
    ln -sf ${php_setup_path}/bin/pecl /usr/bin/pecl
    ln -sf ${php_setup_path}/sbin/php-fpm /usr/bin/php-fpm
}

Pear_Pecl_Set()
{
    pear config-set php_ini ${php_setup_path}/etc/php.ini
    pecl config-set php_ini ${php_setup_path}/etc/php.ini
}

Install_Composer()
{
	if [ ! -f "/usr/bin/composer" ];then
		wget -O /usr/bin/composer ${Download_Url}/install/src/composer.phar -T 20;
		chmod +x /usr/bin/composer
		if [ "${Download_Url}" == "http://$CN:5880" ];then
			composer config -g repo.packagist composer https://packagist.phpcomposer.com
		fi
	fi
}

Install_PHP_52()
{
	if [ "${apacheVersion}" == "2.4" ];then
		rm -rf $Root_Path/server/php/52
		return;
	fi
	cd ${run_path}
	php_version="52"
	php_setup_path=${php_path}/${php_version}
    Export_PHP_Autoconf
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-5.2.17.tar.gz -T20
	fi
    tar zxf src.tar.gz
	mv php-5.2.17 src
	rm -rf /patch
	mkdir -p /patch
	if [ "${apacheVersion}" != '2.2' ];then
		wget ${Download_Url}/src/php-5.2.17-fpm-0.5.14.diff.gz
		gzip -cd php-5.2.17-fpm-0.5.14.diff.gz | patch -d src -p1
	fi
    
	wget -O /patch/php-5.2.17-max-input-vars.patch ${Download_Url}/src/patch/php-5.2.17-max-input-vars.patch -T20
	wget -O /patch/php-5.2.17-xml.patch ${Download_Url}/src/patch/php-5.2.17-xml.patch -T20
	wget -O /patch/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch ${Download_Url}/src/patch/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch -T20
	wget -O /patch/php-5.2-multipart-form-data.patch ${Download_Url}/src/patch/php-5.2-multipart-form-data.patch -T20
	rm -f php-5.2.17-fpm-0.5.14.diff.gz
	cd src/
    patch -p1 < /patch/php-5.2.17-max-input-vars.patch
    patch -p0 < /patch/php-5.2.17-xml.patch
    patch -p1 < /patch/debian_patches_disable_SSLv2_for_openssl_1_0_0.patch
    patch -p1 < /patch/php-5.2-multipart-form-data.patch
	
	ln -s /usr/lib64/libjpeg.so /usr/lib/libjpeg.so
	ln -s /usr/lib64/libpng.so /usr/lib/libpng.so
	
    ./buildconf --force
	if [ "${apacheVersion}" != '2.2' ];then
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --with-mysql=${mysql_dir} --with-pdo-mysql=${mysql_dir} --with-mysqli=$Root_Path/server/mysql/bin/mysql_config --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-discard-path --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --with-mime-magic --with-iconv=/usr/local/libiconv
	else
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --with-apxs2=$Root_Path/server/apache/bin/apxs --with-mysql=${mysql_dir} --with-pdo-mysql=${mysql_dir} --with-mysqli=$Root_Path/server/mysql/bin/mysql_config --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --enable-discard-path --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --with-mime-magic
	fi
	make ZEND_EXTRA_LIBS='-liconv'
    make install
	
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-dist ${php_setup_path}/etc/php.ini
	
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-5.2 installation failed.\033[0m";
		exit 0;
	fi
	
	#安装mysqli
    #cd ${Root_Path}/server/php/52/src/ext/mysqli/
    #${Root_Path}/server/php/52/bin/phpize
    #echo "${now_path}"
    #./configure --with-php-config=${php_setup_path}/bin/php-config  --with-mysqli=$Root_Path/server/mysql/bin/mysql_config
    #make
    #make install
    #cd ${php_setup_path}	

    Ln_PHP_Bin

    # php extensions
    sed -i "s#extension_dir = \"./\"#extension_dir = \"${php_setup_path}/lib/php/extensions/no-debug-non-zts-20060613/\"\n#" ${php_setup_path}/etc/php.ini
    sed -i 's#output_buffering =.*#output_buffering = On#' ${php_setup_path}/etc/php.ini
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/; cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/g'${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    
	mkdir -p /usr/local/zend/php52
	wget -O /usr/local/zend/php52/ZendOptimizer.so ${Download_Url}/src/ZendOptimizer-${Is_64bit}.so -T 20
	
	mysqli='';
	if [ -f ${php_setup_path}/lib/php/extensions/no-debug-non-zts-20060613/mysqli.so ];then
		mysqli="extension=mysqli.so";
	fi

    cat >>${php_setup_path}/etc/php.ini<<EOF
$mysqli
;eaccelerator

;ionCube

[Zend Optimizer]
zend_optimizer.optimization_level=1
zend_extension="/usr/local/zend/php52/ZendOptimizer.so"

;xcache

EOF

	if [ "${apacheVersion}" != '2.2' ];then
		rm -f ${php_setup_path}/etc/php-fpm.conf
		wget -O ${php_setup_path}/etc/php-fpm.conf ${Download_Url}/conf/php-fpm5.2.conf -T20
		wget -O /etc/init.d/php-fpm-52 ${Download_Url}/init/php_fpm_52.init -T20
		chmod +x /etc/init.d/php-fpm-52
		chkconfig --add php-fpm-52
		chkconfig --level 2345 php-fpm-52 on
		service php-fpm-52 start
	else
		if [ ! -f /www/server/php/52/libphp5.so ];then
			\cp -a -r $Root_Path/server/apache/modules/libphp5.so /www/server/php/52/libphp5.so
			sed -i '/#LoadModule php5_module/s/^#//' /www/server/apache/conf/httpd.conf
		fi
		/etc/init.d/httpd restart
	fi
	rm -f ${php_setup_path}/src.tar.gz	
}

Install_PHP_53()
{
	cd ${run_path}
	php_version="53"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-5.3.29.tar.gz
	fi
    
    tar zxf src.tar.gz
	mv php-5.3.29 src
	cd src
	
	rm -rf /patch
	mkdir -p /patch
	wget -O /patch/php-5.3-multipart-form-data.patch ${Download_Url}/src/patch/php-5.3-multipart-form-data.patch -T20
    patch -p1 < /patch/php-5.3-multipart-form-data.patch
	if [ "${apacheVersion}" != '2.2' ];then
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo
	else
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --with-apxs2=$Root_Path/server/apache/bin/apxs --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-magic-quotes --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo
	fi
	make ZEND_EXTRA_LIBS='-liconv'
    make install
	
	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-5.3 installation failed.\033[0m";
		exit 0;
	fi

    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini
	
	cd ${run_path}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
    sed -i 's/register_long_arrays =.*/;register_long_arrays = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/magic_quotes_gpc =.*/;magic_quotes_gpc = On/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 5.3..."
	mkdir -p /usr/local/zend/php53
    if [ "${Is_64bit}" = "64" ] ; then
        wget ${Download_Url}/src/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
        tar zxf ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
        \cp ZendGuardLoader-php-5.3-linux-glibc23-x86_64/php-5.3.x/ZendGuardLoader.so /usr/local/zend/php53/
		rm -f ${run_path}/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz
		rm -rf ${run_path}/ZendGuardLoader-php-5.3-linux-glibc23-x86_64
    else
        wget ${Download_Url}/src/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
        tar zxf ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
        \cp ZendGuardLoader-php-5.3-linux-glibc23-i386/php-5.3.x/ZendGuardLoader.so /usr/local/zend/php53/
		rm -rf ZendGuardLoader-php-5.3-linux-glibc23-i386
		rm -f ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz
    fi
	

    echo "Write ZendGuardLoader to php.ini..."
    cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/php53/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache

EOF
if [ "${apacheVersion}" != '2.2' ];then
    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-53.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_53_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
Set_PHP_FPM_Opt
	
    \cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-53
	chmod +x /etc/init.d/php-fpm-53
	
	chkconfig --add php-fpm-53
	chkconfig --level 2345 php-fpm-53 on
	/etc/init.d/php-fpm-53 start
else
	if [ ! -f /www/server/php/53/libphp5.so ];then
		\cp -a -r $Root_Path/server/apache/modules/libphp5.so /www/server/php/53/libphp5.so
		sed -i '/#LoadModule php5_module/s/^#//' /www/server/apache/conf/httpd.conf
	fi
	/etc/init.d/httpd restart
fi
	rm -f ${php_setup_path}src.tar.gz
}


Install_PHP_54()
{
	cd ${run_path}
	php_version="54"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	
	mkdir -p ${php_setup_path}
    rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-5.4.45.tar.gz -T20
	fi
	
    tar zxf src.tar.gz
	mv php-5.4.45 src
	cd src
	if [ "${apacheVersion}" != '2.2' ];then
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-intl
	else
		./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --with-apxs2=$Root_Path/server/apache/bin/apxs --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-intl --with-xsl
	fi
	make ZEND_EXTRA_LIBS='-liconv'
    make install

	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-5.4 installation failed.\033[0m";
		exit 0;
	fi
	
    Ln_PHP_Bin

    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini
	cd ${php_setup_path}
    # php extensions
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer
	
	mkdir -p /usr/local/zend/php54
    if [ "${Is_64bit}" = "64" ] ; then
        wget ${Download_Url}/src/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz -T20
        tar zxf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz
        \cp ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64/php-5.4.x/ZendGuardLoader.so /usr/local/zend/php54/
		rm -rf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64
		rm -f ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz
    else
        wget ${Download_Url}/src/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz -T20
        tar zxf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz
        \cp ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386/php-5.4.x/ZendGuardLoader.so /usr/local/zend/php54/
		rm -rf ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386
		rm -f ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/php54/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache

EOF

if [ "${apacheVersion}" != '2.2' ];then
    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-54.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_54_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
	Set_PHP_FPM_Opt
    \cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-54
    chmod +x /etc/init.d/php-fpm-54
	
	chkconfig --add php-fpm-54
	chkconfig --level 2345 php-fpm-54 on
	rm -f /tmp/php-cgi-54.sock
	/etc/init.d/php-fpm-54 start
else
	if [ ! -f /www/server/php/54/libphp5.so ];then
		\cp -a -r $Root_Path/server/apache/modules/libphp5.so /www/server/php/54/libphp5.so
		sed -i '/#LoadModule php5_module/s/^#//' /www/server/apache/conf/httpd.conf
	fi
	/etc/init.d/httpd restart
fi
	rm -f ${php_setup_path}/src.tar.gz
}

Install_PHP_55()
{
	cd ${run_path}
	php_version="55"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-${php_55}.tar.gz -T20
	fi
    
    tar zxf src.tar.gz
	mv php-${php_55} src
	cd src
	./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl
	make ZEND_EXTRA_LIBS='-liconv'
    make install
	
	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-5.5 installation failed.\033[0m";
		exit 0;
	fi
	
    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini

    cd ${php_setup_path}
    # php extensions
    echo "Modify php.ini..."
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 5.5..."
    mkdir -p /usr/local/zend/php55
    if [ "${Is_64bit}" = "64" ] ; then
        wget ${Download_Url}/src/zend-loader-php5.5-linux-x86_64.tar.gz -T20
        tar zxf zend-loader-php5.5-linux-x86_64.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.5-linux-x86_64/ZendGuardLoader.so /usr/local/zend/php55/
		rm -rf zend-loader-php5.5-linux-x86_64
		rm -f zend-loader-php5.5-linux-x86_64.tar.gz
    else
        wget ${Download_Url}/src/zend-loader-php5.5-linux-i386.tar.gz
        tar zxf zend-loader-php5.5-linux-i386.tar.gz
        mkdir -p /usr/local/zend/
        \cp zend-loader-php5.5-linux-i386/ZendGuardLoader.so /usr/local/zend/php55/
		rm -rf zend-loader-php5.5-linux-i386
		rm -f zend-loader-php5.5-linux-i386.tar.gz
    fi

    echo "Write ZendGuardLoader to php.ini..."
    cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/php55/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache

EOF

    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-55.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_55_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
Set_PHP_FPM_Opt
    echo "Copy php-fpm init.d file..."
    \cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-55
    chmod +x /etc/init.d/php-fpm-55
	
	chkconfig --add php-fpm-55
	chkconfig --level 2345 php-fpm-55 on
	rm -f /tmp/php-cgi-55.sock
	/etc/init.d/php-fpm-55 start
	rm -f ${php_setup_path}/src.tar.gz
}

Install_PHP_56()
{
	cd ${run_path}
	php_version="56"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-${php_56}.tar.gz -T20
	fi
    
    tar zxf src.tar.gz
	mv php-${php_56} src
	cd src
	./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache --enable-intl

    make ZEND_EXTRA_LIBS='-liconv'
    make install

	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-5.6 installation failed.\033[0m";
		rm -rf ${php_setup_path}
		exit 0;
	fi
	
    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini

    cd ${php_setup_path}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;openssl.cafile=/openssl.cafile=\/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
	sed -i 's/;curl.cainfo =/curl.cainfo = \/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 5.6..."
    mkdir -p /usr/local/zend/php56
    if [ "${Is_64bit}" = "64" ] ; then
        wget ${Download_Url}/src/zend-loader-php5.6-linux-x86_64.tar.gz -T20
        tar zxf zend-loader-php5.6-linux-x86_64.tar.gz
        \cp zend-loader-php5.6-linux-x86_64/ZendGuardLoader.so /usr/local/zend/php56/
		rm -rf zend-loader-php5.6-linux-x86_64
		rm -f zend-loader-php5.6-linux-x86_64.tar.gz
    else
        wget ${Download_Url}/src/zend-loader-php5.6-linux-i386.tar.gz -T20
        tar zxf zend-loader-php5.6-linux-i386.tar.gz
        \cp zend-loader-php5.6-linux-i386/ZendGuardLoader.so /usr/local/zend/php56/
		rm -rf zend-loader-php5.6-linux-i386
		rm -f zend-loader-php5.6-linux-i386.tar.gz
    fi

    echo "Write ZendGuardLoader to php.ini..."
cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
zend_extension=/usr/local/zend/php56/ZendGuardLoader.so
zend_loader.enable=1
zend_loader.disable_licensing=0
zend_loader.obfuscation_level_support=3
zend_loader.license_path=

;xcache

EOF

    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-56.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_56_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
Set_PHP_FPM_Opt
    echo "Copy php-fpm init.d file..."
    \cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-56
    chmod +x /etc/init.d/php-fpm-56
	
	chkconfig --add php-fpm-56
	chkconfig --level 2345 php-fpm-56 on
	rm -f /tmp/php-cgi-56.sock
	/etc/init.d/php-fpm-56 start
	rm -f ${php_setup_path}/src.tar.gz
}

Install_PHP_70()
{
	cd ${run_path}
	php_version="70"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-${php_70}.tar.gz -T20
	fi
    
    tar zxf src.tar.gz
	mv php-${php_70} src
	cd src
	./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache
    make ZEND_EXTRA_LIBS='-liconv'
    make install

	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-7.0 installation failed.\033[0m";
		rm -rf ${php_setup_path}
		exit 0;
	fi
	
    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini

    cd ${php_setup_path}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;openssl.cafile=/openssl.cafile=\/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
	sed -i 's/;curl.cainfo =/curl.cainfo = \/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 7..."
    echo "unavailable now."

    echo "Write ZendGuardLoader to php.ini..."
cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
;php7 do not support zendguardloader @Sep.2015,after support you can uncomment the following line.
;zend_extension=/usr/local/zend/php70/ZendGuardLoader.so
;zend_loader.enable=1
;zend_loader.disable_licensing=0
;zend_loader.obfuscation_level_support=3
;zend_loader.license_path=

;xcache

EOF

    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-70.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_70_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
Set_PHP_FPM_Opt
	\cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-70
    chmod +x /etc/init.d/php-fpm-70
	
	chkconfig --add php-fpm-70
	chkconfig --level 2345 php-fpm-70 on
	rm -f /tmp/php-cgi-70.sock
	/etc/init.d/php-fpm-70 start
	rm -f ${php_setup_path}/src.tar.gz
}


Install_PHP_71()
{
	cd ${run_path}
	php_version="71"
	/etc/init.d/php-fpm-$php_version stop
	php_setup_path=${php_path}/${php_version}
	
	mkdir -p ${php_setup_path}
	rm -rf ${php_setup_path}/*
	cd ${php_setup_path}
	if [ ! -f "${php_setup_path}/src.tar.gz" ];then
		wget -O ${php_setup_path}/src.tar.gz ${Download_Url}/src/php-${php_71}.tar.gz -T20
	fi
    
    tar zxf src.tar.gz
	mv php-${php_71} src
	cd src
	./configure --prefix=${php_setup_path} --with-config-file-path=${php_setup_path}/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www --enable-mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-iconv-dir --with-freetype-dir=/usr/local/freetype --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl=/usr/local/curl --enable-mbregex --enable-mbstring --enable-intl --enable-pcntl --with-mcrypt --enable-ftp --with-gd --enable-gd-native-ttf --with-openssl=/usr/local/openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --with-gettext --disable-fileinfo --enable-opcache
    make ZEND_EXTRA_LIBS='-liconv'
    make install

	if [ ! -f "${php_setup_path}/bin/php" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: php-7.1 installation failed.\033[0m";
		rm -rf ${php_setup_path}
		exit 0;
	fi
	
    Ln_PHP_Bin

    echo "Copy new php configure file..."
    mkdir -p ${php_setup_path}/etc
    \cp php.ini-production ${php_setup_path}/etc/php.ini

    cd ${php_setup_path}
    # php extensions
    echo "Modify php.ini......"
    sed -i 's/post_max_size =.*/post_max_size = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/upload_max_filesize =.*/upload_max_filesize = 50M/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;date.timezone =.*/date.timezone = PRC/g' ${php_setup_path}/etc/php.ini
    sed -i 's/short_open_tag =.*/short_open_tag = On/g' ${php_setup_path}/etc/php.ini
    sed -i 's/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=1/g' ${php_setup_path}/etc/php.ini
    sed -i 's/max_execution_time =.*/max_execution_time = 300/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;sendmail_path =.*/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' ${php_setup_path}/etc/php.ini
	sed -i 's/;openssl.cafile=/openssl.cafile=\/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
	sed -i 's/;curl.cainfo =/curl.cainfo = \/etc\/pki\/tls\/certs\/ca-bundle.crt/' ${php_setup_path}/etc/php.ini
    sed -i 's/disable_functions =.*/disable_functions = passthru,exec,system,chroot,chgrp,chown,shell_exec,popen,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru/g' ${php_setup_path}/etc/php.ini
    sed -i 's/display_errors = Off/display_errors = On/g' ${php_setup_path}/etc/php.ini
    Pear_Pecl_Set
    Install_Composer

    echo "Install ZendGuardLoader for PHP 7..."
    echo "unavailable now."

    echo "Write ZendGuardLoader to php.ini..."
cat >>${php_setup_path}/etc/php.ini<<EOF

;eaccelerator

;ionCube

;opcache

[Zend ZendGuard Loader]
;php7 do not support zendguardloader @Sep.2015,after support you can uncomment the following line.
;zend_extension=/usr/local/zend/php71/ZendGuardLoader.so
;zend_loader.enable=1
;zend_loader.disable_licensing=0
;zend_loader.obfuscation_level_support=3
;zend_loader.license_path=

;xcache

EOF

    cat >${php_setup_path}/etc/php-fpm.conf<<EOF
[global]
pid = ${php_setup_path}/var/run/php-fpm.pid
error_log = ${php_setup_path}/var/log/php-fpm.log
log_level = notice

[www]
listen = /tmp/php-cgi-71.sock
listen.backlog = -1
listen.allowed_clients = 127.0.0.1
listen.owner = www
listen.group = www
listen.mode = 0666
user = www
group = www
pm = dynamic
pm.status_path = /phpfpm_71_status
pm.max_children = 20
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 6
request_terminate_timeout = 100
request_slowlog_timeout = 30
slowlog = var/log/slow.log
EOF
Set_PHP_FPM_Opt
	\cp ${php_setup_path}/src/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm-71
    chmod +x /etc/init.d/php-fpm-71
	
	chkconfig --add php-fpm-71
	chkconfig --level 2345 php-fpm-71 on
	rm -f /tmp/php-cgi-71.sock
	/etc/init.d/php-fpm-71 start
	if [ -d "$Root_Path/server/nginx" ];then
		wget -O $Root_Path/server/nginx/conf/enable-php-71.conf ${Download_Url}/conf/enable-php-71.conf -T20
	fi
	rm -f ${php_setup_path}/src.tar.gz
}


SetPHPMyAdmin()
{
    PHPVersion=""
    if [ -f "$Root_Path/server/php/52/bin/php" ];then
        PHPVersion="52"
    fi
    if [ -f "$Root_Path/server/php/53/bin/php" ];then
        PHPVersion="53"
    fi
    if [ -f "$Root_Path/server/php/54/bin/php" ];then
        PHPVersion="54"
    fi
    if [ -f "$Root_Path/server/php/55/bin/php" ];then
        PHPVersion="55"
    fi
    if [ -f "$Root_Path/server/php/56/bin/php" ];then
        PHPVersion="56"
    fi
    if [ -f "$Root_Path/server/php/70/bin/php" ];then
        PHPVersion="70"
    fi
    if [ -f "$Root_Path/server/php/71/bin/php" ];then
        PHPVersion="71"
    fi
    
    if [ "${webserver}" == "nginx" ];then
        sed -i "s#$Root_Path/wwwroot/default#$Root_Path/server/phpmyadmin#" $Root_Path/server/nginx/conf/nginx.conf
        rm -f $Root_Path/server/nginx/conf/enable-php.conf
        \cp $Root_Path/server/nginx/conf/enable-php-$PHPVersion.conf $Root_Path/server/nginx/conf/enable-php.conf
        sed -i "/pathinfo/d" $Root_Path/server/nginx/conf/enable-php.conf
        /etc/init.d/nginx reload
    else
        sed -i "s#$Root_Path/wwwroot/default#$Root_Path/server/phpmyadmin#" $Root_Path/server/apache/conf/extra/httpd-vhosts.conf
        sed -i "0,/php-cgi/ s/php-cgi-\w*\.sock/php-cgi-${PHPVersion}.sock/" $Root_Path/server/apache/conf/extra/httpd-vhosts.conf
        /etc/init.d/httpd reload
    fi
}

Uninstall_PHP()
{
	php_version=${1/./}
	service php-fpm-$php_version stop
	chkconfig --del php-fpm-$php_version
	rm -rf $php_path/$php_version
	rm -f /etc/init.d/php-fpm-$php_version

    if [ -f "$Root_Path/server/phpmyadmin/version.pl" ];then
        SetPHPMyAdmin
    fi
}


Install_OpenSSL()
{
	if [ ! -f /usr/local/openssl/version.pl ];then
		cd ${run_path}
		wget ${Download_Url}/src/openssl-1.0.2l.tar.gz -T 20
		tar xvf openssl-1.0.2l.tar.gz
		rm -f openssl-1.0.2l.tar.gz
		cd openssl-1.0.2l
		./config --prefix=/usr/local/openssl
		make && make install
		echo '1.0.2l' > /usr/local/openssl/version.pl
		cd ..
		rm -rf openssl-1.0.2l
	fi
}

actionType=$1
version=$2

if [ "$actionType" == 'install' ];then
	Install_OpenSSL
	case "$version" in
		'5.2')
			Install_PHP_52
			;;
		'5.3')
			Install_PHP_53
			;;
		'5.4')
			Install_PHP_54
			;;
		'5.5')
			Install_PHP_55
			;;
		'5.6')
			Install_PHP_56
			;;
		'7.0')
			Install_PHP_70
			;;
		'7.1')
			Install_PHP_71
			;;
	esac
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_PHP $version
fi
