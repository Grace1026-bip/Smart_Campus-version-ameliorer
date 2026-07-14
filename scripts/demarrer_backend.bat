@echo off
setlocal EnableExtensions
title Smart Faculty - Backend FastAPI

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT="

if exist "%SCRIPT_DIR%backend\app\main.py" (
    set "PROJECT_ROOT=%SCRIPT_DIR%"
) else if exist "%SCRIPT_DIR%..\backend\app\main.py" (
    for %%I in ("%SCRIPT_DIR%..") do set "PROJECT_ROOT=%%~fI"
)

if not defined PROJECT_ROOT (
    echo [ERREUR] Impossible de localiser le projet Smart Faculty.
    echo Script : %~f0
    pause
    exit /b 1
)

set "BACKEND_DIR=%PROJECT_ROOT%\backend"
set "PYTHON_EXE=%BACKEND_DIR%\.venv\Scripts\python.exe"

if not exist "%BACKEND_DIR%\app\main.py" (
    echo [ERREUR] Point d'entree FastAPI introuvable.
    echo Chemin verifie : %BACKEND_DIR%\app\main.py
    pause
    exit /b 1
)

if not exist "%PYTHON_EXE%" (
    echo [ERREUR] Environnement Python introuvable.
    echo Chemin attendu : %PYTHON_EXE%
    echo Cree-le puis installe les dependances avec :
    echo python -m venv .venv
    echo .venv\Scripts\python.exe -m pip install -r requirements.txt
    pause
    exit /b 1
)

cd /d "%BACKEND_DIR%"
if errorlevel 1 (
    echo [ERREUR] Impossible d'ouvrir le dossier backend.
    echo Chemin verifie : %BACKEND_DIR%
    pause
    exit /b 1
)

netstat -ano | findstr /R /C:":8000 .*LISTENING" >nul
if not errorlevel 1 (
    echo [ERREUR] Le port 8000 est deja utilise.
    echo Aucun processus n'a ete arrete automatiquement.
    echo Etat du port :
    netstat -ano | findstr /R /C:":8000 .*LISTENING"
    echo Adresse existante : http://127.0.0.1:8000
    pause
    exit /b 2
)

echo ==============================================
echo SMART FACULTY - BACKEND FASTAPI
echo ==============================================
echo Backend : %BACKEND_DIR%
echo Python  : %PYTHON_EXE%
echo URL     : http://127.0.0.1:8000
echo Docs    : http://127.0.0.1:8000/docs
echo.
echo Appuyez sur Ctrl+C pour arreter le serveur.
echo.

"%PYTHON_EXE%" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo Le serveur s'est arrete avec le code %EXIT_CODE%.
pause
exit /b %EXIT_CODE%
