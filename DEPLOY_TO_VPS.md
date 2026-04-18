# Развёртывание Moi-Kursi на VPS (155.212.139.51)

Этот документ описывает как развернуть backend на том же VPS где работает olga-project.

## 📋 Предварительные требования

- SSH доступ к серверу: `root@155.212.139.51`
- Пароль: `T4cHBb!6pfq7`
- На сервере уже установлены: PHP, MySQL, Nginx

## 🚀 Шаги развёртывания

### Шаг 1: SSH доступ к серверу

```bash
ssh root@155.212.139.51
```

Введи пароль: `T4cHBb!6pfq7`

### Шаг 2: Создай директорию для проекта

```bash
mkdir -p /opt/moi-kursi
cd /opt/moi-kursi
```

### Шаг 3: Загрузи файлы на сервер (из локального компьютера)

Открой **второй терминал** на локальном компьютере и выполни:

```bash
# Перейди в папку проекта
cd "d:\С раб.стола\Мои документы\Projects\Moi-kursi"

# Загрузи backend на сервер
scp -r backend root@155.212.139.51:/opt/moi-kursi/
scp .env root@155.212.139.51:/opt/moi-kursi/
scp docs/DATABASE.sql root@155.212.139.51:/opt/moi-kursi/
```

Пароль: `T4cHBb!6pfq7`

### Шаг 4: Создай базу данных и пользователя

Вернись в **первый терминал** (SSH) и выполни:

```bash
mysql -u root << EOFDB
CREATE DATABASE IF NOT EXISTS moi_kursi_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'moi_kursi_user'@'localhost' IDENTIFIED BY 'MoiKursi2026Secure!';
GRANT ALL PRIVILEGES ON moi_kursi_db.* TO 'moi_kursi_user'@'localhost';
FLUSH PRIVILEGES;
EOFDB
```

### Шаг 5: Импортируй схему БД

```bash
cd /opt/moi-kursi
mysql -u moi_kursi_user -pMoiKursi2026Secure! moi_kursi_db < DATABASE.sql
```

### Шаг 6: Установи права доступа

```bash
cd /opt/moi-kursi
chmod -R 755 backend
chmod 600 .env
chown -R www-data:www-data backend
```

### Шаг 7: Настрой Nginx

Создай конфиг файл `/etc/nginx/sites-available/moi-kursi`:

```bash
cat > /etc/nginx/sites-available/moi-kursi << 'EOFNGINX'
server {
    listen 8000;
    server_name _;
    
    root /opt/moi-kursi;
    index index.php;
    
    # API endpoints
    location /backend/api/ {
        try_files $uri $uri/ @api;
    }
    
    location @api {
        rewrite ^/backend/api/v1/(.*)$ /backend/api/index.php?request=$1 last;
    }
    
    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
    
    # Deny access to config and src
    location ~ /backend/(config|src)/ {
        deny all;
    }
}
EOFNGINX
```

Включи сайт:

```bash
ln -sf /etc/nginx/sites-available/moi-kursi /etc/nginx/sites-enabled/
nginx -t  # Проверь конфиг
systemctl restart nginx
```

### Шаг 8: Проверка

Открой в браузере:

```
http://155.212.139.51.nip.io:8000/backend/api/v1/courses
```

Должна вернуться JSON с курсами.

---

## 📡 Использование nip.io домена

`155.212.139.51.nip.io` автоматически разрешается в IP `155.212.139.51`.

Это значит что:
- `https://155.212.139.51.nip.io` = `https://155.212.139.51`
- Работает везде, как обычный домен
- Не требует DNS конфигурации
- Поддерживает HTTPS через Let's Encrypt

---

## 🔍 Troubleshooting

### Ошибка "Connection refused"
```bash
systemctl status nginx
systemctl restart nginx
```

### Ошибка "Database connection failed"
```bash
mysql -u moi_kursi_user -pMoiKursi2026Secure! moi_kursi_db
# Если подключится - БД работает
```

### PHP ошибки в логах
```bash
tail -f /var/log/php-fpm.log
```

### Nginx ошибки
```bash
tail -f /var/log/nginx/error.log
```

---

## 📝 Дальнейшие действия

1. ✅ Развернул backend на VPS
2. ⏳ Загрузи frontend на GitHub Pages
3. ⏳ Загрузи видео на Mail.ru Cloud
4. ⏳ Проверь что всё работает вместе
