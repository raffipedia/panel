#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'
BOLD='\033[1m'

install_dependencies() {
  apt update
  apt install -y unzip wget curl
}

restart_services() {
  chown -R www-data:www-data /var/www/pterodactyl/*
}

check_node_version() {
  NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
  if [ "$NODE_VERSION" -lt 22 ]; then
      npm install -g n
      n 22
      hash -r
  fi
}

pterodactyl_custom() {
  read -p "Install Pterodactyl Custom? (y/n): " yn
  [[ $yn != [Yy]* ]] && return

  cd /var/www/pterodactyl || exit 1

  check_node_version

  php artisan down

  rm -rf resources
  curl -L https://github.com/raffipedia/panel/releases/latest/download/panel.tar.gz | tar -xzv

  chmod -R 755 storage/* bootstrap/cache

  composer install --no-dev --optimize-autoloader
  php artisan migrate --seed --force

  rm -f package-lock.json
  npm install --legacy-peer-deps
  
  NODE_OPTIONS="--max-old-space-size=2048" npm run build:production

  php artisan view:clear
  php artisan config:clear
  
  php artisan up
  restart_services
  
  echo -e "${GREEN}Instalasi dan Build selesai! Tampilan harusnya sudah berubah.${RESET}"
}

reset_pterodactyl() {
  read -p "Uninstall Theme? (y/n): " yn
  [[ $yn != [Yy]* ]] && return

  cd /var/www/pterodactyl || exit 1

  check_node_version

  php artisan down

  rm -rf resources
  curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv

  chmod -R 755 storage/* bootstrap/cache

  composer install --no-dev --optimize-autoloader
  php artisan migrate --seed --force

  rm -f package-lock.json
  npm install --legacy-peer-deps
  
  NODE_OPTIONS="--max-old-space-size=2048" npm run build:production

  php artisan view:clear
  php artisan config:clear
  
  php artisan up
  restart_services
  
  echo -e "${GREEN}Pterodactyl Telah Di Reset ke versi Ori dan di Rebuild.${RESET}"
}

while true; do
  clear
  echo -e "${CYAN}=========================================${RESET}"
  echo -e "${BOLD}    PTERODACTYL CONFIGURATOR CUSTOM v3${RESET}"
  echo -e "${CYAN}=========================================${RESET}"
  echo "1. Install Pterodactyl Custom"
  echo "2. Uninstall Theme"
  echo "3. Keluar"
  echo -e "${CYAN}=========================================${RESET}"
  read -p "Pilih opsi: " choice
  case $choice in
    1) pterodactyl_custom ;;
    2) reset_pterodactyl ;;
    3) exit 0 ;;
    *) echo -e "${RED}Pilihan tidak valid${RESET}"; sleep 2 ;;
  esac
  read -p "Tekan Enter untuk kembali..."
done
