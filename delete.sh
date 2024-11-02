#!/bin/bash

green='\033[0;32m'
nc='\033[0m'

echo -e "${green}Видаляємо...${nc}"

docker stop worker-basic-eth-pred updater-basic-eth-pred head-basic-eth-pred inference-basic-eth-pred
docker rm worker-basic-eth-pred updater-basic-eth-pred head-basic-eth-pred inference-basic-eth-pred
docker rmi basic-coin-prediction-node-inference basic-coin-prediction-node-updater basic-coin-prediction-node-worker

rm -rf basic-coin-prediction-node

docker stop offchain_node offchain_source
docker rm offchain_node offchain_source
docker rmi allora-offchain-source docker rmi allora-offchain-node-node
rm -rf allora-offchain-node
rm -rf allora-chain
docker rmi allora-offchain-node-source
docker stop offchain_node offchain_source
docker container prune
docker image prune -a
rm -rf allora-offchain-node
rm -rf allora-chain
rm -rf basic-coin