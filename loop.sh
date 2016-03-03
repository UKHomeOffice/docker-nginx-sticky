#!/usr/bin/env bash

set -u
set -e

/usr/sbin/nginx -g 'daemon off;' &

while true
do
    /gen-config.sh
    sleep 10
done;
