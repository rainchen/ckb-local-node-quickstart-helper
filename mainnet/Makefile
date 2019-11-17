# Makefile for testnet

.DEFAULT_GOAL:=help
SHELL = /bin/sh

# main receipts
.PHONY: deps help

.SILENT: help

# getting-started: https://docs.nervos.org/getting-started/run-node
# ckb RPC doc: https://github.com/nervosnetwork/ckb/tree/develop/rpc
# refs: https://github.com/nervosnetwork/ckb/blob/develop/docs/run-ckb-with-docker.md

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

define hex2dec
	printf "%d" $(1)
endef

# DEFINE GLOBAL VARIABLES
# get available tags from: https://hub.docker.com/r/nervos/ckb/tags
# get genesis hash from: https://github.com/nervosnetwork/ckb/wiki/Chains
export CKB_BIN_VERSION=v0.25.1
export CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME=ckb-mainnet-node
export CKB_LOCAL_NODE_DIR=ckb-mainnet-node

##@ Dependencies

deps: ## Download the depenedencies.

##@ Cleanup
clean: ## Clean up.
	$(info Cleaning up things)

##@ Start
start: ## Init and Start local node.
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	make init-local-node
	make start-local-node

##@ Manage node

init-local-node: ## init local node for mainnet
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";

	@echo "1) create a dir"
	@mkdir -p $${CKB_LOCAL_NODE_DIR}
	
	@echo "2) Then init the directory with mainnet chain spec."
	@docker run --rm -it -v $${PWD}/$${CKB_LOCAL_NODE_DIR}:/var/lib/ckb nervos/ckb:$${CKB_BIN_VERSION} init --chain mainnet --force
	
	@echo "3) Create a container ckb-mainnet-node to run a node:"
	@if [ "`docker ps -a -q -f name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME}`" == "" ]; then \
		docker create -p 8114:8114 -p 8115:8115 -it -v $${PWD}/$${CKB_LOCAL_NODE_DIR}:/var/lib/ckb --name ${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} nervos/ckb:$${CKB_BIN_VERSION} run ;\
		echo "4) Copy the generated config files from the container:" ;\
		docker cp $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME}:/var/lib/ckb/ckb.toml . ;\
	else \
		echo "already created container $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME}, run 'make start-local-node' to start it" ;\
	fi

start-local-node: ## start local node for mainnet
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	docker start -i $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME}

start-local-node-console: ## debug: enter local_node console
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	docker exec -it $${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} bash
	
stop-local-node: ## stop started local_node
	docker ps -q -f name=$${CKB_LOCAL_NODE_DOCKER_CONTAINER_NAME} | xargs -I @ docker stop @


##@ Quoery data

watch-local-node-info: ## step 7. watch-local-node-info: watch get-local-node-info
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	watch -n 10 -c "make get-local-node-info"

query-local-node-info:
	@printf "%b" "$(OBJ_COLOR)$(@)$(NO_COLOR)\n";
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)check local_node info: node_id addresses version$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"local_node_info","params": []}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r '.result | "\(.node_id)\t\(.addresses)\t\(.version)"'

query-local-node-genesis-block-hash:
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)chain genesis block hash$(NO_COLOR)\n";
	@curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_block_hash","params": ["0x0"]}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r .result

query-local-node-latest-block-number:
	@printf "%b" "$(COM_COLOR)[local_node]$(OBJ_COLOR)latest block number$(NO_COLOR)\n";
	@tip_num=`curl -s -d '{"id": 2, "jsonrpc": "2.0", "method":"get_tip_block_number","params": []}' -H 'content-type:application/json' 'http://127.0.0.1:8114' | jq -r .result` ;\
		$(call hex2dec,$${tip_num})

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


##@ Helpers

help:  ## Display help message.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
