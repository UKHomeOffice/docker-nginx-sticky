#!/usr/bin/env bash

set -u
set -e
: ${PORT:=8000}
: ${POD_PORT:=443}
: ${DOMAIN:=api.${ENVIRONMENT}.svc.cluster.local}
: ${POD_HTTPS:=true}
BACKENDS=$(dig ${DOMAIN} +short | sort |  xargs -I {} echo "        server {}:${POD_PORT};")

if [[ -z $BACKENDS ]]; then
    BACKENDS="        server 127.0.0.1:443;"
fi

if [[ "$POD_HTTPS" == "true" ]]; then
    PROXY_DNS="https://backend"
    PROXY_LOCAL="https://local"
else
    PROXY_DNS="http://backend"
    PROXY_LOCAL="http://local"
fi

cat <<- EOF > file
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;

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

    upstream local {
        server 127.0.0.1:${POD_PORT};
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
            proxy_pass ${PROXY_DNS};
        }
        
        location /irc_entry {

            proxy_ssl_verify off;
            proxy_redirect     off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_pass ${PROXY_DNS};
        }
        location /health/local {

            proxy_ssl_verify off;
            proxy_redirect     off;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_pass ${PROXY_LOCAL};
        }
    }
}
EOF

