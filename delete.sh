#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

stop_and_remove() {
    container_name=$1
    echo -e "${green}Зупиняємо та видаляємо контейнер ${container_name}...${nc}"
    if [ "$(docker ps -q -f name=${container_name})" ]; then
        docker stop ${container_name}
        docker rm ${container_name}
        echo -e "${green}Контейнер ${container_name} успішно видалено.${nc}"
    else
        echo -e "${red}Контейнер ${container_name} не знайдено!${nc}"
    fi
}

remove_image() {
    image_name=$1
    echo -e "${green}Видаляємо образ ${image_name}...${nc}"
    if [ "$(docker images -q ${image_name})" ]; then
        docker rmi ${image_name}
        echo -e "${green}Образ ${image_name} успішно видалено.${nc}"
    else
        echo -e "${red}Образ ${image_name} не знайдено!${nc}"
    fi
}

echo -e "${green}Видаляємо...${nc}"

containers=("worker-basic-eth-pred" "updater-basic-eth-pred" "head-basic-eth-pred" "inference-basic-eth-pred")
images=("basic-coin-prediction-node-inference" "basic-coin-prediction-node-updater" "basic-coin-prediction-node-worker")

for container in "${containers[@]}"; do
    stop_and_remove ${container}
done

for image in "${images[@]}"; do
    remove_image ${image}
done

rm -rf basic-coin-prediction-node
rm -rf allora-offchain-node
rm -rf allora-chain

docker container prune -f
docker image prune -a -f

echo -e "${green}Видалення завершено!${nc}"
