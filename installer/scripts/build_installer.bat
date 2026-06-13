@echo off
title Grammar Assistant - Build Installer
echo ============================================
echo   Grammar Assistant Installer Builder
echo ============================================
echo.

cd /d %~dp0..\..

REM ── Step 1: PyInstaller Backend ──────────────────────
echo [1/3] Building Python backend with PyInstaller...
cd backend
..\venv\Scripts\pyinstaller.exe grammar_backend.spec --noconfirm --clean
if %ERRORLEVEL% neq 0 (
    echo ERROR: PyInstaller build failed!
    pause
    exit /b 1
)
echo [1/3] Backend build complete!
echo.

REM ── Step 2: Flutter Release Build ────────────────────
echo [2/3] Building Flutter Windows release...
cd ..\frontend
call flutter build windows --release
if %ERRORLEVEL% neq 0 (
    echo ERROR: Flutter build failed!
    pause
    exit /b 1
)
echo [2/3] Flutter build complete!
echo.

REM ── Step 3: Inno Setup Installer ────────────────────
echo [3/3] Creating installer with Inno Setup...
cd ..\installer\windows

REM Try common Inno Setup paths
set ISCC=
if exist "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" set ISCC="C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
if exist "C:\Program Files\Inno Setup 6\ISCC.exe" set ISCC="C:\Program Files\Inno Setup 6\ISCC.exe"

if "%ISCC%"=="" (
    echo ERROR: Inno Setup not found! Install it from https://jrsoftware.org/isdl.php
    pause
    exit /b 1
)

%ISCC% grammar_assistant.iss
if %ERRORLEVEL% neq 0 (
    echo ERROR: Inno Setup build failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo   BUILD COMPLETE!
echo   Installer: dist\GrammarAssistant_Setup_v1.0.0.exe
echo ============================================
echo.
cd ..\..
pause
