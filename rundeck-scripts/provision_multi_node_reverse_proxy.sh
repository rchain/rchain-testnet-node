#!/bin/bash 
#
# Enable HTTPS & gRPC reverse-proxy support for rnode
# 1) If SSL cert  for the host doesn't exist, install `certbot` and get SSL certs.  Certbot runs standalone server on port 80, which should be open at the firewall.
# 2) Create nginx conf if it doesn't exist
# using certbot script and installing docerkized nginx reverse-proxy.

set -e 

SCRIPT_NAME=$(basename $0)

RNODE_NETWORK="$1"
RNODE_NAME="$2"
HOST_NAME="$3"
STARTING_PORT="$4"

SRE_EMAIL_ADDR="rchain_sre@rchain.coop"

RNODE_NETWORK_DIR="/rchain/${RNODE_NETWORK}"
RNODE_DIR="${RNODE_NETWORK_DIR}/${RNODE_NAME}"
RNODE_CONTAINER_NAME="${RNODE_NETWORK}-${RNODE_NAME}"

REVPROXY_CONTAINER_NAME="${RNODE_NETWORK}-revproxy"
REVPROXY_CONF_FILE="${RNODE_NETWORK_DIR}/revproxy/conf/${RNODE_NAME}.conf"
REVPROXY_LOG_DIR="${RNODE_NETWORK_DIR}/revproxy/log/${RNODE_NAME}"

set -e

if [ $# -ne 4 ]; then
	echo "usage: ${SCRIPT_NAME} <rnode_network> <rnode_name> <cert hostname> <starting_port>"
        exit 
fi

if [[ -d "/etc/letsencrypt/live/${HOST_NAME}" ]]; then
	echo "${SCRIPT_NAME}: SSL certs detected, skipping certbot install & SSL certs provisioning."
else
	echo "${SCRIPT_NAME}: Installing certbot.../etc/letsencrypt/live/${HOST_NAME}"
	apt update 
	apt -y install certbot

	# Certbot standalone creates temp webserver on port 80 which is also used every 3 months for renewal.
	echo "${SCRIPT_NAME}: Getting SSL certs..."
	certbot certonly -n --standalone --agree-tos -d ${HOST_NAME} --email ${SRE_EMAIL_ADDR}
fi

# Install script to Restart nginx when letsencrypt renews the SSL cert
REVPROXY_RESTART_SCRIPT="/etc/letsencrypt/renewal-hooks/deploy/restart-${REVPROXY_CONTAINER_NAME}.sh"
if [[ ! -f ${REVPROXY_RESTART_SCRIPT} ]]; then
  echo "${SCRIPT_NAME}: Creating letsencrypt post renewal script..."
  cat <<EOF >${REVPROXY_RESTART_SCRIPT}
#!/bin/bash
docker restart ${REVPROXY_CONTAINER_NAME}
EOF
  chmod 754 ${REVPROXY_RESTART_SCRIPT}
fi

# Create reverse-proxy config file
if [[ -d ${REVPROXY_CONF_FILE} ]]; then 
	echo "${SCRIPT_NAME}: nginx config detected, skip creating it"
else
	echo "${SCRIPT_NAME}: Creating nginx config..."
	if [[ ! -d $(dirname ${REVPROXY_CONF_FILE}) ]]; then 
		mkdir -p $(dirname ${REVPROXY_CONF_FILE})
	fi
	if [[ ! -d ${REVPROXY_LOG_DIR} ]]; then 
		mkdir -p ${REVPROXY_LOG_DIR}
	fi

  # Build a nginx conf file
  cat <<EOF >${REVPROXY_CONF_FILE}
    # Redirect all requests to http-api to https-api port
    server {
    listen $(expr $STARTING_PORT + 403);
        server_name ${HOST_NAME};
        return 301 https://\$host\$request_uri;
    }

    # Proxy https-api port to rnode's docker internal address(443)
    server {
    listen $(expr $STARTING_PORT + 443) ssl;
        access_log /var/log/nginx/${RNODE_NAME}/access-https.log;
        error_log  /var/log/nginx/${RNODE_NAME}/error-https.log;
        root   /usr/share/nginx/html;
        index index.html;
        server_name ${HOST_NAME};
        location / {
           proxy_pass http://${RNODE_CONTAINER_NAME}:40403;
        }
        ssl_certificate /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;
    }

    # Proxy grpc-external-api port to rnode's docker,  primarily to capture api calls(40401)
    server {
    listen $(expr $STARTING_PORT + 401) http2;
	access_log /var/log/nginx/${RNODE_NAME}/access-grpc.log;
        error_log  /var/log/nginx/${RNODE_NAME}/error-grpc.log;

	# https://nginx.org/en/docs/http/ngx_http_grpc_module.html
	grpc_read_timeout 3600s;
	grpc_send_timeout 3600s;

        location / {
            grpc_pass grpc://${RNODE_CONTAINER_NAME}:40401;
        }
    }

    # SSL enable external-grpc-api port(40411)
    server {
	listen $(expr $STARTING_PORT + 411) ssl http2;
	access_log /var/log/nginx/${RNODE_NAME}/access-grpcs.log;
        error_log  /var/log/nginx/${RNODE_NAME}/error-grpcs.log;

	# https://nginx.org/en/docs/http/ngx_http_grpc_module.html
	grpc_read_timeout 3600s;
        grpc_send_timeout 3600s;

        location / {
            grpc_pass grpc://${RNODE_CONTAINER_NAME}:40401;
        }
        ssl_certificate /etc/letsencrypt/live/${HOST_NAME}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${HOST_NAME}/privkey.pem;
    }
EOF
fi

docker_nginx="`docker ps -a | grep ${REVPROXY_CONTAINER_NAME}|cut -d' ' -f1`"
if [[ -n "$docker_nginx" ]]; then
	echo "${SCRIPT_NAME}: Stop and remove old nginx container <${docker_nginx}>..."
	docker stop ${docker_nginx} && docker rm ${docker_nginx}
fi

echo "${SCRIPT_NAME}: Starting revproxy container..."
(cd ${RNODE_NETWORK_DIR};docker-compose up -d ${REVPROXY_CONTAINER_NAME})

echo "${SCRIPT_NAME}: All done!"
