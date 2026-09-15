@echo off
title Grammar Assistant
echo ============================================
echo   Grammar Assistant - Starting...
echo ============================================
echo.

REM Kill any existing backend on port 11434
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :11434 ^| findstr LISTENING') do (
    echo Stopping previous backend (PID %%a)...
    taskkill /F /PID %%a >nul 2>&1
)

REM Start the AI backend in a new window
echo [1/2] Starting AI backend...
start "Grammar Assistant - AI Backend" /MIN cmd /c "cd /d %~dp0backend && venv\Scripts\activate && python main.py"

REM Wait for backend to be ready
echo [2/2] Waiting for AI model to load...
:wait_loop
timeout /t 2 /nobreak >nul
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://127.0.0.1:11434/health' -UseBasicParsing -TimeoutSec 2; if (($r.Content | ConvertFrom-Json).status -eq 'ready') { exit 0 } } catch { exit 1 }" >nul 2>&1
if errorlevel 1 goto wait_loop

echo Backend ready!

REM Launch Flutter app — try puro-managed Flutter first, then fall back to PATH
set FLUTTER=%USERPROFILE%\.puro\envs\stable\flutter\bin\flutter.bat
if not exist "%FLUTTER%" (
    for /f "delims=" %%i in ('where flutter 2^>nul') do (set FLUTTER=%%i & goto :found_flutter)
    echo ERROR: flutter not found in puro or PATH.
    echo Install Flutter: https://flutter.dev  or puro: https://puro.dev
    pause
    exit /b 1
)
:found_flutter

echo Launching app window...
cd /d %~dp0frontend
"%FLUTTER%" run -d windows

echo.
echo App closed. Stopping backend...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :11434 ^| findstr LISTENING') do taskkill /F /PID %%a >nul 2>&1
