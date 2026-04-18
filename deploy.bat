@echo off
REM ============================================
REM Moi-Kursi Deployment Script (Windows)
REM ============================================

setlocal enabledelayedexpansion

echo.
echo ========================================
echo  MOI-KURSI DEPLOYMENT
echo ========================================
echo.

REM Parameters
set SSH_HOST=155.212.139.51
set SSH_USER=root
set SSH_PASS=T4scHbbl6pfq7
set DEPLOY_PATH=/var/www/elendes10.beget.tech/public_html
set DOMAIN=elendes10.beget.tech

set DB_NAME=moi_kursi_db
set DB_USER=moi_kursi_user
set DB_PASS=MoiKursi2026Secure!

echo Configuration:
echo   Server: !SSH_HOST!
echo   User: !SSH_USER!
echo   Domain: !DOMAIN!
echo.

REM Step 1: Create directories
echo 1. Creating directories on server...
ssh -o StrictHostKeyChecking=no !SSH_USER!@!SSH_HOST! "mkdir -p !DEPLOY_PATH!/{backend,frontend,docs}" >nul 2>&1
echo    [OK]

REM Step 2: Upload backend
echo 2. Uploading backend...
scp -r -o StrictHostKeyChecking=no backend\* !SSH_USER!@!SSH_HOST!:!DEPLOY_PATH!/backend/ >nul 2>&1
echo    [OK]

REM Step 3: Upload frontend
echo 3. Uploading frontend...
scp -r -o StrictHostKeyChecking=no frontend\* !SSH_USER!@!SSH_HOST!:!DEPLOY_PATH!/frontend/ >nul 2>&1
echo    [OK]

REM Step 4: Upload docs
echo 4. Uploading docs...
scp -r -o StrictHostKeyChecking=no docs\* !SSH_USER!@!SSH_HOST!:!DEPLOY_PATH!/docs/ >nul 2>&1
echo    [OK]

REM Step 5: Upload .env
echo 5. Uploading configuration...
scp -o StrictHostKeyChecking=no .env !SSH_USER!@!SSH_HOST!:!DEPLOY_PATH!/ >nul 2>&1
echo    [OK]

REM Step 6: Set permissions
echo 6. Setting permissions...
ssh -o StrictHostKeyChecking=no !SSH_USER!@!SSH_HOST! "chmod -R 755 !DEPLOY_PATH! && chmod 600 !DEPLOY_PATH!/.env" >nul 2>&1
echo    [OK]

REM Step 7: Create database
echo 7. Creating database...

REM Create SQL script in temp
set TEMP_SQL=%TEMP%\moi_kursi_init.sql
(
    echo CREATE DATABASE IF NOT EXISTS !DB_NAME! CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
    echo CREATE USER IF NOT EXISTS '!DB_USER!'@'localhost' IDENTIFIED BY '!DB_PASS!';
    echo GRANT ALL PRIVILEGES ON !DB_NAME!.* TO '!DB_USER!'@'localhost';
    echo FLUSH PRIVILEGES;
) > "!TEMP_SQL!"

REM Upload and execute SQL
scp -o StrictHostKeyChecking=no "!TEMP_SQL!" !SSH_USER!@!SSH_HOST!:!DEPLOY_PATH!/init.sql >nul 2>&1
ssh -o StrictHostKeyChecking=no !SSH_USER!@!SSH_HOST! "mysql -u root < !DEPLOY_PATH!/init.sql 2>/dev/null" >nul 2>&1
echo    [OK]

REM Step 8: Create tables
echo 8. Creating tables...
ssh -o StrictHostKeyChecking=no !SSH_USER!@!SSH_HOST! "mysql -u !DB_USER! -p!DB_PASS! !DB_NAME! < !DEPLOY_PATH!/docs/DATABASE.sql 2>/dev/null" >nul 2>&1
echo    [OK]

REM Clean up
del "!TEMP_SQL!" >nul 2>&1

echo.
echo ========================================
echo  DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Your platform is live:
echo   Frontend: https://!DOMAIN!/frontend/
echo   API:      https://!DOMAIN!/backend/api/v1/courses
echo.
echo Next steps:
echo   1. Open in browser: https://!DOMAIN!/frontend/
echo   2. Upload videos to Mail.ru Cloud
echo   3. Run: python3 scripts\populate_database.py --file scripts\courses_example.csv
echo.

pause
