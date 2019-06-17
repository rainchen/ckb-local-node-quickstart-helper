.DEFAULT_GOAL:=help
SHELL = /bin/sh

# main receipts
.PHONY: deps help

.SILENT: help

# getting-started: https://docs.nervos.org/getting-started/run-node
# ckb RPC doc: https://github.com/nervosnetwork/ckb/tree/develop/rpc

# DETECT OS
OSFLAG :=
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	OSFLAG += LINUX
endif
ifeq ($(UNAME_S),Darwin)
	OSFLAG += OSX
endif

# DEFINE COLOR VARIABLES 
COM_COLOR   = \033[0;34m
OBJ_COLOR   = \033[0;36m
OK_COLOR    = \033[0;32m
ERROR_COLOR = \033[0;31m
WARN_COLOR  = \033[0;33m
NO_COLOR    = \033[m

# DEFINE COMMON USED STRING
OK_STRING    = "[OK]"
ERROR_STRING = "[ERROR]"
WARN_STRING  = "[WARNING]"

# MESSAGE EXAMPLE
# @$(info info-message)
# @$(warning warning-message)
# @$(error error-and-stop)

# DEFINE FUNCTIONS

# genreate a random key pair which PrivKey is 64 bytes hex string, e.g.: 
# PrivKey: 799f46e9be....
# PubKey: 04d1950e3d069cb2c....
define generate_wallet_prikey
	openssl ecparam -genkey -name secp256k1 -text -noout -outform DER | \
		xxd -p -c 1000 | \
		sed 's/41534e31204f49443a20736563703235366b310a30740201010420/PrivKey: /' | \
		sed 's/a00706052b8104000aa144034200/\'$$'\nPubKey: /'
endef

define get_wallet_pubkey
	cat $${CKB_WALLET_PRIKEY_FILE} | grep PubKey | cut -d ' ' -f 2
endef

define get_wallet_prikey
	cat $${CKB_WALLET_PRIKEY_FILE} | grep PrivKey | cut -d ' ' -f 2
endef

define run_ckb_bin
	docker run --rm -it $${CKB_DOCKER_IMAGE_NAME} $(1)
endef

# DEFINE GLOBAL VARIABLES
# get available tags from https://hub.docker.com/r/nervos/ckb/tags
export CKB_DOCKER_IMAGE_NAME=nervos/ckb:v0.14.0
export CKB_WALLET_DIR=mywallet
export CKB_WALLET_PRIKEY_FILE=${CKB_WALLET_DIR}/wallet_prikey
export CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME=my_local_ckb_node
export CKB_TESTNET_NODE_RPC_URL=1.2.3.4:8114


# DEFINE RECEIPES

##@ Install
install: ## insall
	bundle install

##@ Quip Start

start: ## start all steps
	make step-1
	make step-2
	make step-3

step-1: ## generate wallet prikey & setup local_node
	$(MAKE) install
	$(MAKE) generate-wallet-prikey
	$(MAKE) stop-local-node
	$(MAKE) setup-local-node
	$(MAKE) start-local-node DETACHED=true

step-2: ## setup local_miner & restart local_node
	$(MAKE) setup-local-miner
	@echo "restart local_node"
	$(MAKE) stop-local-node
	$(MAKE) start-local-node DETACHED=true

step-3: ## start local_miner
	@echo "run [make watch-local-node-info] (in a new window) to watch node & wallet info"
	$(MAKE) check-local-miner-wallet-info
	$(MAKE) start-local-miner

##@ Debug Helpers

ckb-bin-help: ## show help for ckb
	$(call run_ckb_bin, --help)

ckb-bin-version: ## check ckb in version, e.g.: ckb 0.12.0-pre (rylai30-dirty 2019-05-16)
	$(call run_ckb_bin, --version)

console: ## enter a Bash console, support CKB_DOCKER_IMAGE_TAG_NAME env
	@echo "[console] enter a Bash console of container"
	@docker run --rm -it -w=/home/ckb -v $${PWD}:/home/ckb/ --entrypoint "/bin/bash" --name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} $${CKB_DOCKER_IMAGE_NAME} -c "bash"

##@ local_node

# steps:
# 1. generate-wallet-prikey
# 2. setup-local-node or setup-local-node-with-bootnodes
# 3. start-local-node
# 4. setup-local-miner (in a new window)
# 5. restart local node: start-local-node
# 6. start-local-miner (in a new window)
# 7. watch-local-node-info (in a new window)

generate-wallet-prikey: ## step 1. generate a new wallet private key
	@echo [generate_wallet_prikey] to $${CKB_WALLET_PRIKEY_FILE}
	mkdir -p $${CKB_WALLET_DIR}
	@if [ -e $${CKB_WALLET_PRIKEY_FILE} ]; then \
	  echo "${CKB_WALLET_PRIKEY_FILE} exists" ;\
	else \
	  $(call generate_wallet_prikey) > $${CKB_WALLET_PRIKEY_FILE} ;\
	  echo "prikey saved to $${CKB_WALLET_PRIKEY_FILE}" ;\
	fi

setup-local-node: ## step 2. setup-local-node: create a local_node config dir
	@echo [local_node] setup a local node that can join CKB testnet 
	@docker run --rm -it -w=/home/ckb -v $${PWD}:/home/ckb/ --entrypoint "/bin/bash" --name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} $${CKB_DOCKER_IMAGE_NAME} -c " \
		ckb --version ;\
		echo 'init ckb-testnet node and miner config' ;\
		test -e ckb-testnet || ckb init -C ckb-testnet --spec testnet ;\
		echo 'created ckb-testnet/ dir' ;\
		sed -i "s/127.0.0.1:8114/0.0.0.0:8114/" ckb-testnet/ckb.toml ;\
		echo 'next step: run [make start-local-node] to start node' ;\
		echo 'then run [make setup-local-miner] in a new window to setup [block_assembler] in ckb-testnet/ckb.toml' ;\
		echo 'use ctrl + c to stop' ;\
		echo '' ;\
	"

setup-local-node-with-bootnodes: ## step 2. setup a local_node with bootnodes.toml config, bootnodes.toml file is required
	@echo [local_node] setup a local node that can join CKB testnet 
	@docker run --rm -it -w=/home/ckb -v $${PWD}:/home/ckb/ --entrypoint "/bin/bash" --name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} $${CKB_DOCKER_IMAGE_NAME} -c " \
		ckb --version ;\
		echo 'init ckb-testnet node and miner config' ;\
		test -e ckb-testnet || ckb init -C ckb-testnet --spec testnet ;\
		echo 'config bootnodes to ckb.toml' ;\
		test -e ckb-testnet/ckb.toml.bak || sed -i.bak -e '/bootnodes =/{r bootnodes.toml' -e 'd}' ckb-testnet/ckb.toml ;\
		echo 'done' ;\
	"

start-local-node: ## step 3. start-local-node: start local_node, allowing passing DETACHED=true to run container in the background
	@echo [local_node] start a node that can join testnet 
	@docker run -d=$${DETACHED:=false} -p 8114:8114 -p 8115:8115 --rm -it -w=/home/ckb -v $${PWD}:/home/ckb/ --entrypoint "/bin/bash" --name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} $${CKB_DOCKER_IMAGE_NAME} -c " \
		ckb --version ;\
		echo 'start node' ;\
		cd ckb-testnet ;\
		pwd ;\
		ckb run ;\
	"

stop-local-node: ## stop started local_node
	docker ps -q -f name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} | xargs -I @ docker stop @

start-local-node-console: ## debug: enter local_node console
	@echo [local_node] start a node that can join testnet 
	docker exec -it $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} bash

get-block-assembler-config: ## ckb cli secp256k1-lock <pubkey>
	@eval pubkey=`$(get_wallet_pubkey)` ;\
		echo "# block_assembler config for pubkey: $${pubkey}" ;\
		$(call run_ckb_bin, cli secp256k1-lock $${pubkey})

setup-local-miner: ## step 4. setup-local-miner: setup local miner config
	@echo setup-local-miner
	# if not exists block_assembler.toml then genereate using "make get-block-assembler-config"
	#   and replace it in ckb-testnet/ckb.toml
	@$(MAKE) get-block-assembler-config > $${CKB_WALLET_DIR}/block_assembler.toml ;\
	 	ckb_toml=ckb-testnet/ckb.toml ;\
		 	sed -i -e "s/^# \[block_assembler\]/[block_assembler]/" $${ckb_toml} ;\
			_args=`cat ${CKB_WALLET_DIR}/block_assembler.toml | grep "^args"` ;\
				sed -i -e "s/args =.*/$${_args}/" $${ckb_toml} ;\
				sed -i -e "s/^# args/args/" $${ckb_toml} ;\
			_code_hash=`cat ${CKB_WALLET_DIR}/block_assembler.toml | grep code_hash` ;\
				sed -i -e "s/^# code_hash =.*/$${_code_hash}/" $${ckb_toml} ;\
		echo "Done! check $${CKB_WALLET_DIR}/block_assembler.toml for sure." ;\
		echo "Next step: restart local_node [make start-local-node]" ;\
		echo "     then: start local_miner [make start-local-miner] in new window" ;\
		echo "     then: watch local_node [make watch-local-node-info] in new window"

start-local-miner: ## step 6. start-local-miner: start local node miner, using the same container as local_node
	@printf "%b" "$(COM_COLOR)[local_miner]$(OBJ_COLOR)start a miner that can join testnet$(NO_COLOR)\n";
	docker exec -it $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} bash -c "cd ckb-testnet; ckb miner"

watch-local-node-info: ## step 7. watch-local-node-info: watch get-local-node-info
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	watch -n 10 -c "make get-local-node-info"

check-local-miner-wallet-info: ## check wallet balance, get_unspent_cells length of local node miner
	@printf "%b" "$(COM_COLOR)[local_miner]$(OBJ_COLOR)check wallet balance of local node miner$(NO_COLOR)\n";
	@ruby wallet_helper.rb wallet_get_balance

query-local-node-info:
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)check local_node info: node_id addresses version$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"local_node_info","params": []}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r '.result | "\(.node_id)\t\(.addresses)\t\(.version)"'

query-local-node-genesis-block-hash:
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)chain genesis block hash$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_block_hash","params": ["0"]}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r .result

query-local-node-latest-block-number:
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)latest block number$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_tip_block_number","params": []}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r .result

get-local-node-peers: # get local_node peers info
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)check local_node connected peers: node_id addresses version$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_peers","params": []}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r '.result[] | "\(.node_id)\t\(.addresses)\t\(.version)"'

get-local-node-info: ## get local_node genesis-block-hash,latest-block-number,local-miner-wallet-info,local-node-peers
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	@make query-local-node-info

	@echo
	@make query-local-node-genesis-block-hash
	@make query-local-node-latest-block-number

	@echo
	@make check-local-miner-wallet-info

	@echo
	@make get-local-node-peers

	@# @echo
	@# @echo "CKB_TESTNET_NODE_RPC_URL: $${CKB_TESTNET_NODE_RPC_URL}"

	@# @make get-testnet-node-genesis-block-hash
	@# @make get-testnet-node-latest-block-number

	@echo
	@@[ -x "$$(command -v istats)" ] && make local-miner-healthy

##@ testnet_node

get-testnet-node-genesis-block-hash: ## get-testnet-node-genesis-block-hash
	@printf "%b" "$(COM_COLOR)[testnet]$(OBJ_COLOR)chain genesis block hash$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_block_hash","params": ["0"]}' -H 'content-type:application/json' $${CKB_TESTNET_NODE_RPC_URL} | jq -r .result

get-testnet-node-latest-block-number: ## get-testnet-node-latest-block-number
	@printf "%b" "$(COM_COLOR)[testnet]$(OBJ_COLOR)latest block number$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_tip_block_number","params": []}' -H 'content-type:application/json' $${CKB_TESTNET_NODE_RPC_URL} | jq -r .result

##@ local_miner
make local-miner-healthy:
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	@make miner-cpu-temp

miner-cpu-temp: ## get CPU temperature
	@[ -x "$$(command -v istats)" ] || gem install iStats
	@istats | grep -E "CPU temp"	

##@ Helpers

help:  ## Display help message.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
