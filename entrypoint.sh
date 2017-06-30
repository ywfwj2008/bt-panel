#!/bin/bash
set -e

/etc/init.d/bt start

exec "$@"
