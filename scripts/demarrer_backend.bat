@echo off
setlocal

cd /d "%~dp0\.."

set "PHP_EXE=C:\wamp64\bin\php\php8.4.15\php.exe"

if not exist "%PHP_EXE%" (
    echo PHP introuvable: %PHP_EXE%
    echo Verifie l'installation WAMP ou adapte PHP_EXE dans ce fichier.
    exit /b 1
)

echo Smart Faculty API
echo URL: http://127.0.0.1:8000
echo.
echo Garde cette fenetre ouverte pendant les tests Flutter.
echo Appuie sur Ctrl+C pour arreter le serveur.
echo.

"%PHP_EXE%" -S 127.0.0.1:8000 -t backend\public backend\public\index.php
