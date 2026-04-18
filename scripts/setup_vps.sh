#!/bin/bash
# ============================================
# Moi-Kursi VPS Setup Script
# Run this on the VPS server (155.212.139.51)
# ============================================

set -e

echo ""
echo "=========================================="
echo "🚀 MOI-KURSI VPS SETUP"
echo "=========================================="
echo ""

# Configuration
PROJECT_DIR="/opt/moi-kursi"
DB_NAME="moi_kursi_db"
DB_USER="moi_kursi_user"
DB_PASS="MoiKursi2026Secure!"
API_PORT="8000"

# Step 1: Create project directory
echo "Step 1: Creating project directory..."
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR
echo "  ✓ Directory created: $PROJECT_DIR"
echo ""

# Step 2: Check if files exist
echo "Step 2: Checking uploaded files..."
if [ ! -d "backend" ] || [ ! -f ".env" ] || [ ! -f "DATABASE.sql" ]; then
    echo "  ✗ ERROR: Files not found!"
    echo ""
    echo "  Please upload these files to $PROJECT_DIR:"
    echo "    - backend/ (folder)"
    echo "    - .env (file)"
    echo "    - docs/DATABASE.sql (file)"
    echo ""
    exit 1
fi
echo "  ✓ All files present"
echo ""

# Step 3: Create database
echo "Step 3: Creating database..."
mysql -u root << EOFDB
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOFDB
echo "  ✓ Database created"
echo ""

# Step 4: Import database schema
echo "Step 4: Importing database schema..."
mysql -u $DB_USER -p$DB_PASS $DB_NAME < docs/DATABASE.sql
echo "  ✓ Database schema imported"
echo ""

# Step 5: Set permissions
echo "Step 5: Setting file permissions..."
chmod -R 755 backend
chmod 600 .env
chown -R www-data:www-data backend 2>/dev/null || true
echo "  ✓ Permissions set"
echo ""

# Step 6: Setup Nginx config
echo "Step 6: Setting up Nginx..."
cat > /etc/nginx/sites-available/moi-kursi << 'EOFNGINX'
server {
    listen 8000;
    server_name _;

    root /opt/moi-kursi;
    index index.php;

    # API endpoints
    location /backend/api/ {
        try_files $uri $uri/ @api;
    }

    location @api {
        rewrite ^/backend/api/v1/(.*)$ /backend/api/index.php?request=$1 last;
    }

    # PHP processing
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Deny access to config and src
    location ~ /backend/(config|src)/ {
        deny all;
    }
}
EOFNGINX

ln -sf /etc/nginx/sites-available/moi-kursi /etc/nginx/sites-enabled/
nginx -t 2>&1 | grep -q "successful" && echo "  ✓ Nginx config valid" || echo "  ✗ Nginx config error"
systemctl restart nginx
echo "  ✓ Nginx restarted"
echo ""

# Step 7: Verify
echo "Step 7: Verifying installation..."
if mysql -u $DB_USER -p$DB_PASS $DB_NAME -e "SHOW TABLES;" | grep -q "courses"; then
    echo "  ✓ Database tables present"
else
    echo "  ✗ Warning: Database tables not found"
fi
echo ""

# Final message
echo "=========================================="
echo "✅ SETUP COMPLETE!"
echo "=========================================="
echo ""
echo "Your API is ready at:"
echo "  http://155.212.139.51.nip.io:8000/backend/api/v1/"
echo ""
echo "Test it:"
echo "  curl http://155.212.139.51.nip.io:8000/backend/api/v1/courses"
echo ""
echo "Next step: Enable GitHub Pages for frontend"
echo ""
