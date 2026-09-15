# -*- mode: python ; coding: utf-8 -*-
"""
PyInstaller spec for Grammar Assistant Backend.
Produces a one-directory bundle: dist/grammar_backend_python/
The main executable is dist/grammar_backend_python/grammar_backend.exe
"""

import os
import glob
from pathlib import Path

block_cipher = None
backend_dir = os.path.abspath('.')

# Find llama_cpp native libraries
venv_dir = os.path.join(os.path.dirname(backend_dir), 'venv')
llama_lib_dir = os.path.join(venv_dir, 'Lib', 'site-packages', 'llama_cpp', 'lib')
llama_binaries = []
if os.path.isdir(llama_lib_dir):
    for dll in glob.glob(os.path.join(llama_lib_dir, '*.dll')):
        # Place DLLs in llama_cpp/lib/ inside the bundle
        llama_binaries.append((dll, os.path.join('llama_cpp', 'lib')))

a = Analysis(
    ['main.py'],
    pathex=[backend_dir],
    binaries=llama_binaries,
    datas=[
        # Bundle prompt templates inside the exe
        ('prompts/grammar.txt', 'prompts'),
        ('prompts/rewrite_casual.txt', 'prompts'),
        ('prompts/rewrite_clear.txt', 'prompts'),
        ('prompts/rewrite_concise.txt', 'prompts'),
        ('prompts/professional.txt', 'prompts'),
        ('prompts/expand.txt', 'prompts'),
        ('prompts/shorten.txt', 'prompts'),
        ('prompts/explain.txt', 'prompts'),
        ('prompts/tone.txt', 'prompts'),
        ('prompts/email.txt', 'prompts'),
    ],
    hiddenimports=[
        'uvicorn.logging',
        'uvicorn.loops',
        'uvicorn.loops.auto',
        'uvicorn.protocols',
        'uvicorn.protocols.http',
        'uvicorn.protocols.http.auto',
        'uvicorn.protocols.http.h11_impl',
        'uvicorn.protocols.websockets',
        'uvicorn.protocols.websockets.auto',
        'uvicorn.lifespan',
        'uvicorn.lifespan.on',
        'uvicorn.lifespan.off',
        'llama_cpp',
        'numpy',
        'multiprocessing',
        'api',
        'api.grammar_service',
        'inference',
        'inference.model_loader',
        'inference.llama_wrapper',
        'inference.prompt_runner',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[
        'tkinter', '_tkinter', 'unittest', 'test',
        'xmlrpc', 'pydoc', 'doctest',
        'PIL', 'matplotlib', 'scipy', 'pandas',
    ],
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='grammar_backend',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=False,
    console=True,      # Console window for backend logging
    icon='..\\frontend\\assets\\icons\\app_icon.ico',
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=False,
    name='grammar_backend_python',
)
