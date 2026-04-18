# 🚀 Полный гайд развёртывания Moi-Kursi

Этот документ описывает полный процесс развёртывания платформы на Beget с использованием автоматизированных скриптов.

## Содержание

1. [Подготовка](#подготовка)
2. [Конфигурация](#конфигурация)
3. [Развёртывание на Beget](#развёртывание-на-beget)
4. [Загрузка видео](#загрузка-видео)
5. [Заполнение БД](#заполнение-бд)
6. [Тестирование](#тестирование)
7. [Решение проблем](#решение-проблем)

---

## Подготовка

### Шаг 1: Соберись с силами

Перед началом у тебя должно быть:

- ✅ Аккаунт на [Beget](https://beget.com)
- ✅ FTP доступ к Beget (из панели управления)
- ✅ Аккаунт на [Mail.ru Cloud](https://cloud.mail.ru)
- ✅ Git установлен на компьютер
- ✅ Python 3.6+ (для скриптов загрузки видео)
- ✅ Папка с твоими видеофайлами

### Шаг 2: Клонируй репозиторий

```bash
git clone https://github.com/desyatovaelena11/moi-kursi.git
cd moi-kursi
```

---

## Конфигурация

### Шаг 1: Создай файл конфигурации

Копируй `.env.example` в `.env`:

```bash
cp .env.example .env
```

### Шаг 2: Заполни `.env` своими данными

Открой `.env` в текстовом редакторе и заполни:

```ini
# ============================================
# Beget Database
# ============================================
DB_HOST=localhost
DB_USER=your_db_user        # Из панели Beget
DB_PASS=your_db_password    # Из панели Beget
DB_NAME=username_moikursi   # Имя БД которую создал

# ============================================
# Beget FTP
# ============================================
FTP_HOST=your-domain.beget.com
FTP_USER=your_ftp_login
FTP_PASS=your_ftp_password
FTP_PORT=21
FTP_REMOTE_PATH=/public_html

# ============================================
# Mail.ru Cloud
# ============================================
MAILRU_EMAIL=your.email@mail.ru
MAILRU_PASSWORD=your_mailru_password

# ============================================
# URLs
# ============================================
API_BASE_URL=https://yourdomain.ru/backend/api/v1
FRONTEND_BASE_URL=https://yourdomain.ru
```

**Где найти эти данные?**

- **Beget FTP:** Панель управления → Управление → Доступ по FTP
- **Beget MySQL:** Панель управления → MySQL → Твоя БД
- **Mail.ru Cloud:** Аккаунт → Настройки → Приложения

⚠️ **ВАЖНО:** `.env` содержит пароли - никогда не коммитируй его в Git!

---

## Развёртывание на Beget

### Способ 1: Автоматически (Linux/Mac)

Если у тебя bash и lftp:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh
```

Скрипт автоматически:
1. Соберёт файлы проекта
2. Загрузит их на Beget по FTP
3. Скажет тебе что дальше делать

### Способ 2: Вручную через FileZilla

1. Открой [FileZilla](https://filezilla-project.org/)
2. Подключись к Beget:
   - Host: `FTP_HOST` из .env
   - Username: `FTP_USER` из .env
   - Password: `FTP_PASS` из .env
   - Port: `21`

3. Загрузи файлы:
   - `backend/` → `public_html/backend/`
   - `frontend/` → `public_html/frontend/`
   - `docs/` → `public_html/docs/`

4. **Важно:** Убедись что на Beget есть файлы:
   ```
   public_html/
   ├── backend/
   │   ├── api/
   │   ├── config/
   │   ├── src/
   │   ├── .htaccess
   │   └── install.php
   ├── frontend/
   │   ├── index.html
   │   ├── css/
   │   └── js/
   └── docs/
   ```

### Шаг 3: Инициализируй БД

1. Скопируй `.env` на Beget в корень проекта
   - Через FileZilla или SSH

2. Открой в браузере:
   ```
   https://yourdomain.ru/backend/install.php
   ```

3. Следуй инструкциям на странице установки

   Скрипт сделает:
   - ✓ Проверит подключение к БД
   - ✓ Создаст таблицы (courses, sections, lessons)
   - ✓ Покажет готовые URL для API

4. Когда будет сообщение **"Installation Complete! 🎉"** - можно удалить `install.php`:

   ```bash
   # Через SSH или FileZilla
   rm public_html/backend/install.php
   ```

✅ База данных готова!

---

## Загрузка видео

### Способ 1: Автоматически через Python

```bash
# Установи зависимости
pip install python-dotenv requests

# Загрузи все видео из папки
python3 scripts/upload_videos.py --folder D:/videos

# Результат сохранится в video_links.json
```

Скрипт:
- Подключится к Mail.ru Cloud
- Загрузит все видео из папки
- Сохранит все ссылки в `video_links.json`

### Способ 2: Вручную в Web интерфейсе

1. Открой https://cloud.mail.ru
2. Авторизируйся
3. Создай папку `/Курсы`
4. Загрузи туда свои видеофайлы
5. Для каждого видео:
   - Правый клик → "Поделиться"
   - Скопируй "Прямую ссылку"

**Пример прямой ссылки:**
```
https://cloud.mail.ru/public/xxxxx/filename.mp4
```

---

## Заполнение БД

### Подготовка данных

Создай файл со структурой курсов в формате CSV или JSON.

#### CSV формат (`courses.csv`):

```
Course Name,Course Description,Section Name,Lesson Name,Video URL,Duration (seconds)
Python Basics,Learn Python from scratch,Introduction,What is Python,https://cloud.mail.ru/...,600
Python Basics,Learn Python from scratch,Introduction,Installing Python,https://cloud.mail.ru/...,900
```

Или используй пример: `scripts/courses_example.csv`

#### JSON формат (`courses.json`):

```json
[
  {
    "name": "Python Basics",
    "description": "Learn Python from scratch",
    "sections": [
      {
        "name": "Introduction",
        "lessons": [
          {
            "name": "What is Python",
            "video_url": "https://cloud.mail.ru/...",
            "duration": 600
          }
        ]
      }
    ]
  }
]
```

Или используй пример: `scripts/courses_example.json`

### Загрузка в БД

```bash
# Установи зависимости
pip install python-dotenv requests

# Загрузи из CSV
python3 scripts/populate_database.py --file courses.csv

# Или из JSON
python3 scripts/populate_database.py --file courses.json
```

Скрипт через API:
1. Создаст курсы
2. Создаст разделы
3. Создаст уроки с видеоссылками

✅ База данных заполнена!

---

## Тестирование

### Проверь что всё работает

#### 1. Тест API

Открой в браузере (замени `yourdomain.ru` на свой домен):

```
https://yourdomain.ru/backend/api/v1/courses
```

Должен увидеть JSON со списком курсов:

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Python Basics",
      "description": "...",
      "sections": [...]
    }
  ]
}
```

#### 2. Тест Frontend

Открой в браузере:

```
https://yourdomain.ru/frontend/
```

Или (если frontend в корне):

```
https://yourdomain.ru/
```

Должен увидеть:
- ✓ Список курсов слева
- ✓ Поле поиска сверху
- ✓ После клика на курс - список разделов
- ✓ После клика на урок - видеоплеер с видео

#### 3. Тест видео

В просмотре видео:
- ✓ Видео проигрывается
- ✓ Работают кнопки play/pause
- ✓ Работает регулятор громкости
- ✓ Видно время видео

### Если что-то не работает

Смотри раздел [Решение проблем](#решение-проблем) ниже.

---

## Решение проблем

### ❌ "API не загружается" (404)

**Причина:** Неправильные пути или `.htaccess` не работает

**Решение:**

1. Проверь что `backend/.htaccess` загружен на Beget
2. Убедись что путь API_BASE правильный в `app.js`:
   ```javascript
   // Должно быть одно из:
   const API_BASE = '/api/v1';                    // Если backend в корне
   const API_BASE = '/backend/api/v1';            // Если backend в папке
   const API_BASE = 'https://yourdomain.ru/...';  // Полный URL
   ```
3. Проверь что на Beget есть файлы:
   - `public_html/backend/api/index.php`
   - `public_html/backend/api/courses.php`
   - `public_html/backend/.htaccess`

### ❌ "БД не подключается" (Error connecting)

**Причина:** Неправильные данные в `.env` или БД не существует

**Решение:**

1. Проверь `.env`:
   ```
   DB_HOST = localhost (всегда localhost на Beget)
   DB_USER = правильное имя пользователя БД
   DB_PASS = правильный пароль
   DB_NAME = имя БД которое создал
   ```

2. Если не уверен - создай новую БД в панели Beget:
   - Панель управления → MySQL
   - Создай новую БД
   - Создай пользователя с доступом
   - Обнови `.env`

3. Запусти `install.php` снова

### ❌ "Видео не воспроизводится"

**Причина:** Неправильная ссылка на Mail.ru Cloud

**Решение:**

1. Убедись что ссылка это **прямая ссылка** на видео, не на папку
   - Правильно: `https://cloud.mail.ru/public/xxxxx/video.mp4`
   - Неправильно: `https://cloud.mail.ru/public/xxxxx/` (без имени файла)

2. Проверь что ссылка работает - открой её в новой вкладке браузера

3. Если видео не видно в Mail.ru Cloud:
   - Раньше видео загружалось ночью (долго)
   - Дождись когда оно появится в облаке

4. Убедись что в БД стоит правильная ссылка:
   ```bash
   # Проверь через API
   curl https://yourdomain.ru/backend/api/v1/lessons/1
   ```

### ❌ "Ошибка при загрузке видео" (Python скрипт)

**Решение:**

1. Убедись что Python 3.6+ установлен:
   ```bash
   python3 --version
   ```

2. Установи зависимости:
   ```bash
   pip install python-dotenv requests
   ```

3. Проверь `.env`:
   - `MAILRU_EMAIL` - правильный email от Mail.ru
   - `MAILRU_PASSWORD` - правильный пароль
   - `LOCAL_VIDEOS_PATH` - папка с видео существует

4. Попробуй сначала с одним маленьким видео для теста

### ❌ "Поиск не работает"

**Причина:** Frontend не загружает курсы из API

**Решение:**

1. Проверь консоль браузера (F12):
   - Есть ли ошибки в консоли?
   - Есть ли Network ошибки?

2. Проверь что API доступен:
   - Открой https://yourdomain.ru/backend/api/v1/courses
   - Должен быть JSON

3. Если API возвращает 404:
   - Смотри выше решение для "API не загружается"

---

## Что дальше?

После успешного развёртывания ты можешь:

- 📝 **Добавлять новые курсы** через API (или через скрипт populate_database.py)
- 🔄 **Обновлять видео** - просто замени video_url в БД на новую ссылку
- 📱 **Делиться платформой** - дай другим людям ссылку на https://yourdomain.ru
- 🎨 **Менять дизайн** - отредактируй `frontend/css/style.css`

### Полезные API запросы

```bash
# Получить все курсы
curl https://yourdomain.ru/backend/api/v1/courses

# Получить курс с разделами и уроками
curl https://yourdomain.ru/backend/api/v1/courses/1

# Создать новый курс
curl -X POST https://yourdomain.ru/backend/api/v1/courses \
  -H "Content-Type: application/json" \
  -d '{"name":"Новый курс","description":"Описание"}'

# Смотри полную документацию в docs/API.md
```

---

## Поддержка

Если что-то не работает:

1. **Сначала смотри SETUP.md** - там есть базовые инструкции
2. **Потом смотри этот файл (DEPLOYMENT.md)** - тут способы автоматизации
3. **Смотри API.md** - там примеры запросов
4. **Проверь консоль браузера (F12)** - там часто видны ошибки
5. **Проверь логи на Beget** - в панели управления

---

**✅ Готово! Твоя платформа видеокурсов онлайн!** 🎉
