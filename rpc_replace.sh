echo -e "${green}Встановлюємо скрипт на швидку заміну RPC...${nc}"

docker compose down

cd $HOME/basic-coin-prediction-node 

cat << 'EOF' > script.py
import json
import os
import subprocess

def update_config_json(new_node_rpc_url):
    config_file_path = 'config.json'
    
    if not os.path.isfile(config_file_path):
        raise FileNotFoundError(f'Error: Файл {config_file_path} не знайдено!')

    with open(config_file_path, 'r') as file:
        config = json.load(file)

    if 'wallet' in config and 'nodeRpc' in config['wallet']:
        config['wallet']['nodeRpc'] = new_node_rpc_url
        print(f'Оновлено "nodeRpc" на {new_node_rpc_url}')

    with open(config_file_path, 'w') as file:
        json.dump(config, file, indent=4)
        print('Зміни успішно збережені в config.json.')

def run_shell_command(command):
    subprocess.run(command, shell=True, check=True)
    print(f'Виконана команда: {command}')

if __name__ == '__main__':
    new_node_rpc_url = input('Введіть нове посилання на RPC: ').strip()
    
    run_shell_command('docker compose down -v')
    try:
        update_config_json(new_node_rpc_url)
        run_shell_command('chmod +x init.config')
        run_shell_command('./init.config')
        run_shell_command('docker compose up -d')
        run_shell_command('docker logs -f worker')
    except Exception as e:
        print(f'Відбулася помилка: {e}')
EOF

echo -e "${green}Скрипт script.py успішно створено.${nc}"
