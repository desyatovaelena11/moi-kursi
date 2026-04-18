# ⚡ Быстрый старт Moi-Kursi

Все данные уже заполнены в `.env`. Вот пошаговая инструкция на 5 минут.

## Шаг 1: Загрузи файлы на сервер (2 минуты)

Открой терминал в папке проекта и запусти:

```bash
bash scripts/upload-files.sh
```

Скрипт:
- ✅ Установит нужные инструменты (sshpass)
- ✅ Подключится к серверу
- ✅ Загрузит все файлы проекта
- ✅ Загрузит конфигурацию (.env)

Должен увидеть:
```
✅ Files uploaded!
```

## Шаг 2: Инициализируй базу данных (1 минута)

1. Открой в браузере:
   ```
   https://elendes10.beget.tech/backend/install.php
   ```

2. Следуй инструкциям на странице

3. Когда будет "Installation Complete! 🎉" - готово!

## Шаг 3: Проверь что работает (1 минута)

Открой в браузере:

```
https://elendes10.beget.tech/frontend/
```

Должен увидеть:
- ✓ Заголовок "📚 Moi-Kursi"
- ✓ Поле поиска
- ✓ Сообщение "Выбери курс слева"

Также проверь API:
```
https://elendes10.beget.tech/backend/api/v1/courses
```

Должен быть JSON (пока пустой, т.к. курсов нет)

## Шаг 4: Загрузи видео на Mail.ru Cloud (зависит от размера 🎬)

Если у тебя есть видео в `D:\Videos`:

```bash
pip install python-dotenv requests
python3 scripts/upload_videos.py
```

Скрипт загрузит видео и сохранит ссылки в `video_links.json`

## Шаг 5: Заполни базу данных курсами (2 минуты)

Создай файл `courses.csv` или используй пример:

```bash
python3 scripts/populate_database.py --file scripts/courses_example.csv
```

После этого:
```
https://elendes10.beget.tech/frontend/
```

Должны показаться курсы! 🎉

---

## ❓ Если что-то не работает

### ❌ "sshpass: command not found"
```bash
# Linux
sudo apt-get install sshpass

# Mac
brew install sshpass

# Windows (используй Git Bash или WSL)
```

### ❌ "Permission denied" при загрузке файлов
Проверь пароль в `.env`:
```
SSH_PASSWORD=T4scHbbl6pfq7
```

### ❌ "install.php не загружается"
Проверь что файлы загружены:
- Открой FTP клиент (FileZilla)
- Проверь что в `public_html/backend/` есть файлы

### ❌ "API возвращает 404"
Проверь что `.htaccess` загружен в `backend/`

---

## 🎉 Готово!

Твоя платформа видеокурсов онлайн!

```
Frontend: https://elendes10.beget.tech/frontend/
API:      https://elendes10.beget.tech/backend/api/v1/courses
```

Дальше можешь:
- 📝 Добавлять новые курсы через API
- 🎨 Менять дизайн (редактируй `frontend/css/style.css`)
- 📱 Делиться ссылкой с другими людьми

Смотри `docs/DEPLOYMENT.md` для полной документации.
