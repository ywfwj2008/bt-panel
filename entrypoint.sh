#!/bin/bash
set -e

service bt start

exec "$@"
