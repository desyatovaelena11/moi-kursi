#!/bin/bash

# ============================================
# Moi-Kursi Deployment Script
# ============================================
# Usage: ./deploy.sh
# Before running:
# 1. Copy .env.example to .env
# 2. Fill .env with your credentials
# 3. Make sure you have FTP client installed (lftp or ftp)

set -e

echo "🚀 Moi-Kursi Deployment Script"
echo "=============================="

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found"
    echo "Please copy .env.example to .env and fill with your credentials"
    exit 1
fi

# Load environment variables
export $(cat .env | grep -v '#' | xargs)

echo ""
echo "📋 Configuration Summary:"
echo "Domain: $FTP_HOST"
echo "FTP User: $FTP_USER"
echo "Remote Path: $FTP_REMOTE_PATH"
echo "DB: $DB_NAME"

echo ""
echo "Step 1: Cleaning old files..."
rm -rf ./build || true
mkdir -p ./build

echo "Step 2: Copying files to build directory..."
cp -r backend build/
cp -r frontend build/
cp -r docs build/

echo "Step 3: Creating upload script..."
cat > ./upload_ftp.txt << EOF
#!/bin/bash
# Generated FTP commands

# Connect to FTP
open $FTP_HOST
user $FTP_USER $FTP_PASS

# Upload backend
cd $FTP_REMOTE_PATH
mkdir -p backend
lcd build/backend
cd backend
mput -R *
cd ..

# Upload frontend
mkdir -p frontend
lcd ../build/frontend
cd frontend
mput -R *
cd ..

# Upload docs
mkdir -p docs
lcd ../build/docs
cd docs
mput -R *

quit
EOF

echo "Step 4: Uploading files to FTP..."

if command -v lftp &> /dev/null; then
    echo "Using lftp..."
    lftp -f ./upload_ftp.txt
elif command -v ftp &> /dev/null; then
    echo "Using standard ftp client..."
    ftp -i < ./upload_ftp.txt
else
    echo "⚠️  Neither lftp nor ftp found"
    echo "Please upload files manually from ./build directory to your FTP"
    echo ""
    echo "Recommended tool: FileZilla (https://filezilla-project.org/)"
    exit 0
fi

echo ""
echo "✅ Deployment complete!"
echo ""
echo "Next steps:"
echo "1. Visit: https://$FTP_HOST/backend/install.php"
echo "2. Follow installation wizard"
echo "3. Access your platform at: https://$FTP_HOST"
echo ""
echo "Frontend URL: https://$FTP_HOST/frontend/"
echo "API URL: https://$FTP_HOST/backend/api/v1/courses"

# Cleanup
rm -f ./upload_ftp.txt
rm -rf ./build
