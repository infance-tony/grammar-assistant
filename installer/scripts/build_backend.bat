@echo off
REM Build Grammar Assistant Backend into a standalone .exe using PyInstaller
REM Run from the repo root: installer\scripts\build_backend.bat

echo === Building Python Backend ===
cd backend

REM Activate venv
call venv\Scripts\activate.bat

REM Install pyinstaller inside the venv
pip install pyinstaller==6.6.0

REM Build single-file executable
pyinstaller ^
  --onefile ^
  --name grammar_backend ^
  --hidden-import=llama_cpp ^
  --hidden-import=uvicorn.logging ^
  --hidden-import=uvicorn.loops ^
  --hidden-import=uvicorn.loops.auto ^
  --hidden-import=uvicorn.protocols ^
  --hidden-import=uvicorn.protocols.http ^
  --hidden-import=uvicorn.protocols.http.auto ^
  --hidden-import=uvicorn.protocols.websockets ^
  --hidden-import=uvicorn.protocols.websockets.auto ^
  --hidden-import=uvicorn.lifespan ^
  --hidden-import=uvicorn.lifespan.on ^
  --add-data "prompts;prompts" ^
  main.py

echo === Backend build complete: backend\dist\grammar_backend.exe ===
cd ..
