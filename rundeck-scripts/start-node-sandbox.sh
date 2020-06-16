#!/bin/bash
set -e -o pipefail
source "$(dirname $0)/functions"

# This fails if there are no RD_OPTION_ variables and that's fine.
env | grep RD_OPTION_ >/tmp/start-node.env

if [[ "$RD_OPTION_STOP_NODE" == yes ]]; then
	stop-node
fi

running_id="$(docker ps -q -f name='^rnode$')"
if [[ -n "$running_id" ]]; then
	echo "Node is already running"
	exit 0
fi

if [[ -n "$(docker ps -qa -f name='^rnode$')" ]]; then
	archived_name="rnode.$(date +%s)"
	echo "Existing dead container found, renaming to $archived_name"
	docker rename rnode $archived_name >/dev/null
fi

echo "Pulling Docker image $RD_OPTION_RNODE_DOCKER_IMAGE"
docker pull $RD_OPTION_RNODE_DOCKER_IMAGE

mkdir -p /var/lib/rnode /var/lib/rnode/genesis

try_download_file()
(
	local url="$1" dest=$2 mode=${3:-644}
	umask $mode # local to myself, I'm running in sub-process (() vs {})
	if [[ -z $url ]]; then
		touch $dest
	else
		echo "Downloading $url to $dest"
		curl -fsSL -o "$dest" "$url"
	fi
)

try_download_file "$RD_OPTION_WALLETS_FILE_URL" /var/lib/rnode/genesis/wallets.txt
# This is the wallet to pay for deploys during autopropose
# We use one deployer key per validator to test block merging.

#while read pk; do3
#	sk=$(())
#	echo "$sk,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
#done < /var/lib/rnode-static/validator-public-keys.txt
echo "308ec641584F7023ba501df8D352FF237B2894b1,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "479be04F42A070F90149ce9e120c2A1919B87e82,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "fC4e24604A4909EF4BA71A5c731bA96023D0C58f,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "9c41d80AAb8706881AF13628DC24f07579Ee041c,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "2D6167210f68e3DF5FE6b850296ed2C9EdD61977,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "1266e051247D8E174758b6a225264d97B288Fa81,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "2BE25b922BeE4A3aBdAa0a36a4f30C475af21233,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "C9844E6CB546D5883366ffc5C27Df7fE528D299A,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "D68c2A023683f1640a89351fe9fe8639bE935674,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "Ce1349512Fb33116a1c85a7d2e9ecA2C6F9625FF,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "4f6470e48afbbdb590e976658abC1d6Fa661D457,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "95c69be0F44FD0B9e9f8bB5a4B5F9627F15AC649,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "47283796230aFD8be53e003fBFF2746C66cef4a5,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "C8AAbAAFc036ff6Ef13dF9fF1995d34f2005Ba0d,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "D9FCa89D6590F54734a4840828874f1A5E7013F0,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "30AfBBae4C6d794964DD54283B9F65FbF383F051,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "aBB350ACA26af929aE9B6912a55F69997888B6BA,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "bf1E1bE2d58C26B69003b8d63D349b44b0809F51,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "d2Dfd4211bfd377400D144d35982D47D6d6fd1b5,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt
echo "a9a67367CC7c306BF9415bBfc1b606f378de2b11,1000000000000000000,0" >> /var/lib/rnode/genesis/wallets.txt

case $(hostname) in
    "node0")
        echo "0110a3b8e9de821cdb305785fed2a19f36413577b2cd4452736ddacbe0656bba" > /var/lib/rnode-static/deployer.sk
        ;;
	"node1")
        echo "573581921a70bf32580c49614e847ac4b7cebd298ece758707df14cee34e003e" > /var/lib/rnode-static/deployer.sk
        ;;
	"node2")
        echo "26f6939e05b1eedebd2b23d61902d0f5a145a13d4cbb76ed8762df5f64bc2003" > /var/lib/rnode-static/deployer.sk
        ;;
	"node3")
        echo "74403979e0dc14a1be9ecea5a956075b7274a8e0054f70e9d8e80a6951be7fda" > /var/lib/rnode-static/deployer.sk
        ;;
	"node4")
        echo "eb7eab8512361a301c07efa3195b8ffc8c17e55b18f5df7f3e1e8230e4f2413e" > /var/lib/rnode-static/deployer.sk
        ;;
	"node5")
        echo "ff4566482c3df328256a503e4f99df4a0a120c12523293546284f1ef30d7cf4b" > /var/lib/rnode-static/deployer.sk
        ;;
	"node6")
        echo "5329d598b0bd84c20c6c6be0adaf9860c013aa502ad2514421407dd21cf7cb02" > /var/lib/rnode-static/deployer.sk
        ;;
	"node7")
        echo "21f811d96dd4efd6567e8f6a39e6163159e64fe538764168f45cc630513922c2" > /var/lib/rnode-static/deployer.sk
        ;;
	"node8")
        echo "c71cd95d6ebc5df04087c762b7882839e23dae8222d024c40fe0e96c42dc88c3" > /var/lib/rnode-static/deployer.sk
        ;;
	"node9")
        echo "bac5a0b7093ef7fab7828e63614b6d6624807ca733bec003a6312035a0e8d947" > /var/lib/rnode-static/deployer.sk
        ;;
	"node10")
        echo "895ea6487b1eb4ca3941ca257a20d7698cf5a7838fd691fb6d3293df251ca3d1" > /var/lib/rnode-static/deployer.sk
        ;;
	"node11")
        echo "2336eacdc265321b2e129eee9c6aed574fe97291539f02aecf13b1c506a8306a" > /var/lib/rnode-static/deployer.sk
        ;;
	"node12")
        echo "00da6e5d2c7c16e19be35313cffad23dd396149793aa111f83b04cc08bd3eb18" > /var/lib/rnode-static/deployer.sk
        ;;
	"node13")
        echo "7839652ca6baedba7b46efa34a3b5675e3353d8fb7a4ee40d38151f3b980b2b7" > /var/lib/rnode-static/deployer.sk
        ;;
	"node14")
        echo "a2282b2caf2f988b55cbd6ab89cbecf8725384207ea14358d09a1ad7936ff2a1" > /var/lib/rnode-static/deployer.sk
        ;;
	"node15")
        echo "97e0bc1569569e2b08a5e483430dddf34da65dce30c72e5b81752ab6a9886fa4" > /var/lib/rnode-static/deployer.sk
        ;;
	"node16")
        echo "c1f1e1648e66c8e3428d72248b91bbb9882e767f7c30c5a1aa54d642b80cde4f" > /var/lib/rnode-static/deployer.sk
        ;;
	"node17")
        echo "3c5841bb3cc8979a30762efda73e433e83592ccfac3d30dd69e6ec6ee473f1a3" > /var/lib/rnode-static/deployer.sk
        ;;
	"node18")
        echo "33a6cbc3ffa227dfe1e4019c335ee0f2108db38ab612aec6822e957ed0fb1178" > /var/lib/rnode-static/deployer.sk
        ;;
	"node19")
        echo "db32b73bc7343ffbe0be4b4adbfd6daeaf48883810f2a4be62383c7863b41c12" > /var/lib/rnode-static/deployer.sk
        ;;
    *)
        ;;
esac

try_download_file "$RD_OPTION_RNODE_OVERRIDE_CONF_URL" /var/lib/rnode/rnode.override.conf 600

ln -sf /var/lib/rnode-static/node.*.pem /var/lib/rnode/

######################################################################
# create bonds.txt file

bonds_tmp=$(mktemp bonds.txt.XXXXXX)

i=1
while read pk; do
	echo "$pk $((RD_OPTION_BOND_BASE_AMOUNT + 2**i))"
	: $((i++))
done \
	< /var/lib/rnode-static/validator-public-keys.txt \
	> $bonds_tmp

if [[ -n $RD_OPTION_BONDS_FILE_URL ]]; then
	curl -fsSL "$RD_OPTION_BONDS_FILE_URL" |\
		sed 's/^[[:blank:]]*//; s/[[:blank:]]*$//; /^$/d' >>$bonds_tmp
fi

tac $bonds_tmp | awk '!seen[$1]++' | tac >/var/lib/rnode/genesis/bonds.txt
rm $bonds_tmp

######################################################################
# generate config file

merge_rnode_conf_fragments

# Create rnode.redacted.conf with default permissions so that it's
# accessible by nginx. umask should have world readable bit cleared.
jq 'del(.rnode.server.casper."validator-private-key")' \
	< /var/lib/rnode/rnode.conf \
	> /var/lib/rnode/rnode.redacted.conf

######################################################################
# load config file and adjust command line options

parse_rnode_config

if [[
	$rnode_server_standalone != true &&
	-n $rnode_server_bootstrap
]]; then
	eval "$(parse-node-url "$rnode_server_bootstrap" bootstrap_)"
fi

if [[
	$rnode_server_standalone == true ||
	-z $rnode_server_bootstrap ||
	$bootstrap_node_id == $(get_tls_node_id)
]]; then
	rnode_server_standalone=true
	echo "Node is standalone"
else
	bootstrap_ip="$(dig +short $bootstrap_hostname A | tail -1)"
	if [[ -n "$bootstrap_ip" ]]; then
		echo "Node will bootstrap from $bootstrap_hostname ($bootstrap_ip)"
	else
		echo "Failed to resolve bootstrap hostname '$bootstrap_hostname'" >&2
		exit 1
	fi
fi

if [[
	$rnode_casper_required_signatures -gt 0 &&
	$rnode_server_standalone != true 
]]; then
	rnode_casper_genesis_validator=true
fi

######################################################################
# initial network isolation

if ! iptables -L rnode_iblock >/dev/null 2>&1; then
	iptables -N rnode_iblock
fi
if ! iptables -L rnode_oblock >/dev/null 2>&1; then
	iptables -N rnode_oblock
fi
if ! iptables -L rnode_isel >/dev/null 2>&1; then
	iptables -N rnode_isel
	iptables -I INPUT 1 -j rnode_isel
fi
if ! iptables -L rnode_osel >/dev/null 2>&1; then
	iptables -N rnode_osel
	iptables -I OUTPUT 1 -j rnode_osel
fi

iptables -F rnode_iblock
iptables -A rnode_iblock -i lo -j RETURN
if [[ $rnode_server_standalone != true ]]; then
	iptables -A rnode_iblock -p tcp --dport "$rnode_server_port" -s "$bootstrap_ip" -j RETURN
	iptables -A rnode_iblock -p tcp --dport "$rnode_server_port" -j REJECT
elif [[ $rnode_casper_required_signatures -eq 0 ]]; then
	iptables -A rnode_iblock -p tcp --dport "$rnode_server_port" -j REJECT
else
	# Let bootstrap's server port open to any validator when genesis block
	# creation requires non-zero number of signatures. Unauthorized validators
	# are not in bonds.txt so it shouldn't be a problem.
	true
fi
iptables -A rnode_iblock -p tcp --dport "$rnode_server_port_kademlia" -j REJECT
iptables -A rnode_iblock -p tcp --dport "$rnode_grpc_port_external" -j REJECT

iptables -F rnode_oblock
iptables -A rnode_oblock -o lo -j RETURN
iptables -A rnode_oblock -p tcp --dport "$bootstrap_port_kademlia" -j REJECT

iptables -F rnode_isel
iptables -A rnode_isel -j rnode_iblock
iptables -F rnode_osel
iptables -A rnode_osel -j rnode_oblock

######################################################################
# diagnostics setup

network_id="${RD_OPTION_NETWORK_ID:-$rnode_server_network_id}"
echo "Network ID: $network_id"

DIAG_TAG=$(get_current_timestamp).$(sanitize_string "$network_id").$(hostname)
if [[ -n "$RD_OPTION_DUMP_TAG" ]]; then
	DIAG_TAG+=.$(sanitize_string "$RD_OPTION_DUMP_TAG")
fi

mkdir $LOCAL_DIAG_ROOT/$DIAG_TAG
rm -f $DIAG_DIR
ln -s $LOCAL_DIAG_ROOT/$DIAG_TAG $DIAG_DIR

check_diag_directory

mv /tmp/start-node.env $DIAG_DIR/

######################################################################
# BEGIN docker run

docker_args=(
	--name=rnode
	--network=rchain-net
	-p 40400:40400 -p 40402:40402 -p 40404:40404 
	-v /var/lib/rnode:/var/lib/rnode
	-v $DIAG_DIR:$DIAG_DIR
	-v /var/lib/rnode-static:/var/lib/rnode-static:ro
	-v /opt/YourKit-JavaProfiler:/opt/YourKit-JavaProfiler:ro
)

launcher_args=(
	-J-Xss5m
	-XX:+HeapDumpOnOutOfMemoryError
	-XX:HeapDumpPath=$DIAG_DIR/heapdump_OOM.hprof
	-XX:+ExitOnOutOfMemoryError
	-XX:ErrorFile=$DIAG_DIR/hs_err.log
	-XX:MaxJavaStackTraceDepth=100000
	-Dlogback.configurationFile=/var/lib/rnode-static/logback.xml
	-c /var/lib/rnode/rnode.conf
	$(get_rnode_launcher_args)
)

run_args=(
	--network-id "$network_id"
	$(get_rnode_run_args)
)

if [[ $RD_OPTION_DEBUG == yes ]]; then
	mkdir $DIAG_DIR/YourKit
	launcher_args+=(
		-J-Xdebug
		-J-Xrunjdwp:transport=dt_socket,address=127.0.0.1:8888,server=y,suspend=n
		-J-agentpath:/opt/YourKit-JavaProfiler/bin/linux-x86-64/libyjpagent.so=port=10001,listen=all,sessionname=$DIAG_TAG,dir=$DIAG_DIR/YourKit,logdir=$DIAG_DIR/YourKit
		-XX:NativeMemoryTracking=detail
	)
fi

if [[ -f /var/lib/rnode-static/environment.docker ]]; then
	docker_args+=(--env-file=/var/lib/rnode-static/environment.docker)
fi

if [[ -f /var/lib/rnode-static/local.env ]]; then
	source /var/lib/rnode-static/local.env
fi

# Create docker named bride if it doesn't exist
docker_net="$(docker network ls -q -f name='rchain-net')"
if [[ -z "$docker_net" ]]; then
	echo "Create docker named network"
	docker network create rchain-net
fi

logcmd docker run -d \
	${docker_args[@]}  \
	"$RD_OPTION_RNODE_DOCKER_IMAGE" \
	${launcher_args[@]} \
	run ${run_args[@]}
	>/dev/null

# END docker run
######################################################################

i=2
sleep_time=5
echo "Waiting $((i*sleep_time))s for RNode to start"

# Provision nginx proxy if not already installed
proxy_id="$(docker ps -q -f name=revproxy)"
if [[ -z "$proxy_id" ]]; then
	echo "Install nginx reverse proxy for gRPC & HTTPS"
	provision_nginx_proxy.sh
fi

while (( i )); do
	container_id="$(docker ps -q -f name=rnode)"
	if [[ -n "$container_id" ]]; then
		echo "RNode is running"
		nohup docker logs -f $container_id &> $DIAG_DIR/console.log &

		node_pid="$(docker inspect -f '{{.State.Pid}}' rnode || echo 0)"
		if (( node_pid )); then
			influx_host=$(grep influx_host /opt/rchain-testnet-node/scripts/scripts.conf | cut -d':' -f2)
			influx_port=$(grep influx_port /opt/rchain-testnet-node/scripts/scripts.conf | cut -d':' -f2)
			nohup $INSTALL_DIR/pmap.py "$node_pid" "$influx_host" "$influx_port" "$network_id" >/dev/null 2>&1 &
		fi
		break
	fi

	sleep $sleep_time
	: $((i--))
done

wait_time_left="${RD_OPTION_WAIT_TIME:-600}"
sleep_time=10
echo "Waiting ${wait_time_left}s for approved block"

while (( wait_time_left > 0 )); do
	if [[ -z "$(docker ps -q -f ID=$container_id)" ]]; then
		echo "RNode is not running" >&2
		if [[ -n "$(docker ps -aq -f ID=$container_id)" ]]; then
			echo "----- BEGIN RNODE OUTPUT -----" >&2
			docker logs $container_id >&2 || true
			echo "----- END RNODE OUTPUT -----" >&2
		fi
		exit 1
	fi

	height="$(docker exec $container_id ./bin/rnode show-blocks |\
		sed -n '/^count: /{s///;p;q}')" || true
	if (( height )); then
		echo "Found approved block"
		break
	fi

	sleep $sleep_time
	: $(( wait_time_left -= sleep_time ))
done

if (( wait_time_left <= 0 )); then
	echo "Did not find approved block" >&2
	exit 1
fi

iptables -F rnode_isel
iptables -F rnode_osel

echo Finished
