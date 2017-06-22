#!/bin/bash
set -e

/usr/bin/bt start

exec "$@"
