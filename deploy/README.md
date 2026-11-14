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
