#!/bin/bash

green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

echo -e "${green}Starting backup...${nc}"

# Backup files
cp adapter/api/source/Dockerfile adapter/api/source/Dockerfile.bak
cp adapter/api/source/requirements.txt adapter/api/source/requirements.txt.bak
cp adapter/api/source/main.py adapter/api/source/main.py.bak
cp config.json config.json.bak

echo -e "${green}Backup completed.${nc}"

cd $HOME/basic-coin-prediction-node

# Stop the node
echo -e "${green}Stopping the node...${nc}"
docker compose down

echo -e "${green}Enter the following details:${nc}"
read -p "Token: " TOKEN
read -p "TRAINING_DAYS: " TRAINING_DAYS
read -p "TIMEFRAME: " TIMEFRAME
read -p "Coingecko: " COINGECKO
read -p "MODEL: " MODEL
read -p "REGION: " REGION
read -p "DATA_PROVIDER: " DATA_PROVIDER
read -p "CG_API_KEY: " CG_API_KEY

# Save to .env file
{
  echo "TOKEN=${TOKEN}"
  echo "TRAINING_DAYS=${TRAINING_DAYS}"
  echo "TIMEFRAME=${TIMEFRAME}"
  echo "COINGECKO=${COINGECKO}"
  echo "MODEL=${MODEL}"
  echo "REGION=${REGION}"
  echo "DATA_PROVIDER=${DATA_PROVIDER}"
  echo "CG_API_KEY=${CG_API_KEY}"
} >> .env

# Make the init.config executable and run it
chmod +x init.config
./init.config

# Start the node
echo -e "${green}Starting the node...${nc}"
docker compose up -d

echo -e "${green}Перевірка логів worker...${nc}"
docker logs -f worker