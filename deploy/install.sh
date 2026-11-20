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

  printf "Домен сервиса, например gayka.ru (пусто — без домена, по адресу этого компьютера): "
  read -r domain || true
  domain=$(printf '%s' "${domain:-}" | tr 'A-Z' 'a-z' | sed 's#^https\{0,1\}://##; s#/.*$##; s#^www\.##')
  proxy_mode=""
  if [ -n "$domain" ]; then
    echo "CRM будет на crm.$domain, сайт — на $domain и www.$domain."
    echo "Как опубликовать?"
    echo "  1) Встроенный Caddy: займёт порты 80 и 443 и сам получит сертификаты (рекомендуется для отдельного сервера)"
    echo "  2) У меня уже есть прокси (Nginx Proxy Manager, nginx, Traefik) на портах 80/443"
    printf "Выберите 1 или 2 [1]: "
    read -r proxy_mode || true
    proxy_mode=${proxy_mode:-1}
  fi

  sed -e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(random_hex 24)|" \
      -e "s|^SECRET_KEY_BASE=.*|SECRET_KEY_BASE=$(random_hex 64)|" \
      -e "s|^BACKUP_PASSPHRASE=.*|BACKUP_PASSPHRASE=$(random_hex 32)|" \
      -e "s|^ADMIN_EMAIL=.*|ADMIN_EMAIL=$(sed_value "$admin_email")|" \
      -e "s|^ADMIN_PASSWORD=.*|ADMIN_PASSWORD=$(sed_value "$admin_password")|" \
      -e "s|^SHOP_NAME=.*|SHOP_NAME=$(sed_value "$shop_name")|" \
      -e "s|^CRM_HOST=.*|CRM_HOST=${domain:+crm.$domain}|" \
      -e "s|^SITE_HOST=.*|SITE_HOST=$domain|" \
      -e "s|^ACME_EMAIL=.*|ACME_EMAIL=$(sed_value "$admin_email")|" \
      env.example > .env
  if [ -n "$domain" ]; then
    {
      echo "RAILS_ASSUME_SSL=true"
      echo "RAILS_FORCE_SSL=true"
    } >> .env
    sed -i.bak -e '/^RAILS_ASSUME_SSL=false$/d' -e '/^RAILS_FORCE_SSL=false$/d' .env && rm -f .env.bak
    if [ "$proxy_mode" = "1" ]; then
      sed -i.bak -e "s|^COMPOSE_PROFILES=.*|COMPOSE_PROFILES=domain|" -e "s|^APP_BIND=.*|APP_BIND=127.0.0.1|" .env && rm -f .env.bak
    fi
  fi
  chmod 600 .env
  echo "Создан файл .env"
  [ -n "$generated" ] && echo "Пароль администратора: $admin_password"
else
  echo "Файл .env уже есть, использую его."
fi

crm_host=$(sed -n 's/^CRM_HOST=//p' .env)
site_host=$(sed -n 's/^SITE_HOST=//p' .env)
if [ -n "$site_host" ]; then
  echo
  echo "Проверка DNS:"
  public_ip=$(curl -fsS --max-time 5 https://ifconfig.me 2>/dev/null || true)
  for host in "$crm_host" "$site_host" "www.$site_host"; do
    resolved=$(getent hosts "$host" 2>/dev/null | awk '{print $1}' | head -1)
    if [ -z "$resolved" ]; then
      echo "  $host — НЕТ записи. Добавьте у регистратора A-запись ${host%%.$site_host} → ${public_ip:-IP этого сервера}"
    elif [ -n "$public_ip" ] && [ "$resolved" != "$public_ip" ]; then
      echo "  $host → $resolved (внешний IP сервера $public_ip — проверьте, что трафик доходит сюда)"
    else
      echo "  $host → $resolved"
    fi
  done
fi

$COMPOSE pull
$COMPOSE up -d

port=$(sed -n 's/^APP_PORT=//p' .env)
profiles=$(sed -n 's/^COMPOSE_PROFILES=//p' .env)
echo
if [ -n "$site_host" ] && [ "$profiles" = "domain" ]; then
  echo "Готово. CRM: https://$crm_host  Сайт: https://$site_host"
  echo "Сертификаты выпускаются автоматически, когда DNS-записи указывают на этот сервер."
elif [ -n "$site_host" ]; then
  echo "Готово. Программа слушает порт ${port:-3000}. Добавьте в свой прокси два хоста с HTTPS:"
  echo "  $crm_host                 → http://<IP этого сервера>:${port:-3000}"
  echo "  $site_host, www.$site_host → http://<IP этого сервера>:${port:-3000}"
  echo "Прокси должен передавать заголовки Host и X-Forwarded-Proto."
else
  echo "Готово. Откройте http://localhost:${port:-3000}"
fi
echo "Первый запуск занимает до минуты, пока создаётся база."
