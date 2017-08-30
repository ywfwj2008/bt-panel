# bt-panel
## TODO
1. 用户名和密码自定义
2. 修改默认IP地址

```
CN='125.88.182.172'
HK='103.224.251.79'
HK2='103.224.251.67'
US='128.1.164.196'

serverUrl=http://$nodeAddr:5880/install
mtype=$1(0/1)
actionType=$2(install/uninstall)
name=$3(nginx/php)
version=$4

nginx：http://125.88.182.172:5880/install/0/nginx.sh
php：http://125.88.182.172:5880/install/0/php.sh
mysql：http://125.88.182.172:5880/install/0/mysql.sh
redis：http://125.88.182.172:5880/install/0/redis.sh
Pure-Ftpd：http://125.88.182.172:5880/install/0/pure-ftpd.sh
lib：http://125.88.182.172:5880/install/1/lib.sh

php扩展：
http://125.88.182.172:5880/install/1/opcache.sh

sh $name.sh $actionType $version
```
## install nginx
nginx: http://125.88.182.172:5880/install/0/nginx.sh install 1.12  
tengine: http://125.88.182.172:5880/install/0/nginx.sh install  
openrestry: http://125.88.182.172:5880/install/0/nginx.sh install openresty

## run mysql
```
docker run \
--name mysql \
-v /home/config/mysql:/etc/mysql/conf.d \
-v /home/mysql:/var/lib/mysql \
-e MYSQL_ROOT_PASSWORD=my-secret-pw \
-d mysql:5.6
```
## run web server
```
docker run \
--name bt \
--link mysql:localmysql \
-v /home/backup:/www/backup \
-v /home/wwwlogs:/www/wwwlogs \
-v /home/wwwroot:/www/wwwroot \
-v /home/config/vhost:/www/server/panel/vhost \
-v /home/config/pureftpd.passwd:/www/server/pure-ftpd/etc/pureftpd.passwd \
-v /home/letsencrypt:/etc/letsencrypt \
-e BT_ADMIN_ACCOUNT=my-account \
-e BT_ADMIN_PASSWORD=my-secret-pw \
-p 8888:8888 \
-p 80:80 \
-p 443:443 \
-p 21:21 \
-p 20:20 \
-d ywfwj2008/bt-php-nginx
```