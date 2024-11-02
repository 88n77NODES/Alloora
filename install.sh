#!/bin/bash

green='\033[0;32m'
nc='\033[0m'

wget https://raw.githubusercontent.com/88n77/Logo-88n77/main/logo.sh
chmod +x logo.sh
./logo.sh

setup_url="https://raw.githubusercontent.com/88n77NODES/Allora/main/setup.sh"    
rpc_replace_url="https://raw.githubusercontent.com/88n77NODES/Allora/main/rpc_replace.sh"  
custom_model_url="https://raw.githubusercontent.com/88n77NODES/Allora/main/custom.sh" 
basic_model_url="https://raw.githubusercontent.com/88n77NODES/Allora/main/baswip.sh"  #baswip
delete_url="https://raw.githubusercontent.com/88n77NODES/Allora/main/delete.sh"  

menu_options=("Встановити" "Скрипт для заміни RPC" "Встановити базову модель" "Створити кастомну модель" "Видалити" "Вийти")
PS3='Оберіть дію: '

select choice in "${menu_options[@]}"
do
    case $choice in
        "Встановити")
            echo -e "${green}Встановлення...${nc}"
            bash <(curl -s $setup_url)
            ;;
        "Скрипт для заміни RPC")
            echo -e "${green}Встановлення...${nc}"
            bash <(curl -s $rpc_replace_url)
            ;;
        "Встановити базову модель")
            echo -e "${green}Встановлення базової моделі...${nc}"
            bash <(curl -s $basic_model_url)
            ;;
        "Створити кастомну модель")
            echo -e "${green}Створення кастомної моделі...${nc}"
            bash <(curl -s $custom_model_url)
            ;;
        "Видалити")
            echo -e "${green}Видалення...${nc}"
            bash <(curl -s $delete_url)
            ;;
        "Вийти")
            echo -e "${green}Вихід...${nc}"
            break
            ;;
        *)
            echo "Невірний вибір!"
            ;;
    esac
done
