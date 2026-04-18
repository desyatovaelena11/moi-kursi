# 🚀 Развёртывание Moi-Kursi: GitHub Pages + VPS

Полная инструкция по развёртыванию платформы с использованием GitHub Pages для frontend и VPS для backend.

---

## 📊 Архитектура

```
┌─────────────────────────────────────────────────────────┐
│                    Пользователь                         │
└─────────────────────────────────────────────────────────┘
                ↓                        ↓
        ┌──────────────────┐    ┌──────────────────┐
        │  GitHub Pages    │    │   VPS Backend    │
        │  Frontend        │    │  (155.212.139.51)│
        │  HTML/CSS/JS     │    │  PHP + MySQL     │
        │                  │←──→│  API endpoints   │
        └──────────────────┘    └──────────────────┘
   https://desyatovaelena11    https://155.212.139.51
   .github.io/moi-kursi/       .nip.io/backend/api/v1
```

---

## ✅ Что уже сделано

- ✅ Frontend обновлён на GitHub Pages (API_BASE = VPS URL)
- ✅ Backend файлы готовы к VPS развёртыванию
- ✅ Код на GitHub
- ✅ Документация DEPLOY_TO_VPS.md создана

---

## 📋 Что нужно сделать

### Этап 1: GitHub Pages (Frontend)

**На GitHub:**

1. Открой https://github.com/desyatovaelena11/moi-kursi
2. Нажми **Settings** → **Pages**
3. **Source**: `Deploy from a branch`
4. **Branch**: `main`
5. **Folder**: `/ (root)` → **Save**
6. Через 1-2 минуты frontend будет доступен:
   ```
   https://desyatovaelena11.github.io/moi-kursi/
   ```

### Этап 2: VPS Backend (155.212.139.51)

**На локальном компьютере:**

Открой два терминала

**Терминал 1 (SSH):**
```bash
ssh root@155.212.139.51
# Пароль: T4cHBb!6pfq7
```

Выполни команды из **DEPLOY_TO_VPS.md** (шаги 2-8)

**Терминал 2 (SCP upload):**
```bash
cd "d:\С раб.стола\Мои документы\Projects\Moi-kursi"

# Загружай файлы на VPS
scp -r backend root@155.212.139.51:/opt/moi-kursi/
scp .env root@155.212.139.51:/opt/moi-kursi/
scp docs/DATABASE.sql root@155.212.139.51:/opt/moi-kursi/
```

---

## 🧪 Проверка что всё работает

### 1. Проверь Backend API

Открой в браузере:
```
http://155.212.139.51.nip.io:8000/backend/api/v1/courses
```

Должна вернуться JSON:
```json
{
  "success": true,
  "data": []
}
```

### 2. Проверь Frontend

Открой:
```
https://desyatovaelena11.github.io/moi-kursi/
```

Должна загрузиться платформа с сообщением "Выбери курс слева"

### 3. Проверь что Frontend обращается к Backend

Открой браузер → **F12** (DevTools) → **Network** → обнови страницу

Должны быть запросы к:
```
https://155.212.139.51.nip.io/backend/api/v1/courses
```

Если видишь запросы и они возвращают данные — **ВСЁ РАБОТАЕТ!** ✅

---

## 📝 Дальнейшие действия

После успешного развёртывания:

### 1. Загрузи видео на Mail.ru Cloud

```bash
# Перейди в папку проекта
cd "d:\С раб.стола\Мои документы\Projects\Moi-kursi"

# Запусти скрипт загрузки
python scripts/upload_videos.py --folder "путь_к_видео"
```

### 2. Создай первый курс через API

```bash
curl -X POST https://155.212.139.51.nip.io/backend/api/v1/courses \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Мой первый курс",
    "description": "Описание курса"
  }'
```

### 3. Добавь разделы и уроки

API документация: [API.md](./docs/API.md)

---

## 🔍 Troubleshooting

### Frontend не загружается
- Проверь: https://desyatovaelena11.github.io/moi-kursi/
- Если 404 — зайди в GitHub Settings → Pages, проверь что enabled

### Backend недоступен (ошибка CORS)
- Это нормально при разработке
- Добавь CORS headers в backend/api/index.php:
```php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
```

### Ошибка подключения к БД на VPS
```bash
# На VPS проверь
mysql -u moi_kursi_user -pMoiKursi2026Secure! moi_kursi_db
SHOW TABLES;
```

### API возвращает 404
```bash
# На VPS проверь что файлы на месте
ls -la /opt/moi-kursi/backend/api/
# Должны быть: index.php, courses.php, sections.php, lessons.php
```

---

## 🎓 Полезные ссылки

- Frontend: https://desyatovaelena11.github.io/moi-kursi/
- Backend API: https://155.212.139.51.nip.io/backend/api/v1/
- GitHub: https://github.com/desyatovaelena11/moi-kursi
- VPS SSH: `ssh root@155.212.139.51`

---

## 📱 Mail.ru Cloud для видео

Видео хранятся отдельно от приложения для экономии места:

1. Регистрация: https://cloud.mail.ru
2. Email: `desyatova.elena11@mail.ru`
3. Пароль: `uw6T*N8DKi#5H3e`
4. Создай папку "Moi-Kursi" для организации видео

---

**Успехов с развёртыванием! 🚀**
