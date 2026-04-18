# API Документация Moi-Kursi

## Основная информация

**Базовый URL:** `https://yourdomain.ru/backend/api/v1`

**Формат ответа:** JSON

**Кодировка:** UTF-8

---

## Структура ответов

### Успешный ответ (200 OK)

```json
{
  "success": true,
  "data": {
    // данные здесь
  },
  "message": "Успешно"
}
```

### Ошибка (4xx, 5xx)

```json
{
  "success": false,
  "error": "Описание ошибки",
  "message": "Что-то пошло не так"
}
```

---

## 📚 Курсы (Courses)

### GET /courses

Получить список всех курсов.

**Параметры:**
- Нет

**Ответ (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Мой первый курс",
      "description": "Описание первого курса",
      "order": 1,
      "created_at": "2026-01-15 10:30:00",
      "updated_at": "2026-01-15 10:30:00"
    },
    {
      "id": 2,
      "name": "Второй курс",
      "description": "Описание второго курса",
      "order": 2,
      "created_at": "2026-01-16 14:20:00",
      "updated_at": "2026-01-16 14:20:00"
    }
  ],
  "message": "Успешно"
}
```

**Ошибки:**
- `500`: Ошибка подключения к БД

---

### GET /courses/{id}

Получить один курс со всеми разделами и уроками (вложенная структура).

**Параметры:**
- `id` (int) — ID курса

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Мой первый курс",
    "description": "Описание первого курса",
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-01-15 10:30:00",
    "sections": [
      {
        "id": 1,
        "course_id": 1,
        "name": "Раздел 1",
        "description": "Первый раздел первого курса",
        "order": 1,
        "created_at": "2026-01-15 10:30:00",
        "updated_at": "2026-01-15 10:30:00",
        "lessons": [
          {
            "id": 1,
            "section_id": 1,
            "name": "Урок 1",
            "description": "Описание первого урока",
            "video_url": "https://cloud.mail.ru/public/example/video1.mp4",
            "duration": 600,
            "order": 1,
            "created_at": "2026-01-15 10:30:00",
            "updated_at": "2026-01-15 10:30:00"
          },
          {
            "id": 2,
            "section_id": 1,
            "name": "Урок 2",
            "description": "Описание второго урока",
            "video_url": "https://cloud.mail.ru/public/example/video2.mp4",
            "duration": 900,
            "order": 2,
            "created_at": "2026-01-15 10:31:00",
            "updated_at": "2026-01-15 10:31:00"
          }
        ]
      }
    ]
  },
  "message": "Успешно"
}
```

**Ошибки:**
- `404`: Курс не найден
- `500`: Ошибка подключения к БД

---

### POST /courses

Создать новый курс.

**Параметры (JSON body):**
- `name` (string, обязательный) — Название курса
- `description` (string, опциональный) — Описание курса
- `order` (int, опциональный) — Порядок сортировки (по умолчанию 0)

**Пример запроса:**

```bash
curl -X POST https://yourdomain.ru/backend/api/v1/courses \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Новый курс",
    "description": "Это мой новый курс",
    "order": 3
  }'
```

**Ответ (201):**

```json
{
  "success": true,
  "data": {
    "id": 3,
    "name": "Новый курс",
    "description": "Это мой новый курс",
    "order": 3,
    "created_at": "2026-04-18 12:00:00",
    "updated_at": "2026-04-18 12:00:00"
  },
  "message": "Курс создан"
}
```

**Ошибки:**
- `400`: Отсутствует поле "name"
- `500`: Ошибка при создании

---

### PUT /courses/{id}

Обновить курс.

**Параметры:**
- `id` (int) — ID курса (в URL)
- `name` (string, опциональный) — Новое название
- `description` (string, опциональный) — Новое описание
- `order` (int, опциональный) — Новый порядок

**Пример запроса:**

```bash
curl -X PUT https://yourdomain.ru/backend/api/v1/courses/1 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Обновленное название",
    "description": "Новое описание"
  }'
```

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Обновленное название",
    "description": "Новое описание",
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-04-18 12:05:00"
  },
  "message": "Курс обновлен"
}
```

**Ошибки:**
- `404`: Курс не найден
- `500`: Ошибка при обновлении

---

### DELETE /courses/{id}

Удалить курс со всеми разделами и уроками.

**Параметры:**
- `id` (int) — ID курса

**Пример запроса:**

```bash
curl -X DELETE https://yourdomain.ru/backend/api/v1/courses/1
```

**Ответ (200):**

```json
{
  "success": true,
  "message": "Курс удален"
}
```

**Ошибки:**
- `404`: Курс не найден
- `500`: Ошибка при удалении

---

## 📂 Разделы (Sections)

### GET /sections?course_id={id}

Получить разделы конкретного курса.

**Параметры:**
- `course_id` (int) — ID курса

**Ответ (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "course_id": 1,
      "name": "Раздел 1",
      "description": "Первый раздел первого курса",
      "order": 1,
      "created_at": "2026-01-15 10:30:00",
      "updated_at": "2026-01-15 10:30:00"
    }
  ],
  "message": "Успешно"
}
```

**Ошибки:**
- `400`: Отсутствует параметр course_id
- `500`: Ошибка подключения к БД

---

### GET /sections/{id}

Получить один раздел со всеми уроками.

**Параметры:**
- `id` (int) — ID раздела

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "course_id": 1,
    "name": "Раздел 1",
    "description": "Первый раздел первого курса",
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-01-15 10:30:00",
    "lessons": [
      {
        "id": 1,
        "section_id": 1,
        "name": "Урок 1",
        "description": "Описание первого урока",
        "video_url": "https://cloud.mail.ru/public/example/video1.mp4",
        "duration": 600,
        "order": 1,
        "created_at": "2026-01-15 10:30:00",
        "updated_at": "2026-01-15 10:30:00"
      }
    ]
  },
  "message": "Успешно"
}
```

**Ошибки:**
- `404`: Раздел не найден
- `500`: Ошибка подключения к БД

---

### POST /sections

Создать новый раздел.

**Параметры (JSON body):**
- `course_id` (int, обязательный) — ID курса
- `name` (string, обязательный) — Название раздела
- `description` (string, опциональный) — Описание
- `order` (int, опциональный) — Порядок сортировки

**Пример запроса:**

```bash
curl -X POST https://yourdomain.ru/backend/api/v1/sections \
  -H "Content-Type: application/json" \
  -d '{
    "course_id": 1,
    "name": "Новый раздел",
    "description": "Описание нового раздела",
    "order": 3
  }'
```

**Ответ (201):**

```json
{
  "success": true,
  "data": {
    "id": 4,
    "course_id": 1,
    "name": "Новый раздел",
    "description": "Описание нового раздела",
    "order": 3,
    "created_at": "2026-04-18 12:00:00",
    "updated_at": "2026-04-18 12:00:00"
  },
  "message": "Раздел создан"
}
```

**Ошибки:**
- `400`: Отсутствуют обязательные поля
- `404`: Курс не найден
- `500`: Ошибка при создании

---

### PUT /sections/{id}

Обновить раздел.

**Параметры:**
- `id` (int) — ID раздела (в URL)
- `name` (string, опциональный) — Новое название
- `description` (string, опциональный) — Новое описание
- `order` (int, опциональный) — Новый порядок

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "course_id": 1,
    "name": "Обновленный раздел",
    "description": "Новое описание раздела",
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-04-18 12:05:00"
  },
  "message": "Раздел обновлен"
}
```

---

### DELETE /sections/{id}

Удалить раздел со всеми уроками.

**Параметры:**
- `id` (int) — ID раздела

**Ответ (200):**

```json
{
  "success": true,
  "message": "Раздел удален"
}
```

---

## 🎥 Уроки (Lessons)

### GET /lessons?section_id={id}

Получить уроки конкретного раздела.

**Параметры:**
- `section_id` (int) — ID раздела

**Ответ (200):**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "section_id": 1,
      "name": "Урок 1",
      "description": "Описание первого урока",
      "video_url": "https://cloud.mail.ru/public/example/video1.mp4",
      "duration": 600,
      "order": 1,
      "created_at": "2026-01-15 10:30:00",
      "updated_at": "2026-01-15 10:30:00"
    }
  ],
  "message": "Успешно"
}
```

---

### GET /lessons/{id}

Получить один урок.

**Параметры:**
- `id` (int) — ID урока

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "section_id": 1,
    "name": "Урок 1",
    "description": "Описание первого урока",
    "video_url": "https://cloud.mail.ru/public/example/video1.mp4",
    "duration": 600,
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-01-15 10:30:00"
  },
  "message": "Успешно"
}
```

---

### POST /lessons

Создать новый урок.

**Параметры (JSON body):**
- `section_id` (int, обязательный) — ID раздела
- `name` (string, обязательный) — Название урока
- `description` (string, опциональный) — Описание урока
- `video_url` (string, обязательный) — URL видео (ссылка на Mail.ru Cloud)
- `duration` (int, опциональный) — Длительность в секундах
- `order` (int, опциональный) — Порядок сортировки

**Пример запроса:**

```bash
curl -X POST https://yourdomain.ru/backend/api/v1/lessons \
  -H "Content-Type: application/json" \
  -d '{
    "section_id": 1,
    "name": "Новый урок",
    "description": "Описание нового урока",
    "video_url": "https://cloud.mail.ru/public/example/video5.mp4",
    "duration": 1200,
    "order": 3
  }'
```

**Ответ (201):**

```json
{
  "success": true,
  "data": {
    "id": 5,
    "section_id": 1,
    "name": "Новый урок",
    "description": "Описание нового урока",
    "video_url": "https://cloud.mail.ru/public/example/video5.mp4",
    "duration": 1200,
    "order": 3,
    "created_at": "2026-04-18 12:00:00",
    "updated_at": "2026-04-18 12:00:00"
  },
  "message": "Урок создан"
}
```

**Ошибки:**
- `400`: Отсутствуют обязательные поля
- `404`: Раздел не найден
- `500`: Ошибка при создании

---

### PUT /lessons/{id}

Обновить урок.

**Параметры:**
- `id` (int) — ID урока (в URL)
- `name` (string, опциональный) — Новое название
- `description` (string, опциональный) — Новое описание
- `video_url` (string, опциональный) — Новый URL видео
- `duration` (int, опциональный) — Новая длительность
- `order` (int, опциональный) — Новый порядок

**Ответ (200):**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "section_id": 1,
    "name": "Обновленный урок",
    "description": "Новое описание",
    "video_url": "https://cloud.mail.ru/public/example/video_updated.mp4",
    "duration": 1500,
    "order": 1,
    "created_at": "2026-01-15 10:30:00",
    "updated_at": "2026-04-18 12:05:00"
  },
  "message": "Урок обновлен"
}
```

---

### DELETE /lessons/{id}

Удалить урок.

**Параметры:**
- `id` (int) — ID урока

**Ответ (200):**

```json
{
  "success": true,
  "message": "Урок удален"
}
```

---

## 🔐 Безопасность

### Защита от XSS
- Все данные в frontend экранируются функцией `escapeHtml()`
- API возвращает чистые данные из БД

### Защита от SQL-инъекций
- Используются подготовленные запросы (prepared statements)
- Параметры привязываются через `bind_param()`

### HTTPS
- Все запросы должны идти через HTTPS
- HTTP перередиректится на HTTPS через `.htaccess`

### CORS
- API включает необходимые CORS заголовки:
  ```
  Access-Control-Allow-Origin: *
  Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS
  Access-Control-Allow-Headers: Content-Type
  ```

---

## ⚠️ Коды ошибок

| Код | Описание | Решение |
|-----|---------|---------|
| `200` | OK | Запрос выполнен успешно |
| `201` | Created | Ресурс создан успешно |
| `400` | Bad Request | Проверь параметры запроса |
| `404` | Not Found | Ресурс не найден (ID неверный) |
| `405` | Method Not Allowed | Метод не поддерживается для этого эндпоинта |
| `500` | Internal Server Error | Ошибка сервера (БД, синтаксис PHP) |

---

## 📝 Примеры использования

### Полный поток: создание курса с разделом и уроком

```bash
# 1. Создать курс
curl -X POST https://yourdomain.ru/backend/api/v1/courses \
  -H "Content-Type: application/json" \
  -d '{"name":"Python Basics","description":"Курс основ Python","order":1}'

# Ответ содержит id: 3

# 2. Создать раздел в курсе
curl -X POST https://yourdomain.ru/backend/api/v1/sections \
  -H "Content-Type: application/json" \
  -d '{"course_id":3,"name":"Введение","description":"Начнём с основ","order":1}'

# Ответ содержит id: 5

# 3. Создать урок в разделе
curl -X POST https://yourdomain.ru/backend/api/v1/lessons \
  -H "Content-Type: application/json" \
  -d '{"section_id":5,"name":"Что такое Python?","video_url":"https://cloud.mail.ru/...","duration":600,"order":1}'

# 4. Получить весь курс с вложенными разделами и уроками
curl https://yourdomain.ru/backend/api/v1/courses/3
```

### Проверка доступности API

```bash
# Простой тест
curl https://yourdomain.ru/backend/api/v1/courses

# Должен вернуть JSON со списком курсов
```

---

## 🧪 Тестирование

### В браузере

Просто открой в браузере:
```
https://yourdomain.ru/backend/api/v1/courses
```

Браузер покажет JSON ответ.

### В Postman

1. Создай новый Request
2. Выбери метод (GET/POST/PUT/DELETE)
3. Введи URL
4. Для POST/PUT добавь JSON body в вкладке Body
5. Нажми Send

### В командной строке (curl)

Все примеры выше используют curl. Адаптируй под свой домен и ID.

---

## 🔄 Порядок полей (сортировка)

Все таблицы поддерживают поле `order` для кастомной сортировки:
- Курсы сортируются по `order` в GET /courses
- Разделы сортируются по `order` в GET /sections?course_id={id}
- Уроки сортируются по `order` в GET /lessons?section_id={id}

Установи `order` вручную через PUT запросы для переупорядочения.

---

**Версия:** 1.0  
**Последнее обновление:** 2026-04-18  
**Автор:** Moi-Kursi Platform
