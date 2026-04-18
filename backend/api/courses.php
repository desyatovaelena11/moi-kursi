<?php
/**
 * Courses API
 * GET /api/v1/courses - Получить все курсы
 * GET /api/v1/courses/{id} - Получить один курс с разделами
 * POST /api/v1/courses - Создать курс
 * PUT /api/v1/courses/{id} - Обновить курс
 * DELETE /api/v1/courses/{id} - Удалить курс
 */

$db = new Database();

// Парсим URL для получения ID
$route_parts = explode('/', trim($route, '/'));
$action = $route_parts[0] ?? '';
$course_id = $route_parts[1] ?? null;

try {
    switch ($request_method) {
        case 'GET':
            if ($course_id) {
                // Получить один курс с разделами
                getCourseWithSections($db, $course_id);
            } else {
                // Получить все курсы
                getAllCourses($db);
            }
            break;

        case 'POST':
            // Создать новый курс
            createCourse($db);
            break;

        case 'PUT':
            // Обновить курс
            if (!$course_id) {
                throw new Exception('Course ID required for update');
            }
            updateCourse($db, $course_id);
            break;

        case 'DELETE':
            // Удалить курс
            if (!$course_id) {
                throw new Exception('Course ID required for delete');
            }
            deleteCourse($db, $course_id);
            break;

        default:
            throw new Exception('Method not allowed');
    }
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode(['error' => $e->getMessage()]);
}

/**
 * Получить все курсы
 */
function getAllCourses($db) {
    $sql = "SELECT id, name, description, created_at FROM courses ORDER BY `order` ASC";
    $courses = $db->query($sql)->getAll();
    echo json_encode(['data' => $courses, 'count' => count($courses)]);
}

/**
 * Получить один курс с разделами и уроками
 */
function getCourseWithSections($db, $course_id) {
    // Получить курс
    $sql = "SELECT id, name, description, created_at FROM courses WHERE id = ?";
    $db->execute($sql, [$course_id]);

    // На самом деле нужен query, а не execute для SELECT
    $sql = "SELECT id, name, description, created_at FROM courses WHERE id = $course_id";
    $course = $db->query($sql)->getOne();

    if (!$course) {
        throw new Exception('Course not found');
    }

    // Получить разделы
    $sql = "SELECT id, course_id, name, description FROM sections WHERE course_id = $course_id ORDER BY `order` ASC";
    $sections = $db->query($sql)->getAll();

    // Для каждого раздела получить уроки
    foreach ($sections as &$section) {
        $section_id = $section['id'];
        $sql = "SELECT id, section_id, name, description, video_url, duration FROM lessons WHERE section_id = $section_id ORDER BY `order` ASC";
        $section['lessons'] = $db->query($sql)->getAll();
    }

    $course['sections'] = $sections;
    echo json_encode(['data' => $course]);
}

/**
 * Создать новый курс
 */
function createCourse($db) {
    $input = json_decode(file_get_contents('php://input'), true);

    if (!isset($input['name'])) {
        throw new Exception('Course name is required');
    }

    $name = $input['name'];
    $description = $input['description'] ?? '';
    $order = $input['order'] ?? 0;

    $sql = "INSERT INTO courses (name, description, `order`, created_at) VALUES (?, ?, ?, NOW())";
    $db->execute($sql, [$name, $description, $order]);

    $course_id = $db->getLastId();
    echo json_encode(['success' => true, 'id' => $course_id, 'message' => 'Course created']);
}

/**
 * Обновить курс
 */
function updateCourse($db, $course_id) {
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

    $params[] = $course_id;
    $sql = "UPDATE courses SET " . implode(', ', $updates) . " WHERE id = ?";
    $db->execute($sql, $params);

    echo json_encode(['success' => true, 'message' => 'Course updated']);
}

/**
 * Удалить курс и все его разделы и уроки
 */
function deleteCourse($db, $course_id) {
    // Сначала удаляем все уроки
    $sql = "DELETE lessons FROM lessons
            INNER JOIN sections ON lessons.section_id = sections.id
            WHERE sections.course_id = ?";
    $db->execute($sql, [$course_id]);

    // Затем удаляем разделы
    $sql = "DELETE FROM sections WHERE course_id = ?";
    $db->execute($sql, [$course_id]);

    // Наконец удаляем курс
    $sql = "DELETE FROM courses WHERE id = ?";
    $db->execute($sql, [$course_id]);

    echo json_encode(['success' => true, 'message' => 'Course deleted']);
}
