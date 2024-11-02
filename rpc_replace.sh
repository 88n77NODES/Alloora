
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

echo -e "${green}Запускаємо скрипт на зміну RPC...${nc}"

sleep 2

if [ -d "basic-coin-prediction-node" ]; then
    cd basic-coin-prediction-node || { echo -e "${red}Не вдалося перейти до каталогу!${nc}"; exit 1; }

    echo -e "${green}Запускаємо script.py...${nc}"
    if python3 script.py; then
        echo -e "${green}Скрипт виконано успішно.${nc}"
    else
        echo -e "${red}Помилка при виконанні скрипта!${nc}"
        exit 1
    fi
else
    echo -e "${red}Каталог basic-coin-prediction-node не знайдено!${nc}"
    exit 1
fi

echo -e "${green}Перевіряємо логи...${nc}"
if docker logs -f worker; then
    echo -e "${green}Логи успішно відображаються.${nc}"
else
    echo -e "${red}Не вдалося отримати логи контейнера worker!${nc}"
    exit 1
fi
