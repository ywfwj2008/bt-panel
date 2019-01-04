#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8
public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL

Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/nginx
run_path='/root'

cpuInfo=$(getconf _NPROCESSORS_ONLN)
if [ "${cpuInfo}" -ge "4" ];then
	cpuCore=$((${cpuInfo}-1))
else
	cpuCore="1"
fi

Install_Jemalloc(){
	if [ ! -f '/usr/local/lib/libjemalloc.so' ]; then
		wget -O jemalloc-5.0.1.tar.bz2 ${download_Url}/src/jemalloc-5.0.1.tar.bz2
		tar -xvf jemalloc-5.0.1.tar.bz2
		cd jemalloc-5.0.1
		./configure
		make && make install
		ldconfig
		cd ..
		rm -rf jemalloc*
	fi
}
Install_Lua()
{
	if [ ! -f '/usr/local/bin/lua' ];then
		yum install libtermcap-devel ncurses-devel libevent-devel readline-devel -y
		wget -c -O lua-5.3.4.tar.gz ${download_Url}/install/src/lua-5.3.4.tar.gz -T 5
		tar xvf lua-5.3.4.tar.gz
		cd lua-5.3.4
		make linux
		make install
		cd ..
		rm -rf lua-*
	fi
}
Install_cjson()
{
	if [ ! -f /usr/local/lib/lua/5.1/cjson.so ];then
		wget -O lua-cjson-2.1.0.tar.gz $download_Url/install/src/lua-cjson-2.1.0.tar.gz -T 20
		tar xvf lua-cjson-2.1.0.tar.gz
		rm -f lua-cjson-2.1.0.tar.gz
		cd lua-cjson-2.1.0
		make
		make install
		cd ..
		rm -rf lua-cjson-2.1.0
	fi
}
Install_LuaJIT()
{
	if [ ! -d '/usr/local/include/luajit-2.0' ];then
		yum install libtermcap-devel ncurses-devel libevent-devel readline-devel -y
		wget -c -O LuaJIT-2.0.4.tar.gz ${download_Url}/install/src/LuaJIT-2.0.4.tar.gz -T 5
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
Download_Src(){
	if [ "${nginxVersion}" == "1.15.6" ]; then
		opensslVer="1.1.1"
	else
		opensslVer="1.0.2l"
	fi
	wget -O openssl.tar.gz ${download_Url}/src/openssl-${opensslVer}.tar.gz -T 5
	tar -xvf openssl.tar.gz
	mv openssl-${opensslVer} openssl
	rm -f openssl.tar.gz

	pcre_version=8.40
    wget -O pcre-$pcre_version.tar.gz ${download_Url}/src/pcre-$pcre_version.tar.gz -T 5
	tar zxf pcre-$pcre_version.tar.gz

	wget -O ngx_cache_purge.tar.gz ${download_Url}/src/ngx_cache_purge-2.3.tar.gz
	tar -zxvf ngx_cache_purge.tar.gz
	mv ngx_cache_purge-2.3 ngx_cache_purge
	rm -f ngx_cache_purge.tar.gz

	wget -O nginx-sticky-module.zip ${download_Url}/src/nginx-sticky-module.zip
	unzip nginx-sticky-module.zip
	rm -f nginx-sticky-module.zip

	wget -O nginx-http-concat.zip ${download_Url}/src/nginx-http-concat-1.2.2.zip
	unzip nginx-http-concat.zip
	mv nginx-http-concat-1.2.2 nginx-http-concat
	rm -f nginx-http-concat.zip

	#lua_nginx_module
	LuaModVer="0.10.13"
	wget -c -O lua-nginx-module-${LuaModVer}.zip ${download_Url}/src/lua-nginx-module-${LuaModVer}.zip -T 5
	unzip lua-nginx-module-${LuaModVer}.zip
	mv lua-nginx-module-${LuaModVer} lua_nginx_module
	rm -f lua-nginx-module-${LuaModVer}.zip
	
	#ngx_devel_kit
	NgxDevelKitVer="0.3.1rc1"
	wget -c -O ngx_devel_kit-${NgxDevelKitVer}.zip ${download_Url}/src/ngx_devel_kit-${NgxDevelKitVer}.zip -T 5
	unzip ngx_devel_kit-${NgxDevelKitVer}.zip
	mv ngx_devel_kit-${NgxDevelKitVer} ngx_devel_kit
	rm -f ngx_devel_kit-${NgxDevelKitVer}.zip	
}

Install_Nginx()
{
	Uninstall_Nginx
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
			wget -O ${Setup_Path}/src.tar.gz ${download_Url}/src/openresty-${openresty_version}.tar.gz -T20
		else
			wget -O ${Setup_Path}/src.tar.gz ${download_Url}/src/nginx-$nginxVersion.tar.gz -T20
		fi
	fi
	tar -zxvf src.tar.gz
	if [ "${nginxVersion}" == '-Tengine2.2.3' ];then
		tar -xvf src.tar.gz
		mv tengine-2.2.3 src
	elif [ "${nginxVersion}" == 'openresty' ];then
		mv openresty-${openresty_version} src
	else
		mv nginx-$nginxVersion src
	fi

	cd src
	Download_Src
	Install_cjson
	Install_LuaJIT

	if [ -f "/usr/local/lib/libjemalloc.so" ]; then
		jemallocLD="--with-ld-opt="-ljemalloc""
	else
		jemallocLD=""
	fi

	export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH 
	if [ "${nginxVersion}" != "1.8.1" ];then
		if [ "${nginx_version}" == "1.14.2" ] || [ "${nginx_version}" == "1.12.2" ];then
			./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --add-module=${Setup_Path}/src/nginx-http-concat --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --with-pcre=pcre-${pcre_version} ${jemallocLD}
		elif [ "${nginxVersion}" == "1.15.6" ]; then
			./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --with-openssl-opt="enable-tls1_3 enable-weak-ssl-ciphers" ${jemallocLD}
		else
			if [ "$nginx_version" == "openresty" ];then
				./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --with-pcre=pcre-${pcre_version} --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --add-module=${Setup_Path}/src/nginx-http-concat --with-luajit --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" ${jemallocLD}
			else
				./configure --user=www --group=www --prefix=${Setup_Path} --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-http_concat_module --with-ld-opt="-Wl,-E" --without-http_upstream_session_sticky_module --with-pcre=pcre-${pcre_version}
			fi
		fi
    else
		./configure --user=www --group=www --prefix=${Setup_Path} --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --add-module=${Setup_Path}/src/nginx-http-concat --with-http_stub_status_module --with-http_ssl_module --with-http_image_filter_module --with-http_spdy_module --with-http_gzip_static_module --with-http_gunzip_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --with-pcre=pcre-${pcre_version} ${jemallocLD}
	fi
	if [ "$nginx_version" == "openresty" ];then
		gmake && gmake install
		ln -sf /www/server/nginx/nginx/html /www/server/nginx/html
		ln -sf /www/server/nginx/nginx/conf /www/server/nginx/conf
		ln -sf /www/server/nginx/nginx/logs /www/server/nginx/logs
		ln -sf /www/server/nginx/nginx/sbin /www/server/nginx/sbin
	else
		make -j${cpuCore} && make install
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

    wget -O ${Setup_Path}/conf/nginx.conf ${download_Url}/conf/nginx.conf -T20
    wget -O ${Setup_Path}/conf/pathinfo.conf ${download_Url}/conf/pathinfo.conf -T20
    wget -O ${Setup_Path}/conf/enable-php.conf ${download_Url}/conf/enable-php.conf -T20
    wget -O ${Setup_Path}/conf/enable-php-52.conf ${download_Url}/conf/enable-php-52.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-53.conf ${download_Url}/conf/enable-php-53.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-54.conf ${download_Url}/conf/enable-php-54.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-55.conf ${download_Url}/conf/enable-php-55.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-56.conf ${download_Url}/conf/enable-php-56.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-70.conf ${download_Url}/conf/enable-php-70.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-71.conf ${download_Url}/conf/enable-php-71.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-72.conf ${download_Url}/conf/enable-php-72.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-73.conf ${download_Url}/conf/enable-php-73.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-74.conf ${download_Url}/conf/enable-php-74.conf -T20
	wget -O ${Setup_Path}/conf/enable-php-75.conf ${download_Url}/conf/enable-php-75.conf -T20
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
	wget -O ${Setup_Path}/html/index.html ${download_Url}/error/index.html -T 5
    wget -O /etc/init.d/nginx ${download_Url}/init/nginx.init -T 5
    chmod +x /etc/init.d/nginx
	
    if [ -f "/usr/bin/apt-get" ];then
    	update-rc.d nginx defaults
    else
    	chkconfig --add nginx
    	chkconfig --level 2345 nginx on
    fi
	
	
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
	location /phpfpm_72_status {
		fastcgi_pass unix:/tmp/php-cgi-72.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_73_status {
		fastcgi_pass unix:/tmp/php-cgi-73.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_74_status {
		fastcgi_pass unix:/tmp/php-cgi-74.sock;
		include fastcgi_params;
		fastcgi_param SCRIPT_FILENAME \$fastcgi_script_name;
	}
	location /phpfpm_75_status {
		fastcgi_pass unix:/tmp/php-cgi-75.sock;
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
client_body_buffer_size 25m;
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
	wget -O waf.zip ${download_Url}/install/waf/waf.zip
	unzip -o waf.zip -d $Setup_Path/ > /dev/null
	if [ ! -d "/www/server/panel/vhost/wafconf" ];then
		mv $Setup_Path/waf/wafconf /www/server/panel/vhost/wafconf
	fi
	cd ${Setup_Path}
	rm -f src.tar.gz
	CheckPHPVersion
	sed -i "s/#limit_conn_zone.*/limit_conn_zone \$binary_remote_addr zone=perip:10m;\n\tlimit_conn_zone \$server_name zone=perserver:10m;/" ${Setup_Path}/conf/nginx.conf
	sed -i "s/mime.types;/mime.types;\n\t\tinclude proxy.conf;\n/" ${Setup_Path}/conf/nginx.conf
	#if [ "${nginx_version}" == "1.12.2" ] || [ "${nginx_version}" == "openresty" ] || [ "${nginx_version}" == "1.14.2" ];then
	sed -i "s/mime.types;/mime.types;\n\t\t#include luawaf.conf;\n/" ${Setup_Path}/conf/nginx.conf
	#fi
	
	/etc/init.d/nginx start
	echo "${nginxVersion}" > ${Setup_Path}/version.pl
}
Update_nginx(){
	cd ${run_path}
	Update_Path=${Setup_Path}/update
	mkdir -p ${Update_Path}
	mkdir -p ${Update_Path}/*
	cd ${Update_Path}
	if [ "$nginx_version" == "openresty" ];then
		wget -O ${Update_Path}/src.tar.gz ${download_Url}/src/openresty-${openresty_version}.tar.gz -T20
	else
		wget -O ${Update_Path}/src.tar.gz ${download_Url}/src/nginx-$nginxVersion.tar.gz -T20
	fi
	tar -zxvf src.tar.gz

	if [ "${nginxVersion}" == '-Tengine2.2.3' ];then
		tar -xvf src.tar.gz
		mv tengine-2.2.3 src
	elif [ "${nginxVersion}" == 'openresty' ];then
		mv openresty-${openresty_version} src
	else
		mv nginx-$nginxVersion src
	fi

	cd src
	Download_Src
	Install_cjson
	Install_LuaJIT

	if [ -f "/usr/local/lib/libjemalloc.so" ]; then
		jemallocLD="--with-ld-opt="-ljemalloc""
	else
		jemallocLD=""
	fi

	export LD_LIBRARY_PATH=/usr/local/lib/:$LD_LIBRARY_PATH 
	if [ "${nginx_version}" == "1.12.2" ] || [ "${nginx_version}" == "1.14.2" ];then
		./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Update_Path}/src/openssl --add-module=${Update_Path}/src/ngx_devel_kit --add-module=${Update_Path}/src/lua_nginx_module --add-module=${Update_Path}/src/ngx_cache_purge --add-module=${Update_Path}/src/nginx-sticky-module --with-http_stub_status_module --with-http_ssl_module --with-http_image_filter_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --with-pcre=pcre-${pcre_version} ${jemallocLD}
	elif [ "${nginxVersion}" == "1.15.6" ]; then
		./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Setup_Path}/src/openssl --add-module=${Setup_Path}/src/ngx_devel_kit --add-module=${Setup_Path}/src/lua_nginx_module --add-module=${Setup_Path}/src/ngx_cache_purge --add-module=${Setup_Path}/src/nginx-sticky-module --with-http_stub_status_module --with-http_ssl_module --with-http_v2_module --with-http_image_filter_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --with-openssl-opt="enable-tls1_3 enable-weak-ssl-ciphers" ${jemallocLD}
	elif [ "$nginx_version" == "openresty" ]; then
		./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Update_Path}/src/openssl --with-pcre=pcre-${pcre_version} --add-module=${Update_Path}/src/ngx_cache_purge --add-module=${Update_Path}/src/nginx-sticky-module --with-luajit --with-http_stub_status_module --with-http_ssl_module --with-http_image_filter_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-stream --with-stream_ssl_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" ${jemallocLD}
	elif [ "${nginxVersion}" = "-Tengine2.2.3" ]; then
		./configure --user=www --group=www --prefix=${Setup_Path} --with-openssl=${Update_Path}/src/openssl --add-module=${Update_Path}/src/ngx_devel_kit --add-module=${Update_Path}/src/lua_nginx_module --add-module=${Update_Path}/src/ngx_cache_purge --add-module=${Update_Path}/src/nginx-sticky-module --with-http_stub_status_module --with-http_ssl_module --with-http_image_filter_module --with-http_v2_module --with-http_gzip_static_module --with-http_gunzip_module --with-ipv6 --with-http_sub_module --with-http_flv_module --with-http_addition_module --with-http_realip_module --with-http_mp4_module --with-ld-opt="-Wl,-E" --without-http_upstream_session_sticky_module --with-pcre=pcre-${pcre_version}
	fi
	make -j${cpuCore}
	if [ "$nginxVersion" = "openresty" ]; then
		make install
		echo -e "done"
		nginx -v
		exit;
	fi
	if [ ! -f ${Update_Path}/src/objs/nginx ]; then
		exit;
	fi
	sleep 1
	/etc/init.d/nginx stop
	mv -f ${Setup_Path}/sbin/nginx ${Setup_Path}/sbin/nginxBak
	\cp -rfp ${Update_Path}/src/objs/nginx ${Setup_Path}/sbin/
	sleep 1
	/etc/init.d/nginx start
	echo -e "done"
	if [ -f "/usr/bin/nginx" ]; then
		rm -rf ${Setup_Path}/src/*
		rm -rf ${Update_Path}
	fi
	nginx -v
	echo "$nginxVersion" > ${Setup_Path}/version.pl
	rm -f ${Setup_Path}/version_check.pl
}
CheckPHPVersion()
{
	PHPVersion=""
	for phpVer in 52 53 54 55 56 70 71 72 73;
	do
		if [ -d "/www/server/php/${phpVer}/bin" ]; then
			PHPVersion=${phpVer}
		fi
	done

	if [ "${PHPVersion}" != '' ];then
		\cp -r -a ${Setup_Path}/conf/enable-php-${PHPVersion}.conf ${Setup_Path}/conf/enable-php.conf
	fi
}

Uninstall_Nginx()
{
	service nginx stop
	pkill -9 nginx
	rm -rf $Setup_Path
	if [ -f "/usr/bin/apt-get" ];then
		update-rc.d nginx remove
	else
		chkconfig --del nginx
	fi
	rm -f /etc/init.d/nginx
}

actionType=$1
version=$2
if [ "$actionType" == 'install' ];then
	Install_Jemalloc
	nginxVersion='-Tengine2.2.3'
	if [ "$version" == "1.10" ] || [ "$version" == "1.12" ];then
		nginxVersion='1.12.2'
		nginx_version='1.12.2'
	elif [ "$version" == "1.8" ];then
		nginxVersion='1.8.1'
	elif [ "$version" == "openresty" ];then
		nginxVersion="openresty"
		nginx_version="openresty"
		openresty_version='1.13.6.2'
	elif [ "$version" == "1.14" ]; then
		nginxVersion='1.14.2'
		nginx_version='1.14.2'
	elif [ "$version" == "1.15" ]; then
		nginxVersion='1.15.6'
		nginx_version='1.15.6'
	fi
	Install_Nginx
	if [ ! -f /www/server/nginx/conf/enable-php-00.conf ];then
		echo > /www/server/nginx/conf/enable-php-00.conf
	fi
	
	if [ -f /www/server/panel/vhost/nginx/btwaf.conf ];then
		echo > /www/server/nginx/conf/luawaf.conf
	fi
	/etc/init.d/nginx restart
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Nginx
elif [ "$actionType" == 'update' ]; then
	Install_Jemalloc
	nginxVersion='-Tengine2.2.3'
	if [ "$version" == "1.10" ] || [ "$version" == "1.12" ];then
		nginxVersion='1.12.2'
		nginx_version='1.12.2'
	elif [ "$version" == "1.8" ];then
		nginxVersion='1.8.1'
	elif [ "$version" == "openresty" ];then
		nginxVersion="openresty"
		nginx_version="openresty"
		openresty_version='1.13.6.2'
	elif [ "$version" == "1.14" ]; then
		nginxVersion='1.14.2'
		nginx_version='1.14.2'
	elif [ "$version" == "1.15" ]; then
		nginxVersion='1.15.6'
		nginx_version='1.15.6'
	fi
	Update_nginx
fi
