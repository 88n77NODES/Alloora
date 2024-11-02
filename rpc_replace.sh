#!/bin/bash

green='\033[0;32m'
nc='\033[0m'

echo -e "${green}Запускаємо скрипт на зміну RPC...${nc}"

sleep 2

cd basic-coin-prediction-node
python3 script.py

echo -e "${green}Перевірити логи...${nc}"
docker logs -f worker