# CKB quick start to run a local node & minder

## Install dependencies

`make install`

## Style A: Quick Start Steps

1. `make step-1`: generate wallet prikey & setup local_node
2. `make step-2`: setup local_miner & restart local_node
3. `make step-3`: start local_miner

Run above commands in different Terminal windows.

Run `make watch-local-node-info` to watch node & wallet info

## Style B: Step by Step

1. make generate-wallet-prikey
2. make setup-local-node or setup-local-node-with-bootnodes
3. make start-local-node
4. make setup-local-miner (in a new window)
5. restart local node: ctrl+c & make start-local-node
6. make start-local-miner (in a new window)
7. make watch-local-node-info (in a new window)

## Notes

* Only tested on macOS
