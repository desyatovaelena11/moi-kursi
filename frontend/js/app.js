/**
 * Moi-Kursi Application
 * Frontend JavaScript Logic
 */

// ============================================
// Configuration
// ============================================

const API_BASE = '/api/v1';  // Замени на URL своего Beget хостинга

// ============================================
// State Management
// ============================================

const state = {
    courses: [],
    currentCourse: null,
    currentSection: null,
    currentLesson: null,
    allCoursesData: {},
    searchQuery: ''
};

// ============================================
// DOM Elements
// ============================================

const elements = {
    coursesList: document.getElementById('coursesList'),
    searchInput: document.getElementById('searchInput'),
    clearSearchBtn: document.getElementById('clearSearchBtn'),
    courseInfo: document.getElementById('courseInfo'),
    videoViewer: document.getElementById('videoViewer'),
    noCourseSelected: document.getElementById('noCourseSelected'),
    loadingIndicator: document.getElementById('loadingIndicator'),
    courseTitle: document.getElementById('courseTitle'),
    courseDescription: document.getElementById('courseDescription'),
    sectionsContainer: document.getElementById('sectionsContainer'),
    videoPlayer: document.getElementById('videoPlayer'),
    videoSource: document.getElementById('videoSource'),
    lessonTitle: document.getElementById('lessonTitle'),
    lessonDescription: document.getElementById('lessonDescription'),
    lessonBreadcrumb: document.getElementById('lessonBreadcrumb'),
    backToSectionBtn: document.getElementById('backToSectionBtn'),
    breadcrumb: document.getElementById('breadcrumb')
};

// ============================================
// API Functions
// ============================================

async function fetchCourses() {
    try {
        elements.loadingIndicator.style.display = 'block';
        const response = await fetch(`${API_BASE}/courses`);
        const data = await response.json();
        state.courses = data.data || [];
        elements.loadingIndicator.style.display = 'none';
        return state.courses;
    } catch (error) {
        console.error('Error fetching courses:', error);
        elements.coursesList.innerHTML = '<div class="error">Ошибка загрузки курсов</div>';
        elements.loadingIndicator.style.display = 'none';
        return [];
    }
}

async function fetchCourseWithSections(courseId) {
    try {
        elements.loadingIndicator.style.display = 'block';
        const response = await fetch(`${API_BASE}/courses/${courseId}`);
        const data = await response.json();
        elements.loadingIndicator.style.display = 'none';
        return data.data;
    } catch (error) {
        console.error('Error fetching course:', error);
        elements.loadingIndicator.style.display = 'none';
        return null;
    }
}

// ============================================
// Rendering Functions
// ============================================

function renderCoursesList(courses = state.courses) {
    if (courses.length === 0) {
        elements.coursesList.innerHTML = '<div class="empty-state">Курсы не найдены</div>';
        return;
    }

    elements.coursesList.innerHTML = courses
        .map(course => `
            <div class="course-item ${state.currentCourse?.id === course.id ? 'active' : ''}"
                 data-course-id="${course.id}">
                <span class="course-item-name">${escapeHtml(course.name)}</span>
                <span class="course-item-count">${state.allCoursesData[course.id]?.sections?.length || 0} разделов</span>
            </div>
        `)
        .join('');

    // Добавляем обработчики событий
    document.querySelectorAll('.course-item').forEach(item => {
        item.addEventListener('click', async () => {
            const courseId = parseInt(item.dataset.courseId);
            await selectCourse(courseId);
        });
    });
}

function renderCourseContent(course) {
    elements.courseTitle.textContent = course.name;
    elements.courseDescription.textContent = course.description || 'Нет описания';

    // Отрисовка разделов
    if (course.sections && course.sections.length > 0) {
        elements.sectionsContainer.innerHTML = course.sections
            .map((section, index) => `
                <div class="section" data-section-id="${section.id}">
                    <div class="section-header" data-toggle="section">
                        <span class="section-name">${escapeHtml(section.name)}</span>
                        <span class="section-toggle">▶</span>
                    </div>
                    <div class="lessons-list" style="display: none;">
                        ${section.lessons.map((lesson, lessonIndex) => `
                            <div class="lesson-item" data-lesson-id="${lesson.id}">
                                <span class="lesson-name">${escapeHtml(lesson.name)}</span>
                                <span class="lesson-duration">${formatDuration(lesson.duration)}</span>
                            </div>
                        `).join('')}
                    </div>
                </div>
            `)
            .join('');

        // Обработчики для разделов
        document.querySelectorAll('.section-header').forEach(header => {
            header.addEventListener('click', function() {
                const section = this.parentElement;
                const lessonsList = section.querySelector('.lessons-list');
                const isHidden = lessonsList.style.display === 'none';

                section.classList.toggle('collapsed', isHidden);
                lessonsList.style.display = isHidden ? 'flex' : 'none';
            });
        });

        // Обработчики для уроков
        document.querySelectorAll('.lesson-item').forEach(item => {
            item.addEventListener('click', async () => {
                const lessonId = parseInt(item.dataset.lessonId);
                const sectionId = item.closest('.section').dataset.sectionId;
                const section = course.sections.find(s => s.id == sectionId);
                const lesson = section.lessons.find(l => l.id == lessonId);

                if (lesson) {
                    selectLesson(course, section, lesson);
                }
            });
        });
    }
}

function renderVideoViewer(course, section, lesson) {
    elements.lessonTitle.textContent = lesson.name;
    elements.lessonDescription.textContent = lesson.description || 'Нет описания';
    elements.videoSource.src = lesson.video_url;
    elements.videoPlayer.load();

    // Обновляем breadcrumb
    elements.lessonBreadcrumb.innerHTML = `
        <span class="breadcrumb-item" data-breadcrumb-course="${course.id}">${escapeHtml(course.name)}</span>
        <span class="breadcrumb-separator">/</span>
        <span class="breadcrumb-item" data-breadcrumb-section="${section.id}">${escapeHtml(section.name)}</span>
        <span class="breadcrumb-separator">/</span>
        <span>${escapeHtml(lesson.name)}</span>
    `;

    // Обработчик назад
    elements.backToSectionBtn.onclick = () => {
        showCourseContent();
    };
}

// ============================================
// Navigation Functions
// ============================================

async function selectCourse(courseId) {
    elements.loadingIndicator.style.display = 'block';

    // Получаем данные если ещё не загружали
    if (!state.allCoursesData[courseId]) {
        const courseData = await fetchCourseWithSections(courseId);
        if (courseData) {
            state.allCoursesData[courseId] = courseData;
        }
    }

    state.currentCourse = state.allCoursesData[courseId];
    state.currentSection = null;
    state.currentLesson = null;

    renderCoursesList();
    showCourseContent();
    elements.loadingIndicator.style.display = 'none';
}

function selectLesson(course, section, lesson) {
    state.currentCourse = course;
    state.currentSection = section;
    state.currentLesson = lesson;

    showVideoViewer();
}

function showCourseContent() {
    elements.noCourseSelected.style.display = 'none';
    elements.videoViewer.style.display = 'none';
    elements.courseInfo.style.display = 'block';

    if (state.currentCourse) {
        renderCourseContent(state.currentCourse);
    }
}

function showVideoViewer() {
    if (state.currentCourse && state.currentSection && state.currentLesson) {
        elements.noCourseSelected.style.display = 'none';
        elements.courseInfo.style.display = 'none';
        elements.videoViewer.style.display = 'block';

        renderVideoViewer(state.currentCourse, state.currentSection, state.currentLesson);
    }
}

// ============================================
// Search & Filter
// ============================================

function filterCourses(query) {
    if (!query) {
        renderCoursesList(state.courses);
        elements.clearSearchBtn.style.display = 'none';
        return;
    }

    elements.clearSearchBtn.style.display = 'block';
    const q = query.toLowerCase();

    const filtered = state.courses.filter(course => {
        if (course.name.toLowerCase().includes(q) ||
            course.description?.toLowerCase().includes(q)) {
            return true;
        }

        // Проверяем разделы и уроки
        const courseData = state.allCoursesData[course.id];
        if (courseData?.sections) {
            return courseData.sections.some(section =>
                section.name.toLowerCase().includes(q) ||
                section.lessons?.some(lesson =>
                    lesson.name.toLowerCase().includes(q)
                )
            );
        }

        return false;
    });

    renderCoursesList(filtered);
}

// ============================================
// Utility Functions
// ============================================

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

function formatDuration(seconds) {
    if (!seconds) return '';
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
}

// ============================================
// Event Listeners
// ============================================

elements.searchInput.addEventListener('input', (e) => {
    state.searchQuery = e.target.value;
    filterCourses(state.searchQuery);
});

elements.clearSearchBtn.addEventListener('click', () => {
    elements.searchInput.value = '';
    state.searchQuery = '';
    filterCourses('');
});

// ============================================
// Initialization
// ============================================

async function init() {
    console.log('Инициализация Moi-Kursi...');

    const courses = await fetchCourses();
    renderCoursesList(courses);

    console.log('✓ Приложение загружено');
}

// Запуск при загрузке страницы
document.addEventListener('DOMContentLoaded', init);
