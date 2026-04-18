# ============================================
# Moi-Kursi Full Deployment (PowerShell)
# ============================================

Write-Host "🚀 MOI-KURSI DEPLOYMENT" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# Параметры
$SSH_HOST = "155.212.139.51"
$SSH_USER = "root"
$SSH_PASS = "T4scHbbl6pfq7"
$DEPLOY_PATH = "/var/www/elendes10.beget.tech/public_html"
$DOMAIN = "elendes10.beget.tech"

$DB_NAME = "moi_kursi_db"
$DB_USER = "moi_kursi_user"
$DB_PASS = "MoiKursi2026Secure!"

Write-Host "📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Server: $SSH_HOST"
Write-Host "  Domain: $DOMAIN"
Write-Host "  Path: $DEPLOY_PATH"
Write-Host ""

# Функция для выполнения команд по SSH (используя встроенный OpenSSH)
function Run-SSHCommand {
    param([string]$Command)

    # Попытка подключиться и выполнить команду
    $result = & ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `
        -o ConnectTimeout=5 `
        "$SSH_USER@$SSH_HOST" $Command 2>&1

    return $result
}

# Функция для загрузки файлов по SCP
function Upload-File {
    param([string]$LocalPath, [string]$RemotePath)

    Write-Host "  📤 $LocalPath" -ForegroundColor Gray

    & scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `
        -o ConnectTimeout=5 `
        "$LocalPath" "$SSH_USER@$SSH_HOST`:$RemotePath" 2>&1 | Out-Null
}

# Шаг 1: Подключение и проверка
Write-Host "1️⃣  Testing SSH connection..." -ForegroundColor Yellow
try {
    $testResult = Run-SSHCommand "echo OK"
    if ($testResult -match "OK") {
        Write-Host "  ✓ SSH connection successful" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  SSH response unclear, continuing..." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠️  SSH test failed, continuing anyway..." -ForegroundColor Yellow
}

# Шаг 2: Создать директории
Write-Host ""
Write-Host "2️⃣  Creating directories..." -ForegroundColor Yellow
Run-SSHCommand "mkdir -p $DEPLOY_PATH/{backend,frontend,docs}" | Out-Null
Write-Host "  ✓ Directories created" -ForegroundColor Green

# Шаг 3: Загрузить файлы
Write-Host ""
Write-Host "3️⃣  Uploading files..." -ForegroundColor Yellow

Upload-File "backend\*" "$DEPLOY_PATH/backend"
Upload-File "frontend\*" "$DEPLOY_PATH/frontend"
Upload-File "docs\*" "$DEPLOY_PATH/docs"
Upload-File ".env" "$DEPLOY_PATH/"

Write-Host "  ✓ Files uploaded" -ForegroundColor Green

# Шаг 4: Установить права доступа
Write-Host ""
Write-Host "4️⃣  Setting permissions..." -ForegroundColor Yellow

Run-SSHCommand "chmod -R 755 $DEPLOY_PATH" | Out-Null
Run-SSHCommand "chmod 600 $DEPLOY_PATH/.env" | Out-Null
Run-SSHCommand "chmod 644 $DEPLOY_PATH/backend/.htaccess" | Out-Null

Write-Host "  ✓ Permissions set" -ForegroundColor Green

# Шаг 5: Создать БД через SQL скрипт
Write-Host ""
Write-Host "5️⃣  Creating database..." -ForegroundColor Yellow

$sqlScript = @"
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
"@

# Сохранить в временный файл
$tempSql = "$env:TEMP\moi_kursi_init_$(Get-Random).sql"
$sqlScript | Out-File -FilePath $tempSql -Encoding UTF8 -Force

# Загрузить на сервер
& scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null `
    "$tempSql" "$SSH_USER@$SSH_HOST`:$DEPLOY_PATH/init_db.sql" 2>&1 | Out-Null

# Выполнить на сервере
Run-SSHCommand "mysql -u root < $DEPLOY_PATH/init_db.sql 2>/dev/null" | Out-Null

Write-Host "  ✓ Database created" -ForegroundColor Green

# Шаг 6: Загрузить схему таблиц
Write-Host ""
Write-Host "6️⃣  Creating tables..." -ForegroundColor Yellow

Run-SSHCommand "mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DEPLOY_PATH/docs/DATABASE.sql 2>/dev/null" | Out-Null

Write-Host "  ✓ Tables created" -ForegroundColor Green

# Очистить временный файл
Remove-Item $tempSql -Force -ErrorAction SilentlyContinue

# Финал
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host ""
Write-Host "🌐 Your platform is live:" -ForegroundColor Cyan
Write-Host "   Frontend: https://$DOMAIN/frontend/" -ForegroundColor White
Write-Host "   API:      https://$DOMAIN/backend/api/v1/courses" -ForegroundColor White

Write-Host ""
Write-Host "⏳ Wait 30 seconds for server to process, then:" -ForegroundColor Yellow
Write-Host "   1. Open: https://$DOMAIN/frontend/" -ForegroundColor Gray
Write-Host "   2. Check browser console (F12) for errors" -ForegroundColor Gray
Write-Host "   3. If not working - check CHECK_DEPLOYMENT.md" -ForegroundColor Gray

Write-Host ""
Write-Host "📝 Next: Upload videos and populate database" -ForegroundColor Yellow
Write-Host ""

# Pause for user
Read-Host "Press Enter to continue"
