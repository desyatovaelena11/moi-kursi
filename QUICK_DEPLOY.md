# ⚡ Быстрый деплой Moi-Kursi (GitHub Pages + VPS)

Пошаговая инструкция за 15 минут.

---

## 🎯 Что будет результат

```
Frontend: https://desyatovaelena11.github.io/moi-kursi/
Backend:  https://155.212.139.51.nip.io:8000/backend/api/v1/
```

---

## 📋 ШАГ 1: GitHub Pages (5 минут)

**Действия на GitHub (самостоятельно):**

1. Открой https://github.com/desyatovaelena11/moi-kursi
2. Нажми **Settings** (вверху справа)
3. В левом меню нажми **Pages**
4. В **Source** выбери:
   - Branch: `main`
   - Folder: `/ (root)`
5. Нажми **Save**
6. Подожди 1-2 минуты

**✅ Результат:** Frontend будет доступен по адресу:
```
https://desyatovaelena11.github.io/moi-kursi/
```

---

## 🖥️ ШАГ 2: VPS Backend (10 минут)

### 2.1 Подключись к VPS по SSH

**Открой терминал и выполни:**

```bash
ssh root@155.212.139.51
```

**Введи пароль:** `T4cHBb!6pfq7`

### 2.2 Создай директорию для проекта

```bash
mkdir -p /opt/moi-kursi
cd /opt/moi-kursi
```

### 2.3 Загрузи файлы (из локального компьютера)

**Открой ВТОРОЙ терминал и выполни:**

```bash
cd "d:\С раб.стола\Мои документы\Projects\Moi-kursi"

# Загрузи все файлы на VPS
scp -r backend root@155.212.139.51:/opt/moi-kursi/
scp .env root@155.212.139.51:/opt/moi-kursi/
scp docs/DATABASE.sql root@155.212.139.51:/opt/moi-kursi/
```

**Введи пароль** (если спросит): `T4cHBb!6pfq7`

### 2.4 Запусти скрипт установки на VPS

**Вернись в ПЕРВЫЙ терминал (SSH) и выполни:**

```bash
# Загрузи скрипт установки
scp scripts/setup_vps.sh root@155.212.139.51:/opt/moi-kursi/

# Выполни скрипт
bash /opt/moi-kursi/setup_vps.sh
```

**Скрипт автоматически:**
- ✓ Создаст базу данных
- ✓ Импортирует схему таблиц
- ✓ Настроит Nginx
- ✓ Проверит всё работает

---

## ✅ ПРОВЕРКА: Всё ли работает?

### 1️⃣ Проверь Backend API

Открой в браузере:
```
http://155.212.139.51.nip.io:8000/backend/api/v1/courses
```

**Должна вернуться JSON:**
```json
{"success": true, "data": []}
```

Если видишь это — backend работает! ✅

### 2️⃣ Проверь Frontend

Открой:
```
https://desyatovaelena11.github.io/moi-kursi/
```

**Должна загрузиться платформа с текстом:**
```
"Выбери курс слева"
```

Если видишь это — frontend работает! ✅

### 3️⃣ Проверь связь Frontend ↔️ Backend

Открой в браузере **F12** (DevTools):
1. Перейди на вкладку **Network**
2. Обнови страницу (Ctrl+R)
3. Ищи запросы к `155.212.139.51.nip.io`

Если видишь запросы и они возвращают **status 200** — связь работает! ✅

---

## 🎬 Дальнейшие действия

После успешного развёртывания:

### 1. Добавь первый курс через API

```bash
curl -X POST http://155.212.139.51.nip.io:8000/backend/api/v1/courses \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Мой первый курс",
    "description": "Описание курса"
  }'
```

Должна вернуться JSON с id созданного курса.

### 2. Загрузи видео на Mail.ru Cloud

```bash
# Скрипт для загрузки видео
python scripts/upload_videos.py --folder "d:/videos"
```

### 3. Добавь видео в курс через API

API документация: [docs/API.md](./docs/API.md)

---

## 🆘 Если что-то не работает

### ❌ Backend недоступен (ошибка подключения)

**На VPS проверь:**

```bash
# Проверь что Nginx работает
systemctl status nginx

# Перезапусти
systemctl restart nginx

# Смотри логи
tail -f /var/log/nginx/error.log
```

### ❌ Backend доступен, но 404 ошибка

**На VPS проверь что файлы на месте:**

```bash
ls -la /opt/moi-kursi/backend/api/
# Должны быть: index.php, courses.php, sections.php, lessons.php
```

### ❌ Frontend не загружается

**На GitHub проверь Pages:**
1. Открой Settings → Pages
2. Убедись что Source = `main` branch
3. Подожди 5 минут на распространение DNS

### ❌ CORS ошибки в браузере

**На VPS в backend/api/index.php добавь:**

```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
```

---

## 📚 Документация

- **GitHub Pages + VPS архитектура:** [DEPLOYMENT_GITHUB_VPS.md](./DEPLOYMENT_GITHUB_VPS.md)
- **VPS детальная инструкция:** [DEPLOY_TO_VPS.md](./DEPLOY_TO_VPS.md)
- **API документация:** [docs/API.md](./docs/API.md)
- **Структура БД:** [docs/DATABASE.sql](./docs/DATABASE.sql)

---

## ✨ Итого

| Компонент | Статус | URL |
|-----------|--------|-----|
| Frontend | GitHub Pages | https://desyatovaelena11.github.io/moi-kursi/ |
| Backend API | VPS | https://155.212.139.51.nip.io:8000/backend/api/v1/ |
| База данных | MySQL на VPS | moi_kursi_db |
| Видео | Mail.ru Cloud | (отдельно) |

---

**Всё готово! Начинай с Шага 1. Успехов! 🚀**
