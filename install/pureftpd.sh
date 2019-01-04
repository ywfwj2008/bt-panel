#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

public_file=/www/server/panel/install/public.sh
if [ ! -f $public_file ];then
	wget -O $public_file http://download.bt.cn/install/public.sh -T 5;
fi
. $public_file

download_Url=$NODE_URL
Root_Path=`cat /var/bt_setupPath.conf`
Setup_Path=$Root_Path/server/pure-ftpd
run_path='/root'
pure_ftpd_version='1.0.47'

Install_Pureftpd()
{
	cd ${run_path}
	rm -rf ${Setup_Path}
	rm -f /etc/init.d/pure-ftpd
	if [ ! -f "pure-ftpd-${pure_ftpd_version}.tar.gz" ];then
		wget ${download_Url}/src/pure-ftpd-${pure_ftpd_version}.tar.gz -T20
	fi
	tar -zxf pure-ftpd-${pure_ftpd_version}.tar.gz
	cd pure-ftpd-${pure_ftpd_version}
	
    echo "Installing pure-ftpd..."
    ./configure --prefix=${Setup_Path} CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg --with-throttling --with-uploadscript --with-language=english --with-rfc2640 --with-ftpwho --with-tls
    make && make install
	
	if [ ! -f "${Setup_Path}/bin/pure-pw" ];then
		echo '========================================================'
		echo -e "\033[31mERROR: pure-ftpd installation failed.\033[0m";
		rm -rf ${Setup_Path}
		exit 0;
	fi
	

    echo "Copy configure files..."
    wget ${download_Url}/install/src/pure-config.pl -T20
    \cp pure-config.pl ${Setup_Path}/sbin/
    chmod 755 ${Setup_Path}/sbin/pure-config.pl
	sed -i "s@/usr/local@$Root_Path/server@g" ${Setup_Path}/sbin/pure-config.pl
	
    mkdir ${Setup_Path}/etc
	wget -O ${Setup_Path}/etc/pure-ftpd.conf ${download_Url}/conf/pure-ftpd.conf -T20
	wget -O /etc/init.d/pure-ftpd ${download_Url}/init/pureftpd.init -T20
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
		openssl req -x509 -nodes -days 3560 -newkey rsa:1024 -keyout /etc/ssl/private/pure-ftpd.pem -out /etc/ssl/private/pure-ftpd.pem<<EOF
CN
Guangdong
Dongguan
BT-PANEL
BT
$address
admin@bt.cn
EOF
		if [ -f '/etc/ssl/private/pure-ftpd.pem' ];then
			chmod 600 /etc/ssl/private/pure-ftpd.pem
			sed -i "s/# TLS/TLS/" /www/server/pure-ftpd/etc/pure-ftpd.conf
		fi
		
		/etc/init.d/pure-ftpd start
		echo "${pure_ftpd_version}" > ${Setup_Path}/version.pl
		echo "${pure_ftpd_version}" > ${Setup_Path}/version_ckeck.pl
    else
        echo "Pureftpd install failed!"
    fi
}
Update_Pureftpd(){
	cd ${run_path}
	mkdir -p ${Setup_Path}/src
	rm -rf ${Setup_Path}/src/*
	cd ${Setup_Path}/src
	\cp -a -r ${Setup_Path}/etc/pureftpd.pdb /www/backup/ftpd_backup.pdb
	\cp -a -r ${Setup_Path}/etc/pureftpd.passwd /www/backup/ftpd_backup.passwd
	\cp -a -r ${Setup_Path}/etc/pure-ftpd.conf /www/backup/ftpd_backup.conf
	if [ ! -f "pure-ftpd-${pure_ftpd_version}.tar.gz" ];then
		wget ${download_Url}/src/pure-ftpd-${pure_ftpd_version}.tar.gz -T20
	fi
	tar -zxf pure-ftpd-${pure_ftpd_version}.tar.gz
	cd pure-ftpd-${pure_ftpd_version}
	
    echo "Installing pure-ftpd..."
    ./configure --prefix=${Setup_Path} CFLAGS=-O2 --with-puredb --with-quotas --with-cookie --with-virtualhosts --with-diraliases --with-sysquotas --with-ratios --with-altlog --with-paranoidmsg --with-shadow --with-welcomemsg --with-throttling --with-uploadscript --with-language=english --with-rfc2640 --with-ftpwho --with-tls
    make && make install
    \cp -a -r /www/backup/ftpd_backup.pdb ${Setup_Path}/etc/pureftpd.pdb
    \cp -a -r /www/backup/ftpd_backup.passwd ${Setup_Path}/etc/pureftpd.passwd
    \cp -a -r /www/backup/ftpd_backup.conf ${Setup_Path}/etc/pure-ftpd.conf
    /etc/init.d/pure-ftpd restart
    echo "${pure_ftpd_version}" > ${Setup_Path}/version.pl
}
Uninstall_Pureftpd()
{
	if [ -f "/www/server/pure-ftpd/sbin/pure-ftpd" ];then
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
	Install_Pureftpd
elif [ "$actionType" == 'uninstall' ];then
	Uninstall_Pureftpd
elif [ "$actionType" == 'update' ]; then
	Update_Pureftpd
fi

