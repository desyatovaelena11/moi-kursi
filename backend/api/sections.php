<?php
/**
 * Sections API
 * GET /api/v1/sections/{id} - Получить раздел с уроками
 * POST /api/v1/sections - Создать раздел
 * PUT /api/v1/sections/{id} - Обновить раздел
 * DELETE /api/v1/sections/{id} - Удалить раздел
 */

$db = new Database();

$route_parts = explode('/', trim($route, '/'));
$section_id = $route_parts[1] ?? null;

try {
    switch ($request_method) {
        case 'GET':
            if ($section_id) {
                getSectionWithLessons($db, $section_id);
            } else {
                throw new Exception('Section ID required');
            }
            break;

        case 'POST':
            createSection($db);
            break;

        case 'PUT':
            if (!$section_id) {
                throw new Exception('Section ID required for update');
            }
            updateSection($db, $section_id);
            break;

        case 'DELETE':
            if (!$section_id) {
                throw new Exception('Section ID required for delete');
            }
            deleteSection($db, $section_id);
            break;

        default:
            throw new Exception('Method not allowed');
    }
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()]);
}

/**
 * Получить раздел с уроками
 */
function getSectionWithLessons($db, $section_id) {
    $sql = "SELECT id, course_id, name, description FROM sections WHERE id = $section_id";
    $section = $db->query($sql)->getOne();

    if (!$section) {
        throw new Exception('Section not found');
    }

    $sql = "SELECT id, section_id, name, description, video_url, duration FROM lessons WHERE section_id = $section_id ORDER BY `order` ASC";
    $section['lessons'] = $db->query($sql)->getAll();

    echo json_encode(['data' => $section]);
}

/**
 * Создать раздел
 */
function createSection($db) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['course_id']) || !isset($input['name'])) {
        throw new Exception('Course ID and name are required');
    }

    $course_id = $input['course_id'];
    $name = $input['name'];
    $description = $input['description'] ?? '';
    $order = $input['order'] ?? 0;

    $sql = "INSERT INTO sections (course_id, name, description, `order`) VALUES (?, ?, ?, ?)";
    $db->execute($sql, [$course_id, $name, $description, $order]);

    $section_id = $db->getLastId();
    echo json_encode(['success' => true, 'id' => $section_id, 'message' => 'Section created']);
}

/**
 * Обновить раздел
 */
function updateSection($db, $section_id) {
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
    if (isset($input['order'])) {
        $updates[] = "`order` = ?";
        $params[] = $input['order'];
    }

    if (empty($updates)) {
        throw new Exception('No fields to update');
    }

    $params[] = $section_id;
    $sql = "UPDATE sections SET " . implode(', ', $updates) . " WHERE id = ?";
    $db->execute($sql, $params);

    echo json_encode(['success' => true, 'message' => 'Section updated']);
}

/**
 * Удалить раздел и его уроки
 */
function deleteSection($db, $section_id) {
    $sql = "DELETE FROM lessons WHERE section_id = ?";
    $db->execute($sql, [$section_id]);

    $sql = "DELETE FROM sections WHERE id = ?";
    $db->execute($sql, [$section_id]);

    echo json_encode(['success' => true, 'message' => 'Section deleted']);
}
