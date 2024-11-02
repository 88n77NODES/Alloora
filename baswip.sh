#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

check_command() {
    if [ $? -ne 0 ]; then
        echo -e "${red}Помилка: ${1} не виконано!${nc}"
        exit 1
    else
        echo -e "${green}${1} успішно виконано.${nc}"
    fi
}

confirm_action() {
    while true; do
        read -p "$1 (y/n): " yn
        case $yn in
            [Yy]* ) break;;
            [Nn]* ) echo -e "${red}Дія скасована.${nc}"; exit 1;;
            * ) echo "Будь ласка, введіть y або n.";;
        esac
    done
}

install_docker_compose() {
    echo -e "${green}Встановлюємо Docker Compose...${nc}"
    sudo apt-get install docker-compose -y
    check_command "Docker Compose встановлено"
}

# Основна частина скрипту
echo -e "${green}Встановлення базової моделі...${nc}"

cd $HOME/basic-coin-prediction-node

sudo apt install nano -y
check_command "Nano встановлено"

echo -e "${green}Налаштовуємо .env файл...${nc}"
touch .env

# Запит значень
declare -A env_vars=( 
    [TOKEN]="ETH"
    [TRAINING_DAYS]="30"
    [TIMEFRAME]="4h"
    [MODEL]="SVR"
    [REGION]="US"
    [DATA_PROVIDER]="binance"
    [CG_API_KEY]=""
)

for var in "${!env_vars[@]}"; do
    read -p "Введіть значення для $var (${env_vars[$var]}): " input
    echo "$var=${input:-${env_vars[$var]}}" >> .env
done

echo -e "${green}Ваш файл .env:${nc}"
cat .env
confirm_action "Чи правильно вказані дані у файлі .env?"

# Перевірка наявності docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${red}Файл docker-compose.yml не знайдено.${nc}"
    install_docker_compose
fi

# Налаштування config.json
echo -e "${green}Налаштовуємо свій config.json...${nc}"
[ -f "config.json" ] && rm config.json

read -p "Введіть назву гаманця: " address_key_name
read -p "Введіть сід-фразу: " address_restore_mnemonic
read -p "Введіть RPC URL: " node_rpc
read -p "Введіть IP адрес сервера для InferenceEndpoint: " server_ip

# Створюємо config.json
cat <<EOF > config.json
{
    "wallet": {
        "addressKeyName": "${address_key_name}",
        "addressRestoreMnemonic": "${address_restore_mnemonic}",
        "alloraHomeDir": "",
        "gas": "auto",
        "gasAdjustment": 1.5,
        "nodeRpc": "${node_rpc}",
        "maxRetries": 1,
        "delay": 1,
        "submitTx": true
    },
    "worker": [
        {
            "topicId": 1,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 2,
            "parameters": {
                "InferenceEndpoint": "http://${server_ip}:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 4,
            "parameters": {
                "InferenceEndpoint": "http://${server_ip}:8000/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 6,
            "parameters": {
                "InferenceEndpoint": "http://${server_ip}:8000/inference/{Token}",
                "Token": "ETH"
            }
        }
    ]
}
EOF

check_command "config.json файл створено"
echo -e "${green}Ваш файл config.json:${nc}"
cat config.json
confirm_action "У файлі config.json все вірно?"

chmod +x init.config
./init.config

echo -e "${green}Запускаємо worker...${nc}"
docker compose pull
docker compose up --build -d
check_command "Worker запущено"

echo -e "${green}Перевірка логів worker...${nc}"
docker logs -f worker
