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
mkdir -p /www/server
run_path="/root"
Is_64bit=`getconf LONG_BIT`

centos_version=`cat /etc/redhat-release | grep ' 7.' | grep -i centos`
if [ "${centos_version}" != '' ]; then
	rpm_path="centos7"
else
	rpm_path="centos6"
fi

Install_SendMail()
{
	yum -y install sendmail mailx
	if [ "${centos_version}" != '' ];then
		systemctl enable sendmail.service
		systemctl start sendmail.service
	else
		chkconfig --level 2345 sendmail on
		service sendmail start
	fi
}

Install_Curl()
{	
	curl_status=`cat /www/server/rpm.pl | grep curl`
	if [ "${curl_status}" != 'curl_installed_New' ] || [ ! -f /usr/local/curl/lib/libcurl.so ]; then
		cd ${run_path}
		if [ ! -f "bt-curl-7.54.0.rpm" ];then
			wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/curl-7.54.0.rpm
		fi
		rpm -ivh curl-7.54.0.rpm --force --nodeps
		rm -f curl-7.54.0.rpm
		sed -i '/curl/d' /www/server/rpm.pl
		echo -e "curl_installed_New" >> /www/server/rpm.pl
	fi
}
Install_Libiconv()
{
	libiconv_status=`cat /www/server/rpm.pl | grep libiconv`
	if [ "${libiconv_status}" != 'libiconv_installed' ] || [ ! -f /usr/local/libiconv/lib/libiconv.so ]; then
		cd ${run_path}
		if [ ! -f "bt-libiconv-1.14.rpm" ];then
			wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-libiconv-1.14.rpm
		fi
		rpm -ivh bt-libiconv-1.14.rpm --force --nodeps
		rm -f bt-libiconv-1.14.rpm
		sed -i '/libiconv/d' /www/server/rpm.pl
		echo -e "libiconv_installed" >> /www/server/rpm.pl
	fi
}

Install_Libmcrypt()
{	
	libmcrypt_status=`cat /www/server/rpm.pl | grep libmcrypt`
	if [ "${libmcrypt_status}" != 'libmcrypt_installed' ] || [ ! -f /usr/local/lib/libmcrypt.so ]; then
		cd ${run_path}
		if [ ! -f "bt-libmcrypt-2.5.8.rpm" ];then
			wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-libmcrypt-2.5.8.rpm
		fi
		rpm -ivh bt-libmcrypt-2.5.8.rpm --force --nodeps
		rm -f bt-libmcrypt-2.5.8.rpm
		ln -s /usr/local/lib/libltdl.so.3 /usr/lib/libltdl.so.3
		sed -i '/libmcrypt/d' /www/server/rpm.pl
		echo -e "libmcrypt_installed" >> /www/server/rpm.pl
	fi
}

Install_Mcrypt()
{   
	mcrypt_status=`cat /www/server/rpm.pl | grep mcrypty`
	if [ "${mcrypt_status}" != 'mcrypty_installed' ] || [ ! -f /usr/local/share/locale/cs/LC_MESSAGES/mcrypt.mo ]; then
		cd ${run_path}
		if [ ! -f "bt-mcrypt-2.6.8.rpm" ];then
			wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-mcrypt-2.6.8.rpm 
		fi
		
		rpm -ivh bt-mcrypt-2.6.8.rpm --force --nodeps 
		rm -f bt-mcrypt-2.6.8.rpm
		sed -i '/mcrypty/d' /www/server/rpm.pl
		echo -e "mcrypty_installed" >> /www/server/rpm.pl
	fi
}

Install_Mhash()
{
	mhash_status=`cat /www/server/rpm.pl | grep mhash`
	if [ "${mhash_status}" != 'mhash_installed' ] || [ ! -f /usr/local/lib/libmhash.so ]; then
		cd ${run_path}
		if [ ! -f "bt-mhash-0.9.9.9.rpm" ];then
			wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-mhash-0.9.9.9.rpm
		fi
		rpm -ivh bt-mhash-0.9.9.9.rpm --force --nodeps
		rm -f bt-mhash-0.9.9.9.rpm
		sed -i '/mhash/d' /www/server/rpm.pl
		echo -e "mhash_installed" >> /www/server/rpm.pl
	fi
}

Install_Pcre()
{	
	pcre_status=`cat /www/server/rpm.pl | grep pcre`
	if [ "${pcre_status}" != 'pcre_installed' ] || [ ! -f /usr/local/lib/libpcre.so ]; then
	    Cur_Pcre_Ver=`pcre-config --version`
	    if echo "${Cur_Pcre_Ver}" | grep -vEqi '^8.';then
			cd ${run_path}
			if [ ! -f "bt-pcre-8.36.rpm" ];then
				wget ${Download_Url}/rpm/${rpm_path}/${Is_64bit}/bt-pcre-8.36.rpm
			fi
			rpm -ivh bt-pcre-8.36.rpm --force --nodeps
			rm -f bt-pcre-8.36.rpm
	    fi
	    sed -i '/pcre/d' /www/server/rpm.pl
	    echo -e "pcre_installed" >> /www/server/rpm.pl
	fi
}

Install_OpenSSL()
{
	openssl_status=`cat /www/server/lib.pl | grep openssl`
	if [ "${openssl_status}" != 'openssl_installed' ]; then
		cd ${run_path}
		wget ${Download_Url}/src/openssl-1.0.2k.tar.gz -T 20
		tar xvf openssl-1.0.2k.tar.gz
		rm -f openssl-1.0.2k.tar.gz
		cd openssl-1.0.2k
		./config --prefix=/usr shared zlib-dynamic
		rm -f /usr/bin/openssl
		rm -f /usr/include/openssl
		make && make install
		ln -sf /usr/include/openssl/*.h /usr/include/
		ln -sf /usr/lib/openssl/engines/*.so /usr/lib/
		ldconfig -v
		echo -e "openssl_installed" >> /www/server/lib.pl
		openssl version
		
		cd .. 
		rm -rf openssl-1.0.2k
	fi
}

lockFile='/var/lock/bt_lib.lock'
if [ ! -f "${lockFile}" ];then
	sed -i "s#SELINUX=enforcing#SELINUX=disabled#" /etc/selinux/config
	rpm -e --nodeps mariadb-libs-*

	rm -f /var/run/yum.pid
	for yumPack in make cmake gcc gcc-c++ gcc-g77 flex bison file libtool libtool-libs autoconf kernel-devel patch wget libjpeg libjpeg-devel libpng libpng-devel libpng10 libpng10-devel gd gd-devel libxml2 libxml2-devel zlib zlib-devel glib2 glib2-devel tar bzip2 bzip2-devel libevent libevent-devel ncurses ncurses-devel curl curl-devel libcurl libcurl-devel e2fsprogs e2fsprogs-devel krb5 krb5-devel libidn libidn-devel openssl openssl-devel vim-minimal gettext gettext-devel ncurses-devel gmp-devel pspell-devel libcap diffutils ca-certificates net-tools libc-client-devel psmisc libXpm-devel git-core c-ares-devel libicu-devel libxslt libxslt-devel zip unzip glibc.i686 libstdc++.so.6 cairo-devel bison-devel ncurses-devel libaio-devel perl perl-devel perl-Data-Dumper lsof pcre pcre-devel vixie-cron crontabs;
	do yum -y install $yumPack;done

	Install_SendMail
	groupadd www
	useradd -s /sbin/nologin -M -g www www
fi


Install_Pcre
Install_Curl
Install_Mhash
Install_Libmcrypt
Install_Mcrypt	
Install_Libiconv
#Install_OpenSSL
echo 'true' > $lockFile
echo "所有前置依赖已经安装完成！"