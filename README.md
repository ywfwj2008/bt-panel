# 宝塔Linux面板 Docker 版

`Version：7.0 免费版`

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
-d ywfwj2008/bt-php-nginx:latest
```

获取BT管理后台地址和用户名与密码：  
`docker exec -it bt bt default`


## 带 MYSQL 和 REDIS 的 运行案例
### run mysql
如果需要外连mysql，先运行mysql镜像。宝塔镜像中使用link参数连接。
```
docker run \
    --name mysql \
    --restart=always \
    -v /data/config/mysql:/etc/mysql/conf.d \
    -v /data/mysql:/var/lib/mysql \
    -e MYSQL_ROOT_PASSWORD=my-secret-pw \
    -d mysql:latest \
        --default-authentication-plugin=mysql_native_password \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_unicode_ci
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
~~运行docker时，可以通过 `BT_PASSWORD` 自定义登录密码~~  
6.0以上版本不再支持自定义密码,请通过执行以下命令获取  
`docker exec -it bt bt default`

```
docker run \
    --name bt \
    --link mysql:localmysql \
    --link redis:localredis \
    -v /data/backup:/www/backup \
    -v /data/wwwlogs:/www/wwwlogs \
    -v /data/wwwroot:/www/wwwroot \
    -p 8888:8888 \
    -p 80:80 \
    -p 443:443 \
    -p 21:21 \
    -p 20:20 \
    -d ywfwj2008/bt-php-nginx:latest
```

备份宝塔配置建议使用宝塔内置的备份功能

## 联系方式

