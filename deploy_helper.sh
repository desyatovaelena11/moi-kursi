#!/bin/bash
# ============================================
# Moi-Kursi Deployment for Helper
# Run this on the server via SSH
# ============================================

set -e

echo ""
echo "=========================================="
echo "📝 MOI-KURSI DEPLOYMENT HELPER SCRIPT"
echo "=========================================="
echo ""

# Configuration
SSH_HOST="155.212.139.51"
SSH_USER="root"
DOMAIN="globaldzih.store"
DEPLOY_PATH="/home/elendes10/public_html"
DB_NAME="moi_kursi_db"
DB_USER="moi_kursi_user"
DB_PASS="MoiKursi2026Secure!"

echo "ℹ️  This script should be run on the server after uploading files"
echo ""
echo "Required files in current directory:"
echo "  - backend/ (folder)"
echo "  - frontend/ (folder)"
echo "  - docs/ (folder)"
echo "  - .env (file)"
echo ""

# Step 1: Create directory structure
echo "Step 1️⃣ : Creating directory structure..."
mkdir -p $DEPLOY_PATH/{backend,frontend,docs}
echo "  ✓ Directories created"

# Step 2: Copy files
echo ""
echo "Step 2️⃣ : Copying files..."
cp -r backend/* $DEPLOY_PATH/backend/
cp -r frontend/* $DEPLOY_PATH/frontend/
cp -r docs/* $DEPLOY_PATH/docs/
cp .env $DEPLOY_PATH/
echo "  ✓ Files copied"

# Step 3: Set permissions
echo ""
echo "Step 3️⃣ : Setting permissions..."
chmod -R 755 $DEPLOY_PATH
chmod 600 $DEPLOY_PATH/.env
chmod 644 $DEPLOY_PATH/backend/.htaccess 2>/dev/null || true
echo "  ✓ Permissions set"

# Step 4: Create database
echo ""
echo "Step 4️⃣ : Creating database..."
mysql -u root << EOFDB
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOFDB
echo "  ✓ Database created"

# Step 5: Create tables
echo ""
echo "Step 5️⃣ : Creating tables..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DEPLOY_PATH/docs/DATABASE.sql
echo "  ✓ Tables created"

# Step 6: Verify installation
echo ""
echo "Step 6️⃣ : Verifying installation..."
if [ -f "$DEPLOY_PATH/frontend/index.html" ]; then
    echo "  ✓ Frontend files present"
else
    echo "  ✗ Frontend files NOT found"
fi

if [ -f "$DEPLOY_PATH/backend/api/index.php" ]; then
    echo "  ✓ Backend files present"
else
    echo "  ✗ Backend files NOT found"
fi

if [ -f "$DEPLOY_PATH/.env" ]; then
    echo "  ✓ Configuration file present"
else
    echo "  ✗ Configuration file NOT found"
fi

echo ""
echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Open in browser: https://$DOMAIN/frontend/"
echo "  2. API endpoint: https://$DOMAIN/backend/api/v1/courses"
echo ""
echo "Database credentials:"
echo "  Database: $DB_NAME"
echo "  User: $DB_USER"
echo "  Password: $DB_PASS"
echo ""
