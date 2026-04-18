#!/bin/bash

# ============================================
# Moi-Kursi Auto Deployment (Bash/Windows SSH)
# ============================================

set -e

echo "🚀 MOI-KURSI AUTO DEPLOYMENT"
echo "============================="

# Проверить .env
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Загрузить переменные
export $(grep -v '^#' .env | xargs)

echo ""
echo "📋 Configuration:"
echo "  Server: $SSH_HOST"
echo "  User: $SSH_USER"
echo "  Path: $DEPLOY_PATH"
echo ""

# Функция для выполнения SSH команд
ssh_cmd() {
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$SSH_HOST" "$@"
}

# Шаг 1: Создать директории
echo "1️⃣  Creating directories..."
ssh_cmd "mkdir -p $DEPLOY_PATH/{backend,frontend,docs}" || true
echo "  ✓ Done"

# Шаг 2: Загрузить файлы
echo ""
echo "2️⃣  Uploading files..."

echo "  📤 backend..."
scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    backend/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/backend/" 2>/dev/null || true

echo "  📤 frontend..."
scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    frontend/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/frontend/" 2>/dev/null || true

echo "  📤 docs..."
scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    docs/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/docs/" 2>/dev/null || true

echo "  📤 .env..."
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    .env "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/" 2>/dev/null || true

echo "  ✓ Files uploaded"

# Шаг 3: Создать БД
echo ""
echo "3️⃣  Creating database..."

SQL_COMMANDS="CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;"

echo "$SQL_COMMANDS" > /tmp/create_db.sql

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    /tmp/create_db.sql "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/" 2>/dev/null || true

ssh_cmd "mysql -u root < $DEPLOY_PATH/create_db.sql 2>/dev/null" || true

echo "  ✓ Database created"

# Шаг 4: Создать таблицы
echo ""
echo "4️⃣  Creating tables..."

ssh_cmd "mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DEPLOY_PATH/docs/DATABASE.sql" 2>/dev/null || true

echo "  ✓ Tables created"

# Шаг 5: Установить права
echo ""
echo "5️⃣  Setting permissions..."

ssh_cmd "chmod -R 755 $DEPLOY_PATH" || true
ssh_cmd "chmod 600 $DEPLOY_PATH/.env" || true
ssh_cmd "chmod 644 $DEPLOY_PATH/backend/.htaccess" || true

echo "  ✓ Permissions set"

# Очистить временный файл
rm -f /tmp/create_db.sql

echo ""
echo "=================================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=================================================="

echo ""
echo "🌐 Your platform is live:"
echo "   Frontend: ${FRONTEND_BASE_URL}/frontend/"
echo "   API:      ${API_BASE_URL}/courses"

echo ""
echo "📝 Next steps:"
echo "   1. Open browser: ${FRONTEND_BASE_URL}/frontend/"
echo "   2. Upload videos to Mail.ru Cloud"
echo "   3. Run: python3 scripts/populate_database.py --file scripts/courses_example.csv"

echo ""
