#!/usr/bin/env bash

set -u
set -e
: ${PORT:=8000}
: ${DOMAIN:=api.${ENVIRONMENT}.svc.cluster.local}
BACKENDS=$(dig ${DOMAIN} +short | sort |  xargs -I {} echo "        server {}:443;")

if [[ -z $BACKENDS ]]; then
    BACKENDS="        server 127.0.0.1:443;"
fi

cat <<- EOF > file
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    upstream backend {
        sticky;
$BACKENDS
    }

    server {
        listen       ${PORT} default_server;
        listen       [::]:${PORT} default_server;
        server_name  _;
 
        location / {
            proxy_ssl_verify off;
            proxy_redirect     off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;     
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_pass https://backend;
        }
        
        location /irc_entry {

            proxy_ssl_verify off;
            proxy_redirect     off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_pass https://backend;
        }
    }
}
EOF

cmp --silent /etc/nginx/nginx.conf file || /bin/cp -rf file /etc/nginx/nginx.conf && /usr/sbin/nginx -s reload
