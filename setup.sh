green='\033[0;32m'
nc='\033[0m'

check_command() {
    if [ $? -ne 0 ]; then
        echo -e "${red}Помилка: ${1} не встановлено!${nc}"
        exit 1
    else
        echo -e "${green}${1} успішно встановлено.${nc}"
    fi
}

echo -e "${green}Оновлюємо та встановлюємо залежності...${nc}"

sudo apt update && sudo apt upgrade -y
check_command "Оновлення системи"

sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev
check_command "Базові залежності"

echo -e "${green}Встановлюємо Python3...${nc}"

sudo apt install -y python3
check_command "Python3"

python3 --version
sudo apt install -y python3-pip
check_command "pip3"

pip3 --version

echo -e "${green}Встановлюємо Docker...${nc}"

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
check_command "Docker GPG key"

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_command "Docker repo"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
check_command "Docker"

docker version
check_command "Docker version"

echo -e "${green}Встановлюємо Docker-Compose...${nc}"

VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/"$VER"/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
check_command "Docker-Compose"

docker-compose --version

sudo groupadd docker
sudo usermod -aG docker $USER
check_command "Група Docker"

echo -e "${green}Встановлюємо Go...${nc}"

sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
check_command "Go"

echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source $HOME/.bash_profile
go version
check_command "Go version"

echo -e "${green}Перевірка встановлення завершена. Продовжуємо...${nc}"
sleep 2

echo -e "${green}Клонуємо репозиторій Allora: Wallet...${nc}"

git clone https://github.com/allora-network/allora-chain.git
check_command "Allora-chain репозиторій"

echo -e "${green}Клонуємо базовий репозиторій для node...${nc}"

git clone https://github.com/allora-network/basic-coin-prediction-node
check_command "Basic Coin Prediction Node репозиторій"

cd basic-coin-prediction-node
check_command "Перехід в директорію basic-coin-prediction-node"

echo -e "${green}Встановлення успішне!${nc}"

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

python3 script.py
