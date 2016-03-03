#!/usr/bin/env bash

set -u
set -e

/usr/sbin/nginx -g 'pid /usr/local/nginx/logs/nginx.pid; daemon off;' &

while true
do
    /gen-config.sh
    cmp --silent /etc/nginx/nginx.conf file || $(/bin/cp -rf file /etc/nginx/nginx.conf && /usr/sbin/nginx -s reload)
    sleep 10
done;
