@echo off
REM ============================================
REM GitHub Pages Setup Script
REM ============================================
REM This script opens GitHub to enable Pages

echo.
echo ========================================
echo  MOI-KURSI: GitHub Pages Setup
echo ========================================
echo.

setlocal enabledelayedexpansion

set GITHUB_REPO=https://github.com/desyatovaelena11/moi-kursi
set SETTINGS_URL=%GITHUB_REPO%/settings/pages

echo Opening GitHub repository settings...
echo.
echo 📍 Откроется вкладка "Settings" → "Pages"
echo.
echo Что нужно сделать:
echo   1. Source: выбери "Deploy from a branch"
echo   2. Branch: "main"
echo   3. Folder: "/ (root)"
echo   4. Нажми "Save"
echo.
echo   ⏳ Подождём 1-2 минуты на распространение
echo   ✅ После этого откроется URL платформы
echo.

REM Open in default browser
start %SETTINGS_URL%

echo.
pause
