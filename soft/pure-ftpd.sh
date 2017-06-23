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
Setup_Path=$Root_Path/server/pure-ftpd
run_path='/root'
pure_ftpd_version='1.0.43'


Install_OpenSSL()
{
	if [ ! -f /usr/local/openssl/version.pl ];then
		cd /root
		wget http://125.88.182.172:5880/src/openssl-1.0.2l.tar.gz -T 20
		tar xvf openssl-1.0.2l.tar.gz
		rm -f openssl-1.0.2l.tar.gz
		cd openssl-1.0.2l
		./config --prefix=/usr/local/openssl
		make && make install
		echo '1.0.2l' > /usr/local/openssl/version.pl
	fi
}


Install_Pureftpd()
{
	cd ${run_path}
	rm -rf ${Setup_Path}
	rm -f /etc/init.d/pure-ftpd
	if [ ! -f "pure-ftpd-${pure_ftpd_version}.tar.gz" ];then
		wget ${Download_Url}/src/pure-ftpd-${pure_ftpd_version}.tar.gz -T20
	fi
	tar -zxf pure-ftpd-${pure_ftpd_version}.tar.gz
	cd pure-ftpd-${pure_ftpd_version}
	
    echo "Installing pure-ftpd..."
    ./configure --prefix=${Setup_Path} CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg --with-throttling --with-uploadscript --with-language=english --with-rfc2640 --with-ftpwho --with-tls=/usr/local/openssl

    make && make install
	
	if [ ! -f "${Setup_Path}/bin/pure-pw" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: pure-ftpd installation failed.\033[0m";
		rm -rf ${Setup_Path}
		exit 0;
	fi
	

    echo "Copy configure files..."
    wget ${Download_Url}/install/src/pure-config.pl -T20
    \cp pure-config.pl ${Setup_Path}/sbin/
    chmod 755 ${Setup_Path}/sbin/pure-config.pl
	sed -i "s@/usr/local@$Root_Path/server@g" ${Setup_Path}/sbin/pure-config.pl
	
    mkdir ${Setup_Path}/etc
	wget -O ${Setup_Path}/etc/pure-ftpd.conf ${Download_Url}/conf/pure-ftpd.conf -T20
	wget -O /etc/init.d/pure-ftpd ${Download_Url}/init/pureftpd.init -T20
    chmod +x /etc/init.d/pure-ftpd
    touch ${Setup_Path}/etc/pureftpd.passwd
    touch ${Setup_Path}/etc/pureftpd.pdb

    StartUp pureftpd

    cd ${run_path}
    rm -rf pure-ftpd*

    if [[ -s ${Setup_Path}/sbin/pure-config.pl && -s ${Setup_Path}/etc/pure-ftpd.conf && -s /etc/init.d/pure-ftpd ]]; then
        echo "Starting pureftpd..."
        if [ -f "/www/backup/ftpd_backup.pdb" ];then
			\cp -a -r /www/backup/ftpd_backup.pdb ${Setup_Path}/etc/pureftpd.pdb
		fi
		if [ -f "/www/backup/ftpd_backup.passwd" ];then
			\cp -a -r /www/backup/ftpd_backup.passwd ${Setup_Path}/etc/pureftpd.passwd
		fi
		if [ -f "/www/backup/ftpd_backup.conf" ];then
			\cp -a -r /www/backup/ftpd_backup.conf ${Setup_Path}/etc/pure-ftpd.conf
		fi
		chkconfig --add pure-ftpd
		chkconfig --level 2345 pure-ftpd on
				address=`curl http://www.bt.cn/Api/getIpAddress`
		if [ "$address" == "" ];then
			address='www.bt.cn';
		fi
		mkdir -p /etc/ssl/private
		openssl req -x509 -nodes -newkey rsa:1024 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem<<EOF
CN
Guangdong
Dongguan
BT-PANEL
BT
$address
admin@bt.cn
EOF
		if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
			sed -i "s/# TLS/TLS/" /www/server/pure-ftpd/etc/pure-ftpd.conf
		fi
		
		/etc/init.d/pure-ftpd start
		echo "${pure_ftpd_version}" > ${Setup_Path}/version.pl
    else
        echo "Pureftpd install failed!"
    fi
}

Uninstall_Pureftpd()
{
	if [ -f "/etc/init.d/pure-ftpd" ];then
		\cp -a -r ${Setup_Path}/etc/pureftpd.pdb /www/backup/ftpd_backup.pdb
		\cp -a -r ${Setup_Path}/etc/pureftpd.passwd /www/backup/ftpd_backup.passwd
		\cp -a -r ${Setup_Path}/etc/pure-ftpd.conf /www/backup/ftpd_backup.conf
		/etc/init.d/pure-ftpd stop
		pkill -9 pure-ftpd
		chkconfig --del pure-ftpd
		rm -f /etc/init.d/pure-ftpd
		rm -rf $Setup_Path
	fi
}

actionType=$1

if [ "$actionType" == 'install' ];then
	Install_OpenSSL
	Install_Pureftpd
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Pureftpd
fi

