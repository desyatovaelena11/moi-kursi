<?php
/**
 * API Router
 * Точка входа для всех API запросов
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Обработка preflight запросов (для CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Подключаем конфиг и классы
require_once '../config/db.php';
require_once '../src/Database.php';

// Парсим URL
$request_uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$request_method = $_SERVER['REQUEST_METHOD'];

// Удаляем базовый путь API
$base_path = '/api/v1';
$route = str_replace($base_path, '', $request_uri);
$route = ltrim($route, '/');

// Роутер
$routes = [
    'courses' => 'courses.php',
    'sections' => 'sections.php',
    'lessons' => 'lessons.php',
];

// Определяем какой файл запустить
$handled = false;
foreach ($routes as $pattern => $file) {
    if (strpos($route, $pattern) === 0) {
        require_once $file;
        $handled = true;
        break;
    }
}

// Если маршрут не найден
if (!$handled) {
    http_response_code(404);
    echo json_encode(['error' => 'Route not found']);
    exit;
}
