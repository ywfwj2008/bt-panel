#!/bin/bash
set -e

echo "" > /www/server/panel/data/iplist.txt

/etc/init.d/bt start

exec "$@"
