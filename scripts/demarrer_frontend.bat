@echo off
setlocal

cd /d "%~dp0\..\frontend"

where flutter >nul 2>nul
if errorlevel 1 (
    echo Flutter introuvable dans le PATH.
    echo Installe Flutter ou ajoute le dossier flutter\bin au PATH avant de relancer ce script.
    exit /b 1
)

echo Smart Faculty - Frontend Flutter
echo URL: http://localhost:3000
echo Backend attendu: http://127.0.0.1:8000/api/v1
echo.

flutter run -d chrome --web-port 3000
