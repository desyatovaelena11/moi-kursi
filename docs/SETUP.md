# Инструкция по развёртыванию Moi-Kursi на Beget

## 📋 Требования

- Аккаунт на Beget (Blog тариф или выше)
- Доступ к панели управления Beget
- Mail.ru Cloud аккаунт (для хранения видео)
- Базовые знания FTP/SSH

## 🚀 Шаг 1: Подготовка Beget

### 1.1 Вход в панель управления

1. Открой [cp.beget.com](https://cp.beget.com)
2. Введи логин и пароль
3. Перейди в раздел **"Управление"** → **"Сайты"**

### 1.2 Создание базы данных

1. В панели управления найди **"MySQL"**
2. Нажми **"Создать новую базу данных"**
3. Заполни данные:
   - **Имя БД:** `username_moikursi` (замени `username` на твой)
   - **Пользователь:** создай нового или используй существующего
   - **Пароль:** используй сильный пароль
4. Запомни эти данные - они нужны для конфига

### 1.3 Сохранение учётных данных БД

```php
DB_HOST = localhost
DB_USER = your_db_user (из панели Beget)
DB_PASS = your_db_password (из панели Beget)
DB_NAME = username_moikursi (имя которое создал)
```

## 📁 Шаг 2: Загрузка файлов на Beget

### 2.1 Через FTP (рекомендуется для начинающих)

1. Открой FTP клиент (FileZilla, Transmit и т.д.)
2. Подключись к Beget (данные в панели управления):
   - **Host:** твой FTP адрес (из панели)
   - **Username:** твой FTP логин
   - **Password:** твой FTP пароль
3. Открой папку `public_html/`
4. **Скопируй туда:**
   - Папку `backend/` → `public_html/backend/`
   - Папку `frontend/` → `public_html/frontend/` (или `public_html/`)

### 2.2 Через SSH (для опытных)

```bash
# Подключись по SSH
ssh username@beget.com

# Перейди в директорию
cd ~/public_html

# Склонируй репозиторий
git clone https://github.com/desyatovaelena11/moi-kursi.git .

# Или скопируй файлы вручную
```

## ⚙️ Шаг 3: Конфигурирование

### 3.1 Обновление конфига БД

1. Открой файл `backend/config/db.php` (через FTP или SSH)
2. Замени значения:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_USER', 'твой_юзер_БД');      // Из шага 1.2
   define('DB_PASS', 'твой_пароль_БД');    // Из шага 1.2
   define('DB_NAME', 'username_moikursi'); // Из шага 1.2
   ```
3. Сохрани файл

### 3.2 Обновление API URL в frontend

1. Открой файл `frontend/js/app.js`
2. Найди строку `const API_BASE = '/api/v1';`
3. Если ты разместил backend в отдельной папке, обнови путь:
   ```javascript
   const API_BASE = '/backend/api/v1'; // Если backend в папке /backend
   // или
   const API_BASE = 'https://yourdomain.ru/backend/api/v1'; // Полный URL
   ```
4. Сохрани файл

## 🗄️ Шаг 4: Создание таблиц БД

### 4.1 Через phpMyAdmin (в панели Beget)

1. В панели управления Beget открой **"phpMyAdmin"**
2. Выбери твою БД (которую создал в шаге 1.2)
3. Открой вкладку **"SQL"**
4. Скопируй всё содержимое файла `docs/DATABASE.sql`
5. Вставь в окно SQL и нажми **"Выполнить"**

### 4.2 Через SSH

```bash
# Подключись по SSH
ssh username@beget.com

# Подключись к MySQL
mysql -h localhost -u твой_юзер -p твоя_БД < ~/moi-kursi/docs/DATABASE.sql

# Введи пароль БД и готово
```

## 🌐 Шаг 5: Доступ к платформе

После того как всё загружено и сконфигурировано:

### Веб-интерфейс

- Если frontend в `public_html/frontend/` → открой `https://yourdomain.ru/frontend/`
- Если frontend в корне `public_html/` → открой `https://yourdomain.ru/`

### API

- `https://yourdomain.ru/backend/api/v1/courses` - список всех курсов
- `https://yourdomain.ru/backend/api/v1/courses/1` - один курс с разделами

## 📹 Шаг 6: Загрузка видео на Mail.ru Cloud

1. Открой [cloud.mail.ru](https://cloud.mail.ru)
2. Создай папки по курсам:
   ```
   /Курс 1
   /Курс 2
   /Курс 3
   ```
3. Загрузи видеофайлы в папки
4. Для каждого видео получи **прямую ссылку на воспроизведение**
5. Добавь эти ссылки в БД (поле `video_url`)

## 🔐 Безопасность

### Важно:

1. **Защита конфига БД:**
   - Убедись что `backend/config/db.php` недоступен напрямую из браузера
   - Включён `.htaccess` для блокировки доступа к папке `config/`

2. **Пароли:**
   - Используй сильные пароли для БД
   - Не коммитируй реальные пароли в Git (только в локальный конфиг)

3. **HTTPS:**
   - Убедись что твой домен использует HTTPS (SSL сертификат)
   - Mail.ru Cloud требует HTTPS для видео

## 🐛 Решение проблем

### API не загружается
```
Ошибка: "Repository not found" или 404
Решение:
1. Проверь что путь API_BASE правильный в app.js
2. Убедись что backend файлы загружены на Beget
3. Проверь что .htaccess включён
```

### Видео не воспроизводится
```
Ошибка: видео не грузится
Решение:
1. Проверь что ссылка на видео (video_url) правильная
2. Убедись что ссылка работает (открой в новой вкладке)
3. Проверь что это прямая ссылка на видео, не на папку
```

### БД не подключается
```
Ошибка: "Connection refused" или "Access denied"
Решение:
1. Проверь учётные данные в backend/config/db.php
2. Убедись что БД создана в панели Beget
3. Убедись что пользователь БД имеет права на доступ
```

## 📞 Контакты поддержки

- **Beget:** [support.beget.com](https://support.beget.com)
- **Mail.ru Cloud:** [help.mail.ru](https://help.mail.ru)
- **GitHub Issues:** [Создать issue](https://github.com/desyatovaelena11/moi-kursi/issues)

---

**Готово!** 🎉 Платформа развёрнута и готова к использованию.
