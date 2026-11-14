# CRM для автосервиса

CRM для автомастерской на **Ruby on Rails 8.1** и **PostgreSQL 17**, запускается в контейнерах (Docker или Podman).

Проект вырос из переноса [ChurchCRM](https://github.com/ChurchCRM/CRM) на Rails. Сейчас каркас переделывается под автосервис: базовые части (вход, пользователи и права, клиенты, заметки, ru/en, контейнеры) остаются, церковные модули заменяются на модули автосервиса.

## План

- [x] Вход, пользователи и права доступа
- [x] Интерфейс на русском и английском
- [x] Запуск через `docker compose` / `podman compose`
- [ ] Клиенты: частные лица и компании
- [ ] Автомобили: марка, модель, год, VIN, госномер, пробег, история обслуживания
- [ ] Заказ-наряды: приём, статусы, мастер, работы и запчасти
- [ ] Справочник работ с нормо-часами и ценами
- [ ] Склад запчастей
- [ ] Оплаты, печать заказ-наряда и акта
- [ ] Запись на приём по постам и мастерам

## Быстрый старт

```bash
cp .env.example .env          # задайте пароли и SECRET_KEY_BASE (openssl rand -hex 64)
docker compose up -d --build  # или: podman compose up -d --build
```

Приложение откроется на http://localhost:3000. Вход — `ADMIN_EMAIL` и `ADMIN_PASSWORD` из `.env`.
При каждом старте контейнер применяет миграции и создаёт администратора, если его ещё нет.

Если перед приложением стоит прокси с HTTPS, добавьте `RAILS_ASSUME_SSL=true` и `RAILS_FORCE_SSL=true`.

## Разработка

```bash
docker compose -f compose.dev.yaml up --build
```

Код монтируется в контейнер, изменения подхватываются без пересборки. Загружаются демо-данные, вход `admin@example.com` / `changeme123`.

```bash
docker compose -f compose.dev.yaml exec web bin/rails test
docker compose -f compose.dev.yaml exec web bin/rails console
```

Без контейнера понадобятся Ruby 3.4 и PostgreSQL. Подключение задаётся переменными `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD` (по умолчанию `localhost:5432`, `church_crm`/`church_crm`).

## Лицензия

MIT. Часть кода основана на идеях [ChurchCRM](https://github.com/ChurchCRM/CRM) (MIT).
