<?php
/**
 * Database Class
 * Простой класс для работы с MySQL
 */

class Database {
    private $connection;
    private $stmt;

    public function __construct() {
        try {
            $this->connection = new mysqli(
                DB_HOST,
                DB_USER,
                DB_PASS,
                DB_NAME
            );

            // Проверка подключения
            if ($this->connection->connect_error) {
                throw new Exception('Ошибка подключения к БД: ' . $this->connection->connect_error);
            }

            // Установка кодировки
            $this->connection->set_charset(DB_CHARSET);
        } catch (Exception $e) {
            http_response_code(500);
            echo json_encode(['error' => $e->getMessage()]);
            exit;
        }
    }

    /**
     * Выполнить запрос SELECT
     */
    public function query($sql) {
        $this->stmt = $this->connection->query($sql);
        return $this;
    }

    /**
     * Получить все результаты
     */
    public function getAll() {
        if (!$this->stmt) return [];
        return $this->stmt->fetch_all(MYSQLI_ASSOC) ?? [];
    }

    /**
     * Получить один результат
     */
    public function getOne() {
        if (!$this->stmt) return null;
        return $this->stmt->fetch_assoc();
    }

    /**
     * Выполнить prepared statement (для INSERT/UPDATE/DELETE)
     */
    public function execute($sql, $params = []) {
        $this->stmt = $this->connection->prepare($sql);

        if (!$this->stmt) {
            throw new Exception('SQL Error: ' . $this->connection->error);
        }

        if (count($params) > 0) {
            // Определить типы параметров
            $types = '';
            foreach ($params as $param) {
                $types .= is_int($param) ? 'i' : 's';
            }
            $this->stmt->bind_param($types, ...$params);
        }

        if (!$this->stmt->execute()) {
            throw new Exception('Execute Error: ' . $this->stmt->error);
        }

        return $this->stmt->affected_rows;
    }

    /**
     * Получить ID последней вставленной записи
     */
    public function getLastId() {
        return $this->connection->insert_id;
    }

    /**
     * Закрыть соединение
     */
    public function close() {
        if ($this->stmt) $this->stmt->close();
        $this->connection->close();
    }
}
