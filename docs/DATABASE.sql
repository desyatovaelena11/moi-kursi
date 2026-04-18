-- ============================================
-- Database Schema for Moi-kursi Platform
-- ============================================

-- Создать таблицу курсов
CREATE TABLE IF NOT EXISTS `courses` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `description` LONGTEXT,
  `order` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_order` (`order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Создать таблицу разделов
CREATE TABLE IF NOT EXISTS `sections` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `course_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` LONGTEXT,
  `order` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`course_id`) REFERENCES `courses`(`id`) ON DELETE CASCADE,
  INDEX `idx_course_id` (`course_id`),
  INDEX `idx_order` (`order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Создать таблицу уроков
CREATE TABLE IF NOT EXISTS `lessons` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `section_id` INT NOT NULL,
  `name` VARCHAR(255) NOT NULL,
  `description` LONGTEXT,
  `video_url` VARCHAR(500) NOT NULL COMMENT 'URL видео с Mail.ru Cloud',
  `duration` INT DEFAULT 0 COMMENT 'Длительность видео в секундах',
  `order` INT DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`section_id`) REFERENCES `sections`(`id`) ON DELETE CASCADE,
  INDEX `idx_section_id` (`section_id`),
  INDEX `idx_order` (`order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- Пример данных (для тестирования)
-- ============================================

-- Пример курса
INSERT INTO `courses` (`name`, `description`, `order`) VALUES
('Мой первый курс', 'Описание первого курса', 1),
('Второй курс', 'Описание второго курса', 2);

-- Пример разделов
INSERT INTO `sections` (`course_id`, `name`, `description`, `order`) VALUES
(1, 'Раздел 1', 'Первый раздел первого курса', 1),
(1, 'Раздел 2', 'Второй раздел первого курса', 2),
(2, 'Раздел 1', 'Первый раздел второго курса', 1);

-- Пример уроков (замени video_url на реальную ссылку)
INSERT INTO `lessons` (`section_id`, `name`, `description`, `video_url`, `duration`, `order`) VALUES
(1, 'Урок 1', 'Описание первого урока', 'https://cloud.mail.ru/public/example/video1.mp4', 600, 1),
(1, 'Урок 2', 'Описание второго урока', 'https://cloud.mail.ru/public/example/video2.mp4', 900, 2),
(2, 'Урок 1', 'Описание первого урока раздела 2', 'https://cloud.mail.ru/public/example/video3.mp4', 1200, 1),
(3, 'Урок 1', 'Описание урока второго курса', 'https://cloud.mail.ru/public/example/video4.mp4', 750, 1);
