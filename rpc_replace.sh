echo -e "${green}Встановлюємо скрипт на швидку заміну RPC...${nc}"

docker compose down

cd basic-coin-prediction-node

cat << 'EOF' > script.py
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

echo -e "${green}Скрипт script.py успішно створено.${nc}"
