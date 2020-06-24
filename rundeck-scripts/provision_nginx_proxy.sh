#!/bin/bash 
#
# Enable HTTPS & gRPC reverse-proxy support for rnode
# 1) If SSL certs don't exist, install `certbot` and get SSL certs.  Certbot runs standalone server on port 80, which should be open at the firewall.
# 2) Create nginx conf if it doesn't exist
# using certbot script and installing docerkized nginx reverse-proxy.

HOST_NAME=`hostname -f`
EMAIL_ADDR="rchain_sre@rchain.coop"
RNODE_NGINX_DIR="/var/lib/rnode-static/nginx"
RNODE_LOG_DIR="/var/lib/rnode-diag/current/nginx"

set -e

if [[ ${HOST_NAME} =~ ".internal" ]]; then
        if [ $# != 1 ]; then
                echo "$0: Host has internal domain, run $0 with an external hostname"
                exit 
        fi
        HOST_NAME=$1
fi

if [[ -d "/etc/letsencrypt/live/${HOST_NAME}" ]]; then
	echo "$0: SSL certs detected, skipping certbot install & SSL certs provisioning."
else
	echo "$0: Installing certbot.../etc/letsencrypt/live/${HOST_NAME}"
	apt update 
	apt -y install certbot

	# Certbot standalone creates temp webserver on port 80 which is also used every 3 months for renewal.
	echo "$0: Getting SSL certs..."
	certbot certonly -n --standalone --agree-tos -d ${HOST_NAME} --email ${EMAIL_ADDR}
fi

# Restart nginx when letsencrypt renews the SSL cert
if [[ ! -f /etc/letsencrypt/renewal-hooks/deploy/restart-docker-nginx.sh ]]; then
  echo "$0: Creating letsencrypt post renewal script..."
  cat <<EOF >/etc/letsencrypt/renewal-hooks/deploy/restart-docker-nginx.sh
#!/bin/bash
docker restart revproxy
EOF
  chmod 754 /etc/letsencrypt/renewal-hooks/deploy/restart-docker-nginx.sh
fi

# Create reverse-proxy config file
if [[ -d ${RNODE_NGINX_DIR} ]]; then 
	echo "$0: nginx config detected, skip creating it"
else
	echo "$0: Creating nginx config..."
	mkdir -p ${RNODE_NGINX_DIR}
	if [[ ! -d ${RNODE_LOG_DIR} ]]; then 
		mkdir -p ${RNODE_LOG_DIR}
	fi

  # Build a nginx conf file
  cat <<EOF >${RNODE_NGINX_DIR}/reverse-proxy.conf
    # Redirect all requests to port 40403(http api) to port 443(https api)
    server {
        listen 40403;
        server_name ${HOST_NAME};
        return 301 https://\$host\$request_uri;
    }

    # Proxy 443(https api) for docker internal address rnode:40403
    server {
        listen [::]:443 ssl ipv6only=on;
        listen 443 ssl;
        access_log /var/log/nginx/access-https.log;
        error_log  /var/log/nginx/error-https.log;
        root   /usr/share/nginx/html;
        index index.html;
        server_name ${HOST_NAME};
        location / {
           proxy_pass http://rnode:40403;
        }
        ssl_certificate /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;
    }

    # Proxy 40401(grpc external api) for docker's rnode:40401, primarily to capture api calls
    server {
        listen 40401 http2;
        access_log /var/log/nginx/access-grpc.log;
        error_log /var/log/nginx/error-grpc.log;

	# https://nginx.org/en/docs/http/ngx_http_grpc_module.html
	grpc_read_timeout 3600s;
	grpc_send_timeout 3600s;

        location / {
            grpc_pass grpc://rnode:40401;
        }
    }

    # Proxy port 40411(grpcs) for port 40401(grpc) 
    server {
        listen 40411 ssl http2;
        access_log /var/log/nginx/access-grpcs.log;
        error_log /var/log/nginx/error-grpcs.log;

        # https://nginx.org/en/docs/http/ngx_http_grpc_module.html
        grpc_read_timeout 3600s;
        grpc_send_timeout 3600s;

        location / {
            grpc_pass grpc://rnode:40401;
        }
        ssl_certificate /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;
    }
EOF
fi

docker_nginx="`docker ps -a | grep nginx|cut -d' ' -f1`"
if [[ -n "$docker_nginx" ]]; then
	echo "$0: Remove old nginx container<${docker_nginx}>, and start a new one..."
	docker stop ${docker_nginx} && docker rm ${docker_nginx}
fi

echo "$0: Starting revproxy container..."
if [[ "$RD_OPTION_CONFIG_V2" == yes ]]; then
	(cd /var/lib/rnode;docker-compose up -d revproxy)
else
	docker run -d  --name revproxy --network rchain-net \
		-p 443:443  -p 40401:40401 -p 40403:40403 -p 40411:40411 \
		-v ${RNODE_NGINX_DIR}:/etc/nginx/conf.d:ro \
		-v /etc/letsencrypt:/etc/letsencrypt:ro \
		-v ${RNODE_LOG_DIR}:/var/log/nginx \
		nginx
fi
