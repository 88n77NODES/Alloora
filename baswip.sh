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

echo -e "${green}Встановлення базової моделі...${nc}"

echo -e "${green}Встановлюємо редактор nano...${nc}"
sudo apt install nano -y
check_command "Nano встановлено"

# Створюємо .env файл та запитуємо значення
echo -e "${green}Налаштовуємо .env файл...${nc}"

touch .env

read -p "Введіть значення для TOKEN (ETH): " token
token=${token:-ETH}

read -p "Введіть значення для TRAINING_DAYS (30): " training_days
training_days=${training_days:-30}

read -p "Введіть значення для TIMEFRAME (4h): " timeframe
timeframe=${timeframe:-4h}

read -p "Введіть значення для MODEL (SVR): " model
model=${model:-SVR}

read -p "Введіть значення для REGION (US): " region
region=${region:-US}

read -p "Введіть значення для DATA_PROVIDER (binance): " data_provider
data_provider=${data_provider:-binance}

read -p "Введіть значення для CG_API_KEY (вказуємо coingecko api): " cg_api_key
cg_api_key=${cg_api_key:-}

echo "TOKEN=$token" >> .env
echo "TRAINING_DAYS=$training_days" >> .env
echo "TIMEFRAME=$timeframe" >> .env
echo "MODEL=$model" >> .env
echo "REGION=$region" >> .env
echo "DATA_PROVIDER=$data_provider" >> .env
echo "CG_API_KEY=$cg_api_key" >> .env

echo -e "${green}Ваш файл .env:${nc}"
cat .env

confirm_action "Чи правильно вказані дані у файлі .env?"

# Перевіряємо, чи існує docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${red}Файл docker-compose.yml не знайдено.${nc}"
    install_docker_compose
fi

echo -e "${green}Налаштовуємо свій config.json...${nc}"

# Видаляємо старий config.json, якщо існує
if [ -f "config.json" ]; then
    rm config.json
fi

# Запитуємо користувача на назву гаманця, сід-фразу та RPC URL
read -p "Введіть назву гаманця (YourWalletName): " address_key_name
read -p "Введіть сід-фразу (YourSeedPhrase): " address_restore_mnemonic
read -p "Введіть значення для nodeRpc (RPC URL): " node_rpc
read -p "Введіть IP адрес сервера для InferenceEndpoint: " server_ip

# Створюємо новий config.json файл
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

cd $HOME && cd basic-coin-prediction-node
cp config.example.json config.json

echo -e "${green}Ініціалізуємо воркера...${nc}"
if [ -f "init.config" ]; then
    chmod +x init.config
    ./init.config
    check_command "Ініціалізація воркера"
else
    echo -e "${red}Файл init.config не знайдено!${nc}"
    exit 1
fi

echo -e "${green}Запускаємо worker...${nc}"
docker compose pull
docker compose up --build -d
check_command "Worker запущено"

echo -e "${green}Перевірка логів worker...${nc}"
docker logs -f worker
