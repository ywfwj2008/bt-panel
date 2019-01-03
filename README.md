# 宝塔Linux面板 Docker 版

`Version：6.8 免费版`

本Docker基于[宝塔Linux面板](https://www.bt.cn),集成环境包含 Nginx PHP5.6 PHP7 FTP等基本服务，未包含Mysql，建议用外链服务的方式支持。

## 三级镜像
 - [宝塔面板](https://hub.docker.com/r/ywfwj2008/bt-panel)
 - [宝塔面板 + PHP](https://hub.docker.com/r/ywfwj2008/bt-php/)
 - [宝塔面板 + PHP + NGINX](https://hub.docker.com/r/ywfwj2008/bt-php-nginx/)

## 快速开始
```
docker run \
--name bt \
-p 8888:8888 \
-p 80:80 \
-p 443:443 \
-p 21:21 \
-p 20:20 \
-p 25:25 \
-d ywfwj2008/bt-php-nginx:latest
```

获BT后台地址和用户名与密码：
`docker exec -it bt /etc/init.d/bt default`


## 带 MYSQL 和 REDIS 的 运行案例
### run mysql
如果需要外连mysql，先运行mysql镜像。宝塔镜像中使用link参数连接。
```
docker run \
    --name mysql \
    -v /data/config/mysql:/etc/mysql/conf.d \
    -v /data/mysql:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -d mysql:latest
```

### run redis
如果需要外连redis，先运行redis镜像。宝塔镜像中使用link参数连接。
```
docker run \
    --name redis \
    --restart=always \
    -e 'REDIS_PASSWORD=redispassword' \
    -v /data/redis-persistence:/var/lib/redis \
    -d sameersbn/redis --appendonly yes
```

### run web server
运行docker时，可以通过 `BT_PASSWORD` 自定义登录密码
```
docker run \
    --name bt \
    --link mysql:localmysql \
    --link redis:localredis \
    -v /data/backup:/www/backup \
    -v /data/wwwlogs:/www/wwwlogs \
    -v /data/wwwroot:/www/wwwroot \
    -v /data/config/panel/vhost:/www/server/panel/vhost \
    -v /data/letsencrypt:/etc/letsencrypt \
    --mount type=bind,source=/data/config/panel/data/default.db,target=/www/server/panel/data/default.db \
    -e BT_PASSWORD=my-secret-pw \
    -p 8888:8888 \
    -p 80:80 \
    -p 443:443 \
    -p 21:21 \
    -p 20:20 \
    -p 25:25 \
    -d ywfwj2008/bt-php-nginx:latest
```

## 联系方式
