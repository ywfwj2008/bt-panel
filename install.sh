#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

isUbuntu=`cat /etc/issue|grep Ubuntu`
if [ "$isUbuntu" != "" ];then
	wget -O install.sh http://download.bt.cn/install/install-ubuntu.sh && sudo bash install.sh
	exit;
fi

isDebian=`cat /etc/issue|grep Debian`
if [ "$isUbuntu" != "" ];then
	wget -O install.sh http://download.bt.cn/install/install-ubuntu.sh && bash install.sh
	exit;
fi

echo "
+----------------------------------------------------------------------
| Bt-WebPanel 4.x FOR CentOS/Redhat/Fedora/Ubuntu/Debian
+----------------------------------------------------------------------
| Copyright © 2015-2017 BT-SOFT(http://www.bt.cn) All rights reserved.
+----------------------------------------------------------------------
| The WebPanel URL will be http://SERVER_IP:8888 when installed.
+----------------------------------------------------------------------
"
#自动选择下载节点
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
download_Url=http://$nodeAddr:5880
rm -f ping.pl

setup_path=/www
port='8888'
if [ -f $setup_path/server/panel/data/port.pl ];then
	port=`cat $setup_path/server/panel/data/port.pl`
fi

yum clean all
yum install ntp -y
\cp -a -r /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo 'Synchronizing system time...'
ntpdate 0.asia.pool.ntp.org
startTime=`date +%s`
yum upgrade -y
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
for pace in wget python-devel python-imaging zip unzip openssl openssl-devel gcc libxml2 libxml2-dev libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs;
do 
	yum -y install $pace; 
done

yum install python-devel -y

if [ ! -f '/usr/bin/mysql_config' ];then
	yum install mysql-devel -y
fi

tmp=`python -V 2>&1|awk '{print $2}'`
pVersion=${tmp:0:3}

Install_setuptools()
{
	if [ ! -f "/usr/bin/easy_install" ];then
		wget -O setuptools-33.1.1.zip $download_Url/install/src/setuptools-33.1.1.zip -T 10
		unzip setuptools-33.1.1.zip
		rm -f setuptools-33.1.1.zip
		cd setuptools-33.1.1
		python setup.py install
		cd ..
		rm -rf setuptools-33.1.1
	fi
	
	if [ ! -f "/usr/bin/easy_install" ];then
		echo '=================================================';
		echo -e "\033[31msetuptools installation failed. \033[0m";
		exit;
	fi
}

Install_pip()
{
	ispip=`pip -V |grep from`
	if [ "$ispip" == "" ];then
		if [ ! -f "/usr/bin/easy_install" ];then
			Install_setuptools
		fi
		wget -O pip-9.0.1.tar.gz $download_Url/install/src/pip-9.0.1.tar.gz -T 10
		tar xvf pip-9.0.1.tar.gz
		rm -f pip-9.0.1.tar.gz
		cd pip-9.0.1
		python setup.py install
		cd ..
		rm -rf pip-9.0.1
	fi
	ispip=`pip -V |grep from`
	if [ "$ispip" = "" ];then
		echo '=================================================';
		echo -e "\033[31m Python-pip installation failed. \033[0m";
		exit;
	fi
}

Install_Pillow()
{
	isSetup=`python -m PIL 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		isFedora = `cat /etc/redhat-release |grep Fedora`
		if [ "$isFedora" != "" ];then
			pip install Pillow
			return;
		fi
		wget -O Pillow-3.2.0.zip $download_Url/install/src/Pillow-3.2.0.zip -T 10
		unzip Pillow-3.2.0.zip
		rm -f Pillow-3.2.0.zip
		cd Pillow-3.2.0
		python setup.py install
		cd ..
		rm -rf Pillow-3.2.0
	fi
	
	isSetup=`python -m PIL 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mPillow installation failed. \033[0m";
		exit;
	fi
}

Install_psutil()
{
	isSetup=`python -m psutil 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O psutil-5.1.3.tar.gz $download_Url/install/src/psutil-5.1.3.tar.gz -T 10
		tar xvf psutil-5.1.3.tar.gz
		rm -f psutil-5.1.3.tar.gz
		cd psutil-5.1.3
		python setup.py install
		cd ..
		rm -rf psutil-5.1.3
	fi
	isSetup=`python -m psutil 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mpsutil installation failed. \033[0m";
		exit;
	fi
}

Install_mysqldb()
{
	isSetup=`python -m MySQLdb 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O MySQL-python-1.2.5.zip $download_Url/install/src/MySQL-python-1.2.5.zip -T 10
		unzip MySQL-python-1.2.5.zip
		rm -f MySQL-python-1.2.5.zip
		cd MySQL-python-1.2.5
		python setup.py install
		cd ..
		rm -rf MySQL-python-1.2.5
	fi
}

Install_chardet()
{
	isSetup=`python -m chardet 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O chardet-2.3.0.tar.gz $download_Url/install/src/chardet-2.3.0.tar.gz -T 10
		tar xvf chardet-2.3.0.tar.gz
		rm -f chardet-2.3.0.tar.gz
		cd chardet-2.3.0
		python setup.py install
		cd ..
		rm -rf chardet-2.3.0
	fi	
	
	isSetup=`python -m chardet 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mchardet installation failed. \033[0m";
		exit;
	fi
}

Install_webpy()
{
	isSetup=`python -m web 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		wget -O web.py-0.38.tar.gz $download_Url/install/src/web.py-0.38.tar.gz -T 10
		tar xvf web.py-0.38.tar.gz
		rm -f web.py-0.38.tar.gz
		cd web.py-0.38
		python setup.py install
		cd ..
		rm -rf web.py-0.38
	fi
	
	isSetup=`python -m web 2>&1|grep package`
	if [ "$isSetup" = "" ];then
		echo '=================================================';
		echo -e "\033[31mweb.py installation failed. \033[0m";
		exit;
	fi
}


Install_setuptools
Install_pip

if [ "$nodeAddr" = "$CN" ]; then
	if [ ! -d "/root/.pip" ];then
		mkdir ~/.pip
	fi
    cat > ~/.pip/pip.conf <<EOF
[global]
index-url = https://pypi.doubanio.com/simple/

[install]
trusted-host=pypi.doubanio.com
EOF
fi

pip install --upgrade pip
pip install psutil mysql-python chardet web.py virtualenv

Install_Pillow
Install_psutil
Install_mysqldb
Install_chardet
Install_webpy

mkdir -p $setup_path/server/panel/logs
mkdir -p $setup_path/server/panel/vhost/apache
mkdir -p $setup_path/server/panel/vhost/nginx
mkdir -p $setup_path/server/panel/vhost/rewrite
wget -O $setup_path/server/panel/certbot-auto $download_Url/install/certbot-auto.init -T 5
chmod +x $setup_path/server/panel/certbot-auto


if [ -f '/etc/init.d/bt' ];then
	service bt stop
fi

mkdir -p /www/server
mkdir -p /www/wwwroot
mkdir -p /www/wwwlogs
mkdir -p /www/backup/database
mkdir -p /www/backup/site

if [ ! -f "/usr/bin/unzip" ];then
	#rm -f /etc/yum.repos.d/epel.repo
	yum install unzip -y
fi
wget -O panel.zip $download_Url/install/src/panel.zip -T 10
wget -O /etc/init.d/bt $download_Url/install/src/bt.init -T 10
if [ -f "$setup_path/server/panel/data/default.db" ];then
	if [ -d "/$setup_path/server/panel/old_data" ];then
		rm -rf $setup_path/server/panel/old_data
	fi
	mkdir -p $setup_path/server/panel/old_data
	mv -f $setup_path/server/panel/data/default.db $setup_path/server/panel/old_data/default.db
	mv -f $setup_path/server/panel/data/system.db $setup_path/server/panel/old_data/system.db
	mv -f $setup_path/server/panel/data/aliossAs.conf $setup_path/server/panel/old_data/aliossAs.conf
	mv -f $setup_path/server/panel/data/qiniuAs.conf $setup_path/server/panel/old_data/qiniuAs.conf
	mv -f $setup_path/server/panel/data/iplist.txt $setup_path/server/panel/old_data/iplist.txt
	mv -f $setup_path/server/panel/data/port.pl $setup_path/server/panel/old_data/port.pl
fi

unzip -o panel.zip -d $setup_path/server/ > /dev/null

if [ -d "$setup_path/server/panel/old_data" ];then
	mv -f $setup_path/server/panel/old_data/default.db $setup_path/server/panel/data/default.db
	mv -f $setup_path/server/panel/old_data/system.db $setup_path/server/panel/data/system.db
	mv -f $setup_path/server/panel/old_data/aliossAs.conf $setup_path/server/panel/data/aliossAs.conf
	mv -f $setup_path/server/panel/old_data/qiniuAs.conf $setup_path/server/panel/data/qiniuAs.conf
	mv -f $setup_path/server/panel/old_data/iplist.txt $setup_path/server/panel/data/iplist.txt
	mv -f $setup_path/server/panel/old_data/port.pl $setup_path/server/panel/data/port.pl
	
	if [ -d "/$setup_path/server/panel/old_data" ];then
		rm -rf $setup_path/server/panel/old_data
	fi
fi

rm -f panel.zip

if [ ! -f $setup_path/server/panel/tools.py ];then
	echo -e "\033[31mERROR: Failed to download, please try again!\033[0m";
	echo '============================================'
	exit;
fi

rm -f $setup_path/server/panel/class/*.pyc
rm -f $setup_path/server/panel/*.pyc
python -m compileall $setup_path/server/panel
rm -f $setup_path/server/panel/class/*.py
rm -f $setup_path/server/panel/*.py



chmod +x /etc/init.d/bt
chkconfig --add bt
chkconfig --level 2345 bt on
chmod -R 600 $setup_path/server/panel
chmod +x $setup_path/server/panel/certbot-auto
chmod -R +x $setup_path/server/panel/script
echo "$port" > $setup_path/server/panel/data/port.pl
password=123456
cd $setup_path/server/panel/
username=`python tools.pyc panel $password`
cd ~
echo "$password" > $setup_path/server/panel/default.pl
chmod 600 $setup_path/server/panel/default.pl

if [ -f "/etc/init.d/iptables" ];then
	iptables -I INPUT DROP
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 20 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 21 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport $port -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 30000:40000 -j ACCEPT
	iptables -I INPUT -p tcp -m state --state NEW -m udp --dport 30000:40000 -j ACCEPT
	service iptables save
	sed -i "s#IPTABLES_MODULES=\"\"#IPTABLES_MODULES=\"ip_conntrack_netbios_ns ip_conntrack_ftp ip_nat_ftp\"#" /etc/sysconfig/iptables-config

	iptables_status=`service iptables status | grep 'not running'`
	if [ "${iptables_status}" == '' ];then
		service iptables restart
	fi
fi

if [ "${isVersion}" == '' ];then
	if [ ! -f "/etc/init.d/iptables" ];then
		yum install firewalld -y
		systemctl enable firewalld
		systemctl start firewalld
		firewall-cmd --set-default-zone=public > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=20/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=21/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=22/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=80/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=$port/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=30000-40000/tcp > /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-port=30000-40000/udp > /dev/null 2>&1
		firewall-cmd --reload
	fi
fi

pip install psutil chardet web.py MySQL-python psutil virtualenv > /dev/null 2>&1

if [ ! -d '/etc/letsencrypt' ];then
	yum install epel-release -y

	if [ "${country}" = "CN" ]; then
		isC7=`cat /etc/redhat-release |grep ' 7.'`
		if [ "${isC7}" == "" ];then
			wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
		else
			wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
		fi
	fi
	mkdir -p /var/spool/cron
	if [ ! -f '/var/spool/cron/root' ];then
		echo '' > /var/spool/cron/root
		chmod 600 /var/spool/cron/root
	fi
	isCron=`cat /var/spool/cron/root|grep certbot.log`
	if [ "${isCron}" == "" ];then
		echo "30 2 * * * $setup_path/server/panel/certbot-auto renew >> $setup_path/server/panel/logs/certbot.log" >>  /var/spool/cron/root
		chown 600 /var/spool/cron/root
	fi
	nohup $setup_path/server/panel/certbot-auto -n > /tmp/certbot-auto.log 2>&1 &
fi

address=""
address=`curl -sS --connect-timeout 10 -m 60 http://www.bt.cn/Api/getIpAddress`
if [ "$address" == "" ];then
	address="SERVER_IP"
fi

if [ "$address" != "SERVER_IP" ];then
	echo "$address" > $setup_path/server/panel/data/iplist.txt
fi

curl -sS --connect-timeout 10 -m 60 http://www.bt.cn/Api/SetupCount?type=Linux > /dev/null 2>&1

echo -e "=================================================================="
echo -e "\033[32mCongratulations! Install succeeded!\033[0m"
echo -e "=================================================================="
echo -e "Bt-Panel: http://$address:$port"
echo -e "username: $username"
echo -e "password: $password"
echo -e "\033[33mWarning:\033[0m"
echo -e "\033[33mIf you cannot access the panel, \033[0m"
echo -e "\033[33mrelease the following port (8888|888|80|443|20|21) in the security group\033[0m"
echo -e "=================================================================="

endTime=`date +%s`
((outTime=($endTime-$startTime)/60))
echo -e "Time consumed:\033[32m $outTime \033[0mMinute!"
rm -f install.sh
