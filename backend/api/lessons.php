<?php
/**
 * Lessons API
 * GET /api/v1/lessons/{id} - Получить один урок
 * POST /api/v1/lessons - Создать урок
 * PUT /api/v1/lessons/{id} - Обновить урок
 * DELETE /api/v1/lessons/{id} - Удалить урок
 */

$db = new Database();

$route_parts = explode('/', trim($route, '/'));
$lesson_id = $route_parts[1] ?? null;

try {
    switch ($request_method) {
        case 'GET':
            if ($lesson_id) {
                getLesson($db, $lesson_id);
            } else {
                throw new Exception('Lesson ID required');
            }
            break;

        case 'POST':
            createLesson($db);
            break;

        case 'PUT':
            if (!$lesson_id) {
                throw new Exception('Lesson ID required for update');
            }
            updateLesson($db, $lesson_id);
            break;

        case 'DELETE':
            if (!$lesson_id) {
                throw new Exception('Lesson ID required for delete');
            }
            deleteLesson($db, $lesson_id);
            break;

        default:
            throw new Exception('Method not allowed');
    }
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()]);
}

/**
 * Получить один урок
 */
function getLesson($db, $lesson_id) {
    $sql = "SELECT id, section_id, name, description, video_url, duration FROM lessons WHERE id = $lesson_id";
    $lesson = $db->query($sql)->getOne();

    if (!$lesson) {
        throw new Exception('Lesson not found');
    }

    echo json_encode(['data' => $lesson]);
}

/**
 * Создать урок
 */
function createLesson($db) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['section_id']) || !isset($input['name']) || !isset($input['video_url'])) {
        throw new Exception('Section ID, name, and video_url are required');
    }

    $section_id = $input['section_id'];
    $name = $input['name'];
    $description = $input['description'] ?? '';
    $video_url = $input['video_url'];
    $duration = $input['duration'] ?? 0;
    $order = $input['order'] ?? 0;

    $sql = "INSERT INTO lessons (section_id, name, description, video_url, duration, `order`) VALUES (?, ?, ?, ?, ?, ?)";
    $db->execute($sql, [$section_id, $name, $description, $video_url, $duration, $order]);

    $lesson_id = $db->getLastId();
    echo json_encode(['success' => true, 'id' => $lesson_id, 'message' => 'Lesson created']);
}

/**
 * Обновить урок
 */
function updateLesson($db, $lesson_id) {
    $input = json_decode(file_get_contents('php://input'), true);

    $updates = [];
    $params = [];

    if (isset($input['name'])) {
        $updates[] = "name = ?";
        $params[] = $input['name'];
    }
    if (isset($input['description'])) {
        $updates[] = "description = ?";
        $params[] = $input['description'];
    }
    if (isset($input['video_url'])) {
        $updates[] = "video_url = ?";
        $params[] = $input['video_url'];
    }
    if (isset($input['duration'])) {
        $updates[] = "duration = ?";
        $params[] = $input['duration'];
    }
    if (isset($input['order'])) {
        $updates[] = "`order` = ?";
        $params[] = $input['order'];
    }

    if (empty($updates)) {
        throw new Exception('No fields to update');
    }

    $params[] = $lesson_id;
    $sql = "UPDATE lessons SET " . implode(', ', $updates) . " WHERE id = ?";
    $db->execute($sql, $params);

    echo json_encode(['success' => true, 'message' => 'Lesson updated']);
}

/**
 * Удалить урок
 */
function deleteLesson($db, $lesson_id) {
    $sql = "DELETE FROM lessons WHERE id = ?";
    $db->execute($sql, [$lesson_id]);

    echo json_encode(['success' => true, 'message' => 'Lesson deleted']);
}
