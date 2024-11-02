#!/bin/bash

green='\033[0;32m'
nc='\033[0m'
red='\033[0;31m'

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
token=${token:-ETH}  # Використовуємо стандартне значення ETH, якщо не введено

read -p "Введіть значення для TRAINING_DAYS (30): " training_days
training_days=${training_days:-30}  # Використовуємо стандартне значення 30, якщо не введено

read -p "Введіть значення для TIMEFRAME (4h): " timeframe
timeframe=${timeframe:-4h}  # Використовуємо стандартне значення 4h, якщо не введено

read -p "Введіть значення для MODEL (SVR): " model
model=${model:-SVR}  # Використовуємо стандартне значення SVR, якщо не введено

read -p "Введіть значення для REGION (US): " region
region=${region:-US}  # Використовуємо стандартне значення US, якщо не введено

read -p "Введіть значення для DATA_PROVIDER (binance): " data_provider
data_provider=${data_provider:-binance}  # Використовуємо стандартне значення binance, якщо не введено

read -p "Введіть значення для CG_API_KEY (вказуємо coingecko api): " cg_api_key
cg_api_key=${cg_api_key:-}  # Якщо значення не введено, залишається пустим

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

# Створюємо config.json файл та запитуємо значення
echo -e "${green}Налаштовуємо config.json файл...${nc}"

read -p "Введіть значення для nodeRpc: " node_rpc
read -p "Введіть значення для wallet.address: " wallet_address

cat <<EOF > config.json
{
    "wallet": {
        "nodeRpc": "$node_rpc",
        "address": "$wallet_address"
    }
}
EOF

check_command "config.json файл створено"

echo -e "${green}Будь ласка, відредагуйте config.json файл.${nc}"
nano config.json

confirm_action "Чи ви зберегли файл config.json і чи все вірно?"

echo -e "${green}Налаштовуємо скрипт для заміни RPC...${nc}"
docker compose down
check_command "Docker зупинено"

cd basic-coin-prediction-node || exit
check_command "Перехід до директорії basic-coin-prediction-node"

cat <<EOF > script.py
import json
import os
import subprocess

def update_config_json(new_node_rpc_url):
    config_file_path = 'config.json'
    
    if not os.path.exists(config_file_path):
        print(f'Error: Файл {config_file_path} не знайдено!')
        return

    try:
        with open(config_file_path, 'r') as file:
            config = json.load(file)

        if 'wallet' in config and 'nodeRpc' in config['wallet']:
            config['wallet']['nodeRpc'] = new_node_rpc_url
            print(f'Оновлено "nodeRpc" всередині "wallet" на {new_node_rpc_url}')

        with open(config_file_path, 'w') as file:
            json.dump(config, file, indent=4)

        print('Зміни успішно збережені в config.json.')

    except json.JSONDecodeError as e:
        print(f'Помилка читання JSON: {e}')
    except Exception as e:
        print(f'Відбулася помилка: {e}')

def run_shell_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
        print(f'Виконана команда: {command}')
    except subprocess.CalledProcessError as e:
        print(f'Помилка виконання команди {command}: {e}')

if __name__ == '__main__':
    new_node_rpc_url = input('Введіть нове посилання на RPC: ').strip()

    run_shell_command('docker compose down -v')
    update_config_json(new_node_rpc_url)
    run_shell_command('chmod +x init.config')
    run_shell_command('./init.config')
    run_shell_command('docker compose up -d')
    run_shell_command('docker logs -f worker')
EOF

check_command "script.py створено"

echo -e "${green}Запускаємо script.py...${nc}"
python3 script.py
check_command "script.py виконано"

echo -e "${green}Ініціалізуємо воркера...${nc}"
chmod +x init.config
./init.config
check_command "Ініціалізація воркера"

echo -e "${green}Запускаємо worker...${nc}"
docker compose pull
docker compose up --build -d
check_command "Worker запущено"

echo -e "${green}Перевірка логів worker...${nc}"
docker logs -f worker
