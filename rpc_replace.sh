#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

echo -e "${green}### Автоматичний скрипт для швидкої зміни RPC ###${nc}"

echo -e "${green}Переходимо до директорії allora...${nc}"
cd basic-coin-prediction-node

echo -e "${green}Відкриття script.py для редагування...${nc}"
cat <<EOL > script.py
import json
import os
import subprocess

def update_config_json(new_node_rpc_url):
    config_file_path = 'config.json'
    
    # Перевірка, чи є файл config.json
    if not os.path.exists(config_file_path):
        print(f'Error: Файл {config_file_path} не знайдений!')
        return

    try:
        # Читаємо config.json
        with open(config_file_path, 'r') as file:
            config = json.load(file)

        # Оновлення "nodeRpc" всередині "wallet"
        if 'wallet' in config and 'nodeRpc' in config['wallet']:
            config['wallet']['nodeRpc'] = new_node_rpc_url
            print(f'Оновлення "nodeRpc" всередині "wallet" на {new_node_rpc_url}')

        # Запис JSON назад у файл
        with open(config_file_path, 'w') as file:
            json.dump(config, file, indent=4)

        print('Успішно змінено config.json.')

    except json.JSONDecodeError as e:
        print(f'Помилка читання JSON: {e}')
    except Exception as e:
        print(f'Виникла помилка: {e}')

def run_shell_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
        print(f'Виконана команда: {command}')
    except subprocess.CalledProcessError as e:
        print(f'Помилка команди {command}: {e}')

if __name__ == '__main__':
    new_node_rpc_url = input('Вкажіть посилання на RPC: ').strip()

    # Команди для виконання
    run_shell_command('docker compose down -v')
    update_config_json(new_node_rpc_url)
    run_shell_command('chmod +x init.config')
    run_shell_command('./init.config')
    run_shell_command('docker compose up -d')
    run_shell_command('docker compose logs -f')
EOL

# Перевіряємо, чи файл успішно створено
if [ -f "script.py" ]; then
    echo -e "${green}script.py створений успішно!${nc}"
else
    echo -e "${red}Помилка при створенні script.py!${nc}"
    exit 1
fi

# Запуск Python-скрипта
echo -e "${green}Запуск script.py...${nc}"
python3 script.py || { echo -e "${red}Помилка при виконанні script.py!${nc}"; exit 1; }

echo -e "${green}### Скрипт завершено! ###${nc}"
