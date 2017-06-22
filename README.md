# bt-panel

```
docker run \
--name bt \
--link mysql:localmysql \
-p 8888:8888 \
-p 80:80 \
-p 21 \
-p 20 \
-d ywfwj2008/bt-panel
```