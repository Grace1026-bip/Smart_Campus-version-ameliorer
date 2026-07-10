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

echo Smart Faculty - API FastAPI
echo URL: http://127.0.0.1:8000
echo Documentation: http://127.0.0.1:8000/docs
echo.

".venv\Scripts\python.exe" -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
