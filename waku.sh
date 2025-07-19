#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Directory for user config and keystore
CONFIG_DIR="$HOME/.waku"
ENV_FILE="$CONFIG_DIR/.env"

# Compose project directories
COMPOSE_DIR="$HOME/nwaku-compose"
KEYSTORE_DIR="$COMPOSE_DIR/keystore"
EXAMPLE_ENV="$COMPOSE_DIR/.env.example"
TARGET_ENV="$COMPOSE_DIR/.env"

# Default keystore.json path inside CONFIG_DIR
DEFAULT_KEYSTORE_FILE="$CONFIG_DIR/keystore.json"

# Ensure user config directory exists
mkdir -p "$CONFIG_DIR"

config() {
  # Проверка наличия ENV_FILE
  if [[ ! -f "$ENV_FILE" ]]; then
    echo "Файл $ENV_FILE не знайдено. Створіть конфігурацію через 'Create the configuration'."
    return 1
  fi
  source "$ENV_FILE"

  # Проверка необходимых переменных
  for var in private_key public_key LineaS_RPC PASS KEYSTORE_FILE; do
    if [[ -z "${!var:-}" ]]; then
      echo "Змінна $var не встановлена в $ENV_FILE."
      return 1
    fi
  done

  # Копируем пример .env и обновляем значения
  cp "$EXAMPLE_ENV" "$TARGET_ENV"

  # Создаем keystore-директорию
  mkdir -p "$KEYSTORE_DIR"

  # Копируем keystore.json из CONFIG_DIR
  if [[ ! -f "$KEYSTORE_FILE" ]]; then
    echo "Файл keystore не знайдено за шляхом $KEYSTORE_FILE"
    return 1
  fi
  cp "$KEYSTORE_FILE" "$KEYSTORE_DIR/keystore.json"
  chmod 600 "$KEYSTORE_DIR/keystore.json"

  # Подстановка значений в .env
  sed -i -e "s%RLN_RELAY_ETH_CLIENT_ADDRESS=.*%RLN_RELAY_ETH_CLIENT_ADDRESS=${LineaS_RPC}%g" "$TARGET_ENV"
  sed -i -e "s%ETH_TESTNET_ACCOUNT=.*%ETH_TESTNET_ACCOUNT=${public_key}%g"             "$TARGET_ENV"
  sed -i -e "s%ETH_TESTNET_KEY=.*%ETH_TESTNET_KEY=${private_key}%g"                   "$TARGET_ENV"
  sed -i -e "s%RLN_RELAY_CRED_PASSWORD=.*%RLN_RELAY_CRED_PASSWORD=${PASS}%g"         "$TARGET_ENV"
  sed -i -e "s%STORAGE_SIZE=.*%STORAGE_SIZE=30720MB%g"                               "$TARGET_ENV"
  grep -q '^POSTGRES_SHM=' "$TARGET_ENV" || echo 'POSTGRES_SHM=2g' >> "$TARGET_ENV"

  # Обновление портов в docker-compose.yml
  sed -i 's/0\.0\.0\.0:3000:3000/0.0.0.0:3003:3000/' "$COMPOSE_DIR/docker-compose.yml"
  sed -i 's/80:80/82:80/'                               "$COMPOSE_DIR/docker-compose.yml"
}

while true; do
  PS3='Select an action: '
  options=(
    "Docker"
    "Download the components"
    "Create the configuration"
    "Run Node"
    "Update Node"
    "Check health"
    "Logs"
    "Uninstall"
    "Exit"
  )
  select opt in "${options[@]}"; do
    case $opt in

      "Docker")
        if ! . <(wget -qO- https://raw.githubusercontent.com/mgpwnz/VS/main/docker.sh); then
          echo "❌ Не вдалося завантажити docker.sh"
        fi
        break
        ;;

      "Download the components")
        if [[ ! -d "$COMPOSE_DIR" ]]; then
          git clone https://github.com/waku-org/nwaku-compose "$COMPOSE_DIR"
        else
          echo "Репозиторій уже існує — оновлюю..."
          git -C "$COMPOSE_DIR" pull
        fi
        break
        ;;

      "Create the configuration")
        mkdir -p "$CONFIG_DIR"
        touch "$ENV_FILE"
        source "$ENV_FILE" 2>/dev/null || true

        # Сбор обязательных переменных
        if [[ -z "${private_key:-}" ]]; then
          read -rp "Enter your private key: " private_key
          echo "private_key=\"$private_key\"" >> "$ENV_FILE"
        fi
        if [[ -z "${public_key:-}" ]]; then
          read -rp "Enter your public key: " public_key
          echo "public_key=\"$public_key\"" >> "$ENV_FILE"
        fi
        if [[ -z "${LineaS_RPC:-}" ]]; then
          read -rp "🌐 Linea Sepolia RPC URL: " LineaS_RPC
          echo "LineaS_RPC=\"$LineaS_RPC\"" >> "$ENV_FILE"
        fi
        if [[ -z "${PASS:-}" ]]; then
          read -rp "Enter password 🔑: " PASS
          echo "PASS=\"$PASS\"" >> "$ENV_FILE"
        fi

        # Установка KEYSTORE_FILE
        if [[ -z "${KEYSTORE_FILE:-}" ]]; then
          if [[ -f "$DEFAULT_KEYSTORE_FILE" ]]; then
            KEYSTORE_FILE="$DEFAULT_KEYSTORE_FILE"
            echo "KEYSTORE_FILE=\"$KEYSTORE_FILE\"" >> "$ENV_FILE"
          else
            read -rp "Enter path to keystore.json (можно загрузить по SFTP в $CONFIG_DIR): " KEYSTORE_FILE
            echo "KEYSTORE_FILE=\"$KEYSTORE_FILE\"" >> "$ENV_FILE"
          fi
        fi

        break
        ;;

      "Run Node")
        if ! config; then
          echo "❌ Помилка конфігурації — повертаюся в меню."
          continue
        fi
        cd "$COMPOSE_DIR"
        docker compose up -d
        docker compose logs -f
        break
        ;;

      "Update Node")
        cd "$COMPOSE_DIR"
        docker compose down
        git fetch && git stash && git merge origin/master && git stash pop
        rm -f .env
        if ! config; then
          echo "❌ Помилка конфігурації після оновлення."
          continue
        fi
        docker compose up -d
        break
        ;;

      "Check health")
        bash "$COMPOSE_DIR/chkhealth.sh"
        break
        ;;

      "Logs")
        docker compose -f "$COMPOSE_DIR/docker-compose.yml" logs -f --tail 1000
        break
        ;;

      "Uninstall")
        if [[ -d "$COMPOSE_DIR" ]]; then
          read -rp "Wipe all DATA? [y/N] " response
          if [[ "$response" =~ ^[Yy] ]]; then
            cd "$COMPOSE_DIR" && docker compose down -v
            rm -rf "$COMPOSE_DIR"
          else
            echo "Canceled"
          fi
        fi
        break
        ;;

      "Exit")
        exit 0
        ;;

      *) echo "invalid option $REPLY";;
    esac
  done
done
