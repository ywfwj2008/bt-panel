#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
CN='125.88.182.172'
HK='103.224.251.79'
HK2='103.224.251.67'
US='128.1.164.196'

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
Setup_Path=$Root_Path/server/nginx
run_path='/root'

Install_Lua()
{
	if [ ! -f '/usr/local/bin/lua' ];then
		yum install libtermcap-devel ncurses-devel libevent-devel readline-devel -y
		wget -c -O lua-5.3.4.tar.gz $Download_Url/install/src/lua-5.3.4.tar.gz -T 5
		tar xvf lua-5.3.4.tar.gz
		cd lua-5.3.4
		make linux
		make install
		cd ..
		rm -rf lua-*
	fi
}

Install_LuaJIT()
{
	if [ ! -d '/usr/local/include/luajit-2.0' ];then
		yum install libtermcap-devel ncurses-devel libevent-devel readline-devel -y
		wget -c -O LuaJIT-2.0.4.tar.gz $Download_Url/install/src/LuaJIT-2.0.4.tar.gz -T 5
		tar xvf LuaJIT-2.0.4.tar.gz
		cd LuaJIT-2.0.4
		make linux
		make install
		cd ..
		rm -rf LuaJIT-*
		export LUAJIT_LIB=/usr/local/lib
		export LUAJIT_INC=/usr/local/include/luajit-2.0/
		ln -sf /usr/local/lib/libluajit-5.1.so.2 /usr/local/lib64/libluajit-5.1.so.2
		echo "/usr/local/lib" >> /etc/ld.so.conf
		ldconfig
	fi
}

Install_Nginx()
{
	cd ${run_path}
	Run_User="www"
    groupadd ${Run_User}
    useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
	service nginx stop
	mkdir -p ${Setup_Path}
	rm -rf ${Setup_Path}/*
	cd ${Setup_Path}
	if [ ! -f "${Setup_Path}/src.tar.gz" ];then
		if [ "$nginx_version" == "openresty" ];then
			wget -O ${Setup_Path}/src.tar.gz ${Download_Url}/src/openresty-1.11.2.3.tar.gz -T20
		else
			wget -O ${Setup_Path}/src.tar.gz ${Download_Url}/src/nginx-$nginxVersion.tar.gz -T20
		fi
	fi
	tar -zxvf src.tar.gz
	if [ "${nginxVersion}" == '-Tengine2.2.0' ];then
		mv tengine-2.2.0 src
	elif [ "${nginxVersion}" == 'openresty' ];then
		mv openresty-1.11.2.3 src
	else
		mv nginx-$nginxVersion src
	fi
	cd src
	
	wget -O openssl.tar.gz ${Download_Url}/src/openssl-1.0.2l.tar.gz -T 5
	tar -xvf openssl.tar.gz
	mv openssl-1.0.2l openssl
	rm -f openssl.tar.gz
	
	export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH 
	if [ "${nginxVersion}" != "1.8.1" ];then
		if [ "${nginx_version}" == "1.12.1" ];then
			Install_LuaJIT
			#lua_nginx_module
			wget -c -O lua-nginx-module-master.zip $Download_Url/install/src/lua-nginx-module-master.zip -T 5
			unzip lua-nginx-module-master.zip
			mv lua-nginx-module-master lua_nginx_module
			rm -f lua-nginx-module-master.zip
			
			#ngx_devel_kit
			wget -c -O ngx_devel_kit-master.zip $Download_Url/install/src/ngx_devel_kit-master.zip -T 5
			unzip ngx_devel_kit-master.zip
			mv ngx_devel_kit-master ngx_devel_kit
			rm -f ngx_devel_kit-master.zip
			./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E"
		else
			if [ "$nginx_version" == "openresty" ];then
				Install_LuaJIT
				./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --with-luajit --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E"
			else
				./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E"
			fi
		fi
    else
		./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --with-http_stub_status_module --with-http_ssl_module --with-http_spdy_module --with-http_gzip_static_module --with-http_gunzip_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E"
	fi
	if [ "$nginx_version" == "openresty" ];then
		gmake && gmake install
		ln -sf /www/server/nginx/nginx/html /www/server/nginx/html
		ln -sf /www/server/nginx/nginx/conf /www/server/nginx/conf
		ln -sf /www/server/nginx/nginx/logs /www/server/nginx/logs
		ln -sf /www/server/nginx/nginx/sbin /www/server/nginx/sbin
	else
		make && make install
	fi
	cd ../
	if [ ! -f "${Setup_Path}/sbin/nginx" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: nginx-${nginxVersion} installation failed.\033[0m";
		rm -rf ${Setup_Path}
		exit 0;
	fi
	
    ln -sf ${Setup_Path}/sbin/nginx /usr/bin/nginx
    rm -f ${Setup_Path}/conf/nginx.conf

    wget -O ${Setup_Path}/conf/nginx.conf ${Download_Url}/conf/nginx.conf -T20
    wget -O ${Setup_Path}/conf/pathinfo.conf ${Download_Url}/conf/pathinfo.conf -T20
    wget -O ${Setup_Path}/conf/enable-php.conf ${Download_Url}/conf/enable-php.conf -T20
    wget -O ${Setup_Path}/conf/enable-php-52.conf ${Download_Url}/conf/enable-php-52.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-53.conf ${Download_Url}/conf/enable-php-53.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-54.conf ${Download_Url}/conf/enable-php-54.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-55.conf ${Download_Url}/conf/enable-php-55.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-56.conf ${Download_Url}/conf/enable-php-56.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-70.conf ${Download_Url}/conf/enable-php-70.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-71.conf ${Download_Url}/conf/enable-php-71.conf -T20
	ln -s /usr/local/lib/libpcre.so.1 /lib64/
	ln -s /usr/local/lib/libpcre.so.1 /lib/
	sed -i "s#include vhost/\*.conf;#include /www/server/panel/vhost/nginx/\*.conf;#" ${Setup_Path}/conf/nginx.conf
	sed -i "s#/www/wwwroot/default#/www/server/phpmyadmin#" ${Setup_Path}/conf/nginx.conf
	sed -i "/pathinfo/d" ${Setup_Path}/conf/enable-php.conf
	
	Default_Website_Dir=$Root_Path'/wwwroot/default'
    mkdir -p ${Default_Website_Dir}
    chmod +w ${Default_Website_Dir}
    mkdir -p $Root_Path/wwwlogs
    chmod 777 $Root_Path/wwwlogs

    chown -R ${Run_User}:${Run_User} ${Default_Website_Dir}
    mkdir -p ${Setup_Path}/conf/vhost
	
	mkdir -p /usr/local/nginx/logs
	mkdir -p ${Setup_Path}/conf/rewrite
	wget -O ${Setup_Path}/html/index.html ${Download_Url}/error/index.html -T 5
    wget -O /etc/init.d/nginx ${Download_Url}/init/nginx.init -T 5
    chmod +x /etc/init.d/nginx
	
	chkconfig --add nginx
	chkconfig --level 2345 nginx on
	
	
	cat > $Root_Path/server/panel/vhost/nginx/phpfpm_status.conf<<EOF
server {
	listen 80;
	server_name 127.0.0.1;
	allow 127.0.0.1;
	location /nginx_status {
		stub_status on;
		access_log off;
	}
	location /phpfpm_52_status {
		fastcgi_pass unix:/tmp/php-cgi-52.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_53_status {
		fastcgi_pass unix:/tmp/php-cgi-53.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_54_status {
		fastcgi_pass unix:/tmp/php-cgi-54.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_55_status {
		fastcgi_pass unix:/tmp/php-cgi-55.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_56_status {
		fastcgi_pass unix:/tmp/php-cgi-56.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_70_status {
		fastcgi_pass unix:/tmp/php-cgi-70.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_71_status {
		fastcgi_pass unix:/tmp/php-cgi-71.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
}
EOF


	#cat > ${Setup_Path}/conf/vhost/default.conf<<EOF
#server {
#	listen 80 default_server;
#	server_name _;
#	root $Setup_Path/html;
#}
#EOF


cat > ${Setup_Path}/conf/proxy.conf<<EOF
proxy_temp_path ${Setup_Path}/proxy_temp_dir;
proxy_cache_path ${Setup_Path}/proxy_cache_dir levels=1:2 keys_zone=cache_one:20m inactive=1d max_size=5g;
client_body_buffer_size 512k;
proxy_connect_timeout 60;
proxy_read_timeout 60;
proxy_send_timeout 60;
proxy_buffer_size 32k;
proxy_buffers 4 64k;
proxy_busy_buffers_size 128k;
proxy_temp_file_write_size 128k;
proxy_next_upstream error timeout invalid_header http_500 http_503 http_404;
proxy_cache cache_one;
EOF

cat > ${Setup_Path}/conf/luawaf.conf<<EOF
lua_shared_dict limit 10m;
lua_package_path "/www/server/nginx/waf/?.lua";
init_by_lua_file  /www/server/nginx/waf/init.lua;
access_by_lua_file /www/server/nginx/waf/waf.lua;
EOF
	
	rm -f ${Setup_Path}/conf/vhost/default.conf
	mkdir -p /www/wwwlogs/waf
	chown www.www /www/wwwlogs/waf
	chmod 744 /www/wwwlogs/waf
	mkdir -p /www/server/panel/vhost
	wget -O waf.zip $Download_Url/install/waf/waf.zip
	unzip -o waf.zip -d $Setup_Path/ > /dev/null
	if [ ! -d "/www/server/panel/vhost/wafconf" ];then
		mv $Setup_Path/waf/wafconf /www/server/panel/vhost/wafconf
	fi
	cd ${Setup_Path}
	rm -f src.tar.gz
	CheckPHPVersion
	sed -i "s/#limit_conn_zone.*/limit_conn_zone \$binary_remote_addr zone=perip:10m;\n\tlimit_conn_zone \$server_name zone=perserver:10m;/" ${Setup_Path}/conf/nginx.conf
	if [ "${nginx_version}" == "1.12.1" ] || [ "${nginx_version}" == "openresty" ];then
		sed -i "s/mime.types;/mime.types;\n\tinclude proxy.conf;\n\t#include luawaf.conf;\n/" ${Setup_Path}/conf/nginx.conf
	fi
	
	/etc/init.d/nginx start
	echo "${nginxVersion}" > ${Setup_Path}/version.pl
}

CheckPHPVersion()
{
	PHPVersion=""
	if [ -d "/www/server/php/52" ];then
		PHPVersion="52"
	fi
	if [ -d "/www/server/php/53" ];then
		PHPVersion="53"
	fi
	if [ -d "/www/server/php/54" ];then
		PHPVersion="54"
	fi
	if [ -d "/www/server/php/55" ];then
		PHPVersion="55"
	fi
	if [ -d "/www/server/php/56" ];then
		PHPVersion="56"
	fi
	if [ -d "/www/server/php/70" ];then
		PHPVersion="70"
	fi
	if [ -d "/www/server/php/71" ];then
		PHPVersion="71"
	fi
	if [ "${PHPVersion}" != '' ];then
		\cp -r -a ${Setup_Path}/conf/enable-php-${PHPVersion}.conf ${Setup_Path}/conf/enable-php.conf
	fi
}

Uninstall_Nginx()
{
	service nginx stop
	pkill -9 nginx
	rm -rf $Setup_Path
	chkconfig --del nginx
	rm -f /etc/init.d/nginx
}

actionType=$1
version=$2
if [ "$actionType" == 'install' ];then
	nginxVersion='-Tengine2.2.0'
	if [ "$version" == "1.10" ] || [ "$version" == "1.12" ];then
		nginxVersion='1.12.1'
		nginx_version='1.12.1'
	elif [ "$version" == "1.8" ];then
		nginxVersion='1.8.1'
	elif [ "$version" == "openresty" ];then
		nginxVersion="openresty"
		nginx_version="openresty"
	fi
	Install_Nginx
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Nginx
fi
