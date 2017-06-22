# bt-panel
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

nginx:
编译：http://125.88.182.172:5880/install/0/nginx.sh
极速：http://125.88.182.172:5880/install/1/nginx.sh
php:
编译：http://125.88.182.172:5880/install/0/php.sh
极速：http://125.88.182.172:5880/install/1/php.sh

sh $name.sh $actionType $version
```

```
docker run \
--name bt \
--link mysql:localmysql \
-v /www:/www \
-p 8888:8888 \
-p 80:80 \
-p 21 \
-p 20 \
-d ywfwj2008/bt-panel
```