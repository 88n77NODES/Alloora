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
