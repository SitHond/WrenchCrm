#!/usr/bin/env sh
# WrenchCRM installer for Linux and macOS. Needs Docker or Podman with compose.
set -eu
cd "$(dirname "$0")"

if docker compose version >/dev/null 2>&1; then COMPOSE="docker compose"
elif podman compose version >/dev/null 2>&1; then COMPOSE="podman compose"
elif command -v podman-compose >/dev/null 2>&1; then COMPOSE="podman-compose"
elif command -v docker-compose >/dev/null 2>&1; then COMPOSE="docker-compose"
else
  echo "Docker или Podman с compose не найден. Установите Docker (https://docs.docker.com/engine/install/) или Podman + podman-compose." >&2
  exit 1
fi

random_hex() {
  if command -v openssl >/dev/null 2>&1; then openssl rand -hex "$1"
  else head -c "$1" /dev/urandom | od -An -tx1 | tr -d ' \n'; fi
}

# Escape a value for the sed replacement below.
sed_value() { printf '%s' "$1" | sed 's/[\\|&]/\\&/g'; }

if [ ! -f .env ]; then
  printf "Email администратора [admin@example.com]: "
  read -r admin_email || true
  admin_email=${admin_email:-admin@example.com}
  printf "Пароль администратора (пусто — сгенерировать): "
  stty -echo 2>/dev/null || true
  read -r admin_password || true
  stty echo 2>/dev/null || true
  echo
  generated=""
  if [ -z "${admin_password:-}" ]; then admin_password=$(random_hex 6); generated=1; fi
  printf "Название сервиса для печатных форм [Автосервис]: "
  read -r shop_name || true
  shop_name=${shop_name:-Автосервис}

  sed -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(random_hex 24)|" \
      -e "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$(random_hex 64)|" \
      -e "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=$(sed_value "$admin_email")|" \
      -e "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=$(sed_value "$admin_password")|" \
      -e "s|^SHOP_NAME=.*|SHOP_NAME=$(sed_value "$shop_name")|" \
      env.example > .env
  chmod 600 .env
  echo "Создан файл .env"
  [ -n "$generated" ] && echo "Пароль администратора: $admin_password"
else
  echo "Файл .env уже есть, использую его."
fi

$COMPOSE pull
$COMPOSE up -d

port=$(sed -n 's/^APP_PORT=//p' .env)
echo
echo "Готово. Откройте http://localhost:${port:-3000}"
echo "Первый запуск занимает до минуты, пока создаётся база."
