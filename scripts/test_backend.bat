@echo off
setlocal

cd /d "%~dp0\..\backend"

if not exist ".venv\Scripts\python.exe" (
    echo Environnement Python introuvable: backend\.venv
    echo Cree-le puis installe les dependances avec:
    echo python -m venv .venv
    echo .venv\Scripts\python.exe -m pip install -r requirements.txt
    exit /b 1
)

echo Smart Faculty - Tests backend FastAPI
echo Base cible: smart_faculty_test
echo Protection attendue: le nom de la base doit finir par _test
echo.

set "APP_ENV=test"
set "MYSQL_DATABASE=smart_faculty_test"

".venv\Scripts\python.exe" -m pytest -v
