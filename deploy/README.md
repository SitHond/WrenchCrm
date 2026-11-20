# WrenchCRM: установка

CRM для автосервиса. Работает в контейнерах: приложение и база PostgreSQL запускаются одной командой.

## Что нужно

- **Linux**: Docker Engine с плагином compose или Podman с podman-compose
- **Windows и macOS**: [Docker Desktop](https://www.docker.com/products/docker-desktop/) или [Podman Desktop](https://podman-desktop.io/)
- 2 ГБ оперативной памяти и 2 ГБ места на диске

## Установка

Распакуйте архив в папку, где будет жить программа, например `C:\WrenchCRM` или `/opt/wrenchcrm`.

**Linux / macOS**

```bash
./install.sh
```

**Windows** (PowerShell в папке с программой)

```powershell
powershell -ExecutionPolicy Bypass -File install.ps1
```

Скрипт спросит email и пароль администратора и название сервиса, сгенерирует пароль базы и секретный ключ в файле `.env`, скачает образ и запустит программу. Откройте http://localhost:3000.

Чтобы посмотреть программу на примерах, перед первым запуском впишите в `.env` строку `SEED_DEMO=1`.

## Домен: CRM и сайт сервиса

Если при установке указать домен (например `gayka.ru`), CRM будет на `crm.gayka.ru`, а сайт сервиса — на `gayka.ru` и `www.gayka.ru`.

1. У регистратора домена добавьте A-записи `@`, `www` и `crm` на внешний IP сервера. Установщик проверит их и подскажет, чего не хватает.
2. **Встроенный Caddy** (вариант 1): программа сама занимает порты 80 и 443 и получает сертификаты Let's Encrypt. Порты 80 и 443 должны быть открыты и проброшены на сервер.
3. **Свой прокси** (вариант 2, например Nginx Proxy Manager): программа слушает `APP_PORT`, а в прокси нужно создать два хоста с HTTPS — `crm.домен` и `домен, www.домен` — оба на `http://IP-сервера:APP_PORT`.

Добавить домен позже: впишите в `.env` `CRM_HOST`, `SITE_HOST`, `RAILS_ASSUME_SSL=true`, `RAILS_FORCE_SSL=true`, для Caddy ещё `COMPOSE_PROFILES=domain` и `APP_BIND=127.0.0.1`, затем `docker compose up -d`.

Без домена сайт можно посмотреть по адресу `http://localhost:3000/site`. Содержимое сайта настраивается в CRM: раздел «Сайт».

## Повседневные команды

Выполняются в папке с программой. Вместо `docker compose` можно `podman compose`.

| Действие | Команда |
|----------|---------|
| Остановить | `docker compose down` |
| Запустить | `docker compose up -d` |
| Логи | `docker compose logs -f web` |
| Состояние | `docker compose ps` |

После перезагрузки компьютера программа запускается сама, если запущен Docker.

## Обновление

1. Сделайте резервную копию (ниже).
2. Впишите новую версию в `.env`, например `WRENCH_VERSION=1.1.0`. Номера версий — на странице релизов.
3. Выполните:

```bash
docker compose pull
docker compose up -d
```

Миграции базы применяются автоматически при запуске.

## Резервная копия

### Автоматически, с шифрованием

`backup.sh` делает зашифрованную копию базы (AES-256) в папку `backups` и удаляет копии старше `BACKUP_KEEP_DAYS` дней (по умолчанию 14). Добавьте в `.env` длинную случайную фразу и сохраните её отдельно — без неё копию не расшифровать:

```bash
echo "BACKUP_PASSPHRASE=$(openssl rand -base64 32)" >> .env
./backup.sh
```

Ежедневный запуск в 03:30 (Linux, от root):

```bash
echo "30 3 * * * root cd $(pwd) && ./backup.sh >> backups/backup.log 2>&1" > /etc/cron.d/wrenchcrm-backup
```

Восстановить из зашифрованной копии (текущие данные будут заменены):

```bash
docker compose stop web
openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -pass env:BACKUP_PASSPHRASE -in backups/wrenchcrm-2026-01-31-0330.dump.enc |
  docker compose exec -T db pg_restore -U wrench_crm -d wrench_crm_production --clean --if-exists
docker compose start web
```

Перед командой выполните `export BACKUP_PASSPHRASE=...` с фразой из `.env`. Храните копии ещё и на другом носителе или сервере в РФ (требование локализации персональных данных).

### Вручную

Создать:

```bash
docker compose exec -T db pg_dump -U wrench_crm -Fc wrench_crm_production > wrenchcrm-$(date +%F).dump
```

В PowerShell:

```powershell
docker compose exec -T db pg_dump -U wrench_crm -Fc wrench_crm_production -f /tmp/backup.dump
docker compose cp db:/tmp/backup.dump "wrenchcrm-$(Get-Date -Format yyyy-MM-dd).dump"
```

Восстановить (текущие данные будут заменены):

```bash
docker compose stop web
docker compose exec -T db pg_restore -U wrench_crm -d wrench_crm_production --clean --if-exists < wrenchcrm-2026-01-31.dump
docker compose start web
```

В PowerShell:

```powershell
docker compose stop web
docker compose cp wrenchcrm-2026-01-31.dump db:/tmp/restore.dump
docker compose exec -T db pg_restore -U wrench_crm -d wrench_crm_production --clean --if-exists /tmp/restore.dump
docker compose start web
```

Храните копии и файл `.env` вне этого компьютера. Без `.env` копию можно восстановить, но придётся задать новый `SECRET_KEY_BASE`, и всех пользователей разлогинит.

## Доступ из локальной сети и интернета

Другие компьютеры в сети открывают `http://<IP-адрес-компьютера>:3000`. Порт меняется переменной `APP_PORT`.

Для доступа из интернета поставьте перед программой обратный прокси с HTTPS (Caddy, nginx, Traefik) и включите в `.env`:

```
RAILS_ASSUME_SSL=true
RAILS_FORCE_SSL=true
```

Не открывайте порт 3000 в интернет напрямую: пароли будут передаваться без шифрования.
