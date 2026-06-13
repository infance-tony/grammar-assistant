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
    venv\Scripts\pip.exe install fastapi uvicorn llama-cpp-python --quiet
    echo [SETUP] Done!
    echo.
)

cd /d %~dp0backend
..\venv\Scripts\python.exe main.py
pause
