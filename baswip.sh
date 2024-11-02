#!/bin/bash

green='\033[0;32m'
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

echo -e "${green}Встановлення базової моделі...${nc}"

echo -e "${green}Встановлюємо редактор nano...${nc}"
sudo apt install nano
check_command "Nano встановлено"

echo -e "${green}Налаштовуємо .env файл...${nc}"
cp .env.example .env
check_command ".env файл створено"

read -p "Введіть значення для API_KEY: " api_key
read -p "Введіть значення для DB_HOST: " db_host
read -p "Введіть значення для DB_USER: " db_user
read -p "Введіть значення для DB_PASSWORD: " db_password

echo "API_KEY=$api_key" >> .env
echo "DB_HOST=$db_host" >> .env
echo "DB_USER=$db_user" >> .env
echo "DB_PASSWORD=$db_password" >> .env

echo -e "${green}Ваш файл .env:${nc}"
cat .env

confirm_action "Чи правильно вказані дані у файлі .env?"

echo -e "${green}Копіюємо config.json файл...${nc}"
cp config.example.json config.json
check_command "config.json файл створено"

echo -e "${green}Будь ласка, відредагуйте config.json файл.${nc}"
nano config.json

confirm_action "Чи ви зберегли файл config.json і чи все вірно?"

echo -e "${green}Налаштовуємо скрипт для заміни RPC...${nc}"
docker compose down
check_command "Docker зупинено"

cd basic-coin-prediction-node
check_command "Перехід до директорії basic-coin-prediction-node"

cat <<EOF > script.py
import json
import os
import subprocess

def update_config_json(new_node_rpc_url):
    config_file_path = 'config.json'
    
    # Перевіряємо, чи існує файл config.json
    if not os.path.exists(config_file_path):
        print(f'Error: Файл {config_file_path} не знайдено!')
        return

    try:
        # Читаємо вміст config.json
        with open(config_file_path, 'r') as file:
            config = json.load(file)

        # Оновлюємо поле "nodeRpc" усередині "wallet", якщо воно існує
        if 'wallet' in config and 'nodeRpc' in config['wallet']:
            config['wallet']['nodeRpc'] = new_node_rpc_url
            print(f'Оновлено "nodeRpc" всередині "wallet" на {new_node_rpc_url}')

        # Записуємо оновлений JSON назад у файл
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

    # Виконуємо команди
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
