#!/bin/bash
set -e

/etc/init.d/bt start
/etc/init.d/nginx start

exec "$@"
