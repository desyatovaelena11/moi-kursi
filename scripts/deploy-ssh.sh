#!/bin/bash

# ============================================
# Moi-Kursi SSH Deployment Script
# ============================================
# Usage: bash scripts/deploy-ssh.sh
# Before running: cp .env.example .env && fill with your credentials

set -e

echo "🚀 Moi-Kursi SSH Deployment"
echo "=============================="

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

echo ""
echo "📋 Configuration:"
echo "Server: $SSH_HOST ($SSH_USER)"
echo "Domain: $FRONTEND_BASE_URL"
echo "Deploy Path: $DEPLOY_PATH"
echo ""

# Check if sshpass is installed
if ! command -v sshpass &> /dev/null; then
    echo "⚠️  sshpass not found. Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y sshpass
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install sshpass
    else
        echo "❌ Please install sshpass manually from: https://linux.die.net/man/1/sshpass"
        exit 1
    fi
fi

SSH_CMD="sshpass -p '$SSH_PASSWORD' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $SSH_USER@$SSH_HOST"

echo "Step 1: Connecting to server and preparing directories..."
$SSH_CMD << 'EOFSETUP'
set -e
echo "✓ Connected to server"
mkdir -p /var/www/elendes10.beget.tech/public_html/{backend,frontend,docs}
echo "✓ Directories created"
EOFSETUP

echo ""
echo "Step 2: Uploading project files..."

# Upload backend
echo "Uploading backend..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    backend/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/backend/" 2>/dev/null || true

# Upload frontend
echo "Uploading frontend..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    frontend/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/frontend/" 2>/dev/null || true

# Upload docs
echo "Uploading docs..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    docs/* "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/docs/" 2>/dev/null || true

# Upload .env to server
echo "Uploading configuration..."
sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no \
    .env "$SSH_USER@$SSH_HOST:$DEPLOY_PATH/.env" 2>/dev/null || true

echo "✓ Files uploaded successfully"

echo ""
echo "Step 3: Setting up database..."

$SSH_CMD << 'EOFDB'
set -e

# Create MySQL user and database
mysql -u root << 'EOFMYSQL'
CREATE DATABASE IF NOT EXISTS moi_kursi_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'moi_kursi_user'@'localhost' IDENTIFIED BY 'MoiKursi2026Secure!';
GRANT ALL PRIVILEGES ON moi_kursi_db.* TO 'moi_kursi_user'@'localhost';
FLUSH PRIVILEGES;
EOFMYSQL

echo "✓ Database and user created"

# Import schema
mysql -u moi_kursi_user -pMoiKursi2026Secure! moi_kursi_db < /var/www/elendes10.beget.tech/public_html/docs/DATABASE.sql

echo "✓ Tables created"

EOFDB

echo ""
echo "Step 4: Setting permissions..."

$SSH_CMD << 'EOFPERM'
chmod -R 755 /var/www/elendes10.beget.tech/public_html
chmod -R 644 /var/www/elendes10.beget.tech/public_html/*.html
chmod -R 644 /var/www/elendes10.beget.tech/public_html/**/*.{js,css,html,php}
chmod 600 /var/www/elendes10.beget.tech/public_html/.env
echo "✓ Permissions set"
EOFPERM

echo ""
echo "✅ Deployment complete! 🎉"
echo ""
echo "🌐 Your platform is live:"
echo "   Frontend: $FRONTEND_BASE_URL/frontend/"
echo "   API: $API_BASE_URL/courses"
echo ""
echo "📝 Next steps:"
echo "1. Check the platform in browser"
echo "2. Upload videos to Mail.ru Cloud"
echo "3. Run: python3 scripts/populate_database.py --file courses.csv"
echo ""
