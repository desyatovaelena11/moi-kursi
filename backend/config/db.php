<?php
/**
 * Database Configuration
 * Параметры подключения к MySQL на Beget
 */

// Для локального развития (если нужно тестировать локально)
if ($_SERVER['HTTP_HOST'] === 'localhost' || $_SERVER['HTTP_HOST'] === 'localhost:8000') {
    define('DB_HOST', 'localhost');
    define('DB_USER', 'root');
    define('DB_PASS', 'root');
    define('DB_NAME', 'moi_kursi');
} else {
    // Для Beget (замени на свои данные из панели управления Beget)
    define('DB_HOST', 'localhost');           // Обычно localhost на Beget
    define('DB_USER', 'your_username');       // Твой пользователь БД (из панели Beget)
    define('DB_PASS', 'your_password');       // Твой пароль БД
    define('DB_NAME', 'your_database_name');  // Имя БД (обычно username_dbname)
}

// Общие параметры
define('DB_CHARSET', 'utf8mb4');
define('DB_COLLATE', 'utf8mb4_unicode_ci');

// Для CORS (доступ с фронтенда)
define('ALLOWED_ORIGINS', ['http://localhost:3000', 'http://localhost', 'https://yourdomain.ru']);

// API версия
define('API_VERSION', 'v1');
define('API_BASE_URL', '/api/' . API_VERSION);

// Временная зона
date_default_timezone_set('UTC');
