# Taskmanager

Небольшой task manager на Vue 3 + FastAPI + PostgreSQL. Задачи можно создавать, удалять и отмечать выполненными. Данные сохраняются в PostgreSQL.

## Запуск без Docker

Это основной способ запуска проекта. Нужны Python 3.11+, Node.js 18+ и PostgreSQL 17+.

### 1. Подготовить PostgreSQL

Создайте роль и базу от имени администратора PostgreSQL. Пример для PowerShell, если пароль администратора `postgres`:

```powershell
$env:PGPASSWORD = "postgres"
$psql = "C:\Program Files\PostgreSQL\17\bin\psql.exe"
& $psql -U postgres -d postgres -c "CREATE USER taskmanager WITH PASSWORD 'taskmanager';"
& $psql -U postgres -d postgres -c "CREATE DATABASE taskmanager OWNER taskmanager;"
```

Если роль или база уже существуют, эти команды можно пропустить. Служба PostgreSQL должна быть запущена.

### 2. Запустить API

```powershell
cd backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$env:DATABASE_URL = "postgresql+psycopg://taskmanager:taskmanager@localhost:5432/taskmanager"
uvicorn app.main:app --reload --port 8000
```

API доступно на `http://localhost:8000`, документация: `http://localhost:8000/docs`.

### 3. Запустить Vue в другом терминале

```powershell
cd frontend
npm install
npm run dev
```

Откройте `http://localhost:5173`.

Для production-сборки Vue:

```powershell
cd frontend
npm run build
npm run preview
```

## Docker (необязательно)

В проекте также есть `docker-compose.yml`. Одного Docker CLI недостаточно: для `docker compose up` нужен запущенный Docker Engine, обычно он устанавливается вместе с Docker Desktop или Docker Engine на Linux.

```powershell
docker compose up --build
```

## Запуск API как сервиса

### Linux / systemd

Файл `taskmanager-api.service` уже подготовлен:

```bash
sudo cp taskmanager-api.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now taskmanager-api
sudo systemctl status taskmanager-api
```

Перед этим создайте окружение в `/opt/taskmanager/.venv` и установите зависимости backend.

### Windows / NSSM

1. Установите NSSM и выполните `nssm install taskmanager-api`.
2. В поле **Application** укажите путь к `backend\\.venv\\Scripts\\python.exe`.
3. В поле **Arguments** укажите `-m uvicorn app.main:app --host 0.0.0.0 --port 8000`.
4. В поле **Startup directory** укажите папку `backend`.
5. Добавьте переменную окружения `DATABASE_URL=postgresql+psycopg://taskmanager:taskmanager@localhost:5432/taskmanager` и запустите `nssm start taskmanager-api`.

## API

- `GET /api/tasks` — список задач
- `POST /api/tasks` — создать задачу (`title`, `description`)
- `PATCH /api/tasks/{id}` — обновить название, описание или `completed`
- `DELETE /api/tasks/{id}` — удалить задачу
