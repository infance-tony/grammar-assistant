@echo off
title Grammar Assistant - AI Backend
echo ============================================
echo   Grammar Assistant AI Backend
echo   Running on http://127.0.0.1:11434
echo ============================================
echo.

cd /d %~dp0

REM Check if venv exists, create it if not
if not exist "venv\Scripts\python.exe" (
    echo [SETUP] Virtual environment not found. Creating...
    python -m venv venv
    echo [SETUP] Installing dependencies...
    venv\Scripts\pip.exe install --upgrade pip --quiet
    venv\Scripts\pip.exe install fastapi==0.111.0 "uvicorn[standard]==0.29.0" pydantic==2.7.1 python-multipart==0.0.9 --quiet
    echo [SETUP] Installing llama-cpp-python (pre-built CPU wheel, no compiler needed)...
    venv\Scripts\pip.exe install llama-cpp-python==0.3.4 --extra-index-url https://abetlen.github.io/llama-cpp-python/whl/cpu --quiet
    echo [SETUP] Done!
    echo.
)

cd /d %~dp0backend
..\venv\Scripts\python.exe main.py
pause
