#!/bin/bash

# ============================================
# Moi-Kursi Upload Files via SCP
# ============================================

set -e

echo "📤 Uploading files to server..."

# Load env
export $(cat .env | grep -v '^#' | xargs)

# Check sshpass
if ! command -v sshpass &> /dev/null; then
    echo "Installing sshpass..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo apt-get install -y sshpass > /dev/null 2>&1
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install sshpass > /dev/null 2>&1
    fi
fi

SSH="$SSH_USER@$SSH_HOST:$DEPLOY_PATH"

echo "Server: $SSH_HOST"
echo "Path: $DEPLOY_PATH"
echo ""

# Create directories on server
echo "1️⃣  Creating directories..."
sshpass -p "$SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" \
    "mkdir -p $DEPLOY_PATH/{backend,frontend,docs}" 2>/dev/null

# Upload files
echo "2️⃣  Uploading backend..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    backend/* "$SSH:backend/" 2>/dev/null || echo "⚠️  Warning: some backend files may have failed"

echo "3️⃣  Uploading frontend..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    frontend/* "$SSH:frontend/" 2>/dev/null || echo "⚠️  Warning: some frontend files may have failed"

echo "4️⃣  Uploading docs..."
sshpass -p "$SSH_PASSWORD" scp -r -o StrictHostKeyChecking=no \
    docs/* "$SSH:docs/" 2>/dev/null || echo "⚠️  Warning: some docs files may have failed"

echo "5️⃣  Uploading .env..."
sshpass -p "$SSH_PASSWORD" scp -o StrictHostKeyChecking=no \
    .env "$SSH:/" 2>/dev/null || true

echo ""
echo "✅ Files uploaded!"
echo ""
echo "📋 Next step:"
echo "   Open in browser: https://elendes10.beget.tech/backend/install.php"
echo "   Follow the installation steps"
echo ""
