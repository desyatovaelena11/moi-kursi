# ============================================
# Moi-Kursi Auto Deployment (PowerShell)
# ============================================

# Загрузить .env
$envFile = ".env"
if (-not (Test-Path $envFile)) {
    Write-Host "❌ Error: .env file not found" -ForegroundColor Red
    exit 1
}

# Парсить .env
$env_vars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if (-not $key.StartsWith('#')) {
            $env_vars[$key] = $value
        }
    }
}

$SSH_HOST = $env_vars['SSH_HOST']
$SSH_USER = $env_vars['SSH_USER']
$SSH_PASSWORD = $env_vars['SSH_PASSWORD']
$DEPLOY_PATH = $env_vars['DEPLOY_PATH']
$DB_NAME = $env_vars['DB_NAME']
$DB_USER = $env_vars['DB_USER']
$DB_PASS = $env_vars['DB_PASS']
$FRONTEND_BASE_URL = $env_vars['FRONTEND_BASE_URL']
$API_BASE_URL = $env_vars['API_BASE_URL']

Write-Host "🚀 MOI-KURSI AUTO DEPLOYMENT (PowerShell)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`n📋 Configuration:" -ForegroundColor Yellow
Write-Host "  Server: $SSH_HOST"
Write-Host "  User: $SSH_USER"
Write-Host "  Path: $DEPLOY_PATH"
Write-Host "  Database: $DB_NAME"
Write-Host ""

# Функция для выполнения SSH команд
function Invoke-SSHCommand {
    param([string]$Command)

    # Используем встроенный Windows SSH
    $output = ssh -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" $Command 2>&1
    return $output
}

# Функция для загрузки файлов по SCP
function Upload-Files {
    param([string]$LocalPath, [string]$RemotePath)

    Write-Host "  📤 $LocalPath -> $RemotePath" -ForegroundColor Gray

    # Используем встроенный Windows SCP
    scp -r -o StrictHostKeyChecking=no "$LocalPath" "$SSH_USER@$SSH_HOST`:$RemotePath" 2>&1 | Out-Null
}

# Шаг 1: Создать директории
Write-Host "`n1️⃣  Creating directories on server..." -ForegroundColor Yellow
Invoke-SSHCommand "mkdir -p $DEPLOY_PATH/{backend,frontend,docs}" | Out-Null
Write-Host "  ✓ Directories created" -ForegroundColor Green

# Шаг 2: Загрузить файлы
Write-Host "`n2️⃣  Uploading files..." -ForegroundColor Yellow
Upload-Files "backend/*" "$DEPLOY_PATH/backend"
Upload-Files "frontend/*" "$DEPLOY_PATH/frontend"
Upload-Files "docs/*" "$DEPLOY_PATH/docs"
Upload-Files ".env" "$DEPLOY_PATH/"
Write-Host "  ✓ Files uploaded" -ForegroundColor Green

# Шаг 3: Создать БД
Write-Host "`n3️⃣  Creating database..." -ForegroundColor Yellow

$sqlCommands = @"
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
"@

# Сохранить SQL в временный файл
$tempSql = "$env:TEMP\create_db_$([DateTime]::Now.Ticks).sql"
$sqlCommands | Out-File -FilePath $tempSql -Encoding UTF8

# Загрузить на сервер
scp -o StrictHostKeyChecking=no $tempSql "$SSH_USER@$SSH_HOST`:$DEPLOY_PATH/create_db.sql" 2>&1 | Out-Null

# Выполнить на сервере
Invoke-SSHCommand "mysql -u root < $DEPLOY_PATH/create_db.sql" | Out-Null
Write-Host "  ✓ Database created" -ForegroundColor Green

# Шаг 4: Загрузить схему таблиц
Write-Host "`n4️⃣  Creating tables..." -ForegroundColor Yellow
Invoke-SSHCommand "mysql -u $DB_USER -p$DB_PASS $DB_NAME < $DEPLOY_PATH/docs/DATABASE.sql" | Out-Null
Write-Host "  ✓ Tables created" -ForegroundColor Green

# Шаг 5: Установить права
Write-Host "`n5️⃣  Setting permissions..." -ForegroundColor Yellow
Invoke-SSHCommand "chmod -R 755 $DEPLOY_PATH" | Out-Null
Invoke-SSHCommand "chmod 600 $DEPLOY_PATH/.env" | Out-Null
Write-Host "  ✓ Permissions set" -ForegroundColor Green

# Очистить временный файл
Remove-Item $tempSql -Force -ErrorAction SilentlyContinue

Write-Host "`n" + "=" * 50 -ForegroundColor Green
Write-Host "✅ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

Write-Host "`n🌐 Your platform is live:" -ForegroundColor Cyan
Write-Host "   Frontend: $FRONTEND_BASE_URL/frontend/" -ForegroundColor White
Write-Host "   API:      $API_BASE_URL/courses" -ForegroundColor White

Write-Host "`n📝 Next steps:" -ForegroundColor Yellow
Write-Host "   1. Open in browser: $FRONTEND_BASE_URL/frontend/" -ForegroundColor Gray
Write-Host "   2. Upload videos to Mail.ru Cloud" -ForegroundColor Gray
Write-Host "   3. Run: python3 scripts/populate_database.py --file courses_example.csv" -ForegroundColor Gray

Write-Host ""
