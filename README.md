<div align="center">

# ✍️ Grammar Assistant

**A modern, offline-first desktop application for grammar correction and text enhancement.**

Built with Flutter • Powered by local AI • No internet required

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078D6?logo=windows)](https://www.microsoft.com/windows)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.12-3776AB?logo=python)](https://python.org)

</div>

---

## 💡 Why Grammar Assistant?

Most grammar tools require an internet connection and send your text to cloud servers. **Grammar Assistant** is different:

- **100% Offline** — Your text never leaves your computer.
- **No Accounts** — No sign-ups, no subscriptions, no tracking.
- **Fast** — Local AI inference with sub-second response times.
- **Free & Open Source** — MIT licensed, customize it however you want.

It's like having Grammarly on your desktop — without the cloud.

---

## 🚀 Features

| Feature | Description |
|---|---|
| ✏️ **Fix Grammar** | Corrects grammar, spelling, and punctuation errors |
| 🔄 **Rewrite** | Rewrites text in Casual, Clear, or Concise styles |
| 💼 **Professional** | Converts informal text into business language |
| 📖 **Expand** | Expands short text into detailed paragraphs |
| ✂️ **Shorten** | Condenses long text while preserving meaning |
| 🌗 **Dark / Light Mode** | Beautiful themed interface with smooth animations |
| 🔒 **100% Offline** | No cloud APIs, no accounts, no internet needed |

---

## 🏗️ Architecture

```
grammar-assistant
│
├── Frontend (Flutter Desktop)
│   ├── Material 3 Design
│   ├── Custom dark & light themes
│   ├── Smooth micro-animations
│   └── System tray support
│
├── Backend (Python FastAPI)
│   ├── uvicorn server (port 11434)
│   ├── REST API endpoints
│   └── Prompt template engine
│
└── AI Engine (llama.cpp)
    ├── Qwen2.5-0.5B-Instruct (Q4_K_M)
    ├── ~380 MB model file
    ├── CPU-only inference (8 threads)
    └── 1024 token context window
```

**Communication flow:**

```
Flutter UI  ──HTTP──▶  FastAPI  ──▶  llama.cpp  ──▶  Qwen2.5 Model
   :11434         /api/process         GGUF          ~500ms response
```

---

## 📦 Installation

### Option 1: Windows Installer (Recommended)

1. Download **`GrammarAssistant_Setup_v1.0.0.exe`** (~408 MB)
2. Run the installer — follow the wizard
3. Launch from Start Menu or Desktop shortcut
4. **Done!** Everything is bundled. No Python, no Flutter, no setup needed.

> The installer includes: Flutter app + Embedded Python 3.12 + AI model — all in one.

### Option 2: Build from Source

#### Prerequisites

| Tool | Version | Link |
|---|---|---|
| Flutter SDK | 3.x+ | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Python | 3.12+ | [python.org](https://python.org/downloads/) |
| Windows | 10/11 (x64) | — |

#### Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/your-username/grammar-assistant.git
cd grammar-assistant

# 2. Set up Python backend
python -m venv venv
venv\Scripts\activate
pip install -r backend\requirements.txt

# 3. Download the AI model (~380 MB)
#    Download Qwen2.5-0.5B-Instruct-Q4_K_M.gguf
#    Save it as: backend\models\qwen.gguf

# 4. Start the backend
python backend\main.py

# 5. In a new terminal — run the Flutter app
cd frontend
flutter pub get
flutter run -d windows
```

#### One-Click Launch (after setup)

```bash
# Starts both backend and frontend
run.bat

# Or backend only
run_backend_only.bat
```

---

## 📁 Project Structure

```
grammar-assistant/
│
├── frontend/                   # Flutter desktop application
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── app.dart            # MaterialApp configuration
│   │   ├── models/             # Data models
│   │   ├── screens/            # Home, Settings screens
│   │   ├── services/           # Backend service & launcher
│   │   ├── theme/              # Color palette (dark/light)
│   │   └── widgets/            # Reusable UI components
│   ├── assets/icons/           # App icons
│   └── pubspec.yaml            # Flutter dependencies
│
├── backend/                    # Python AI service
│   ├── api/
│   │   └── grammar_service.py  # FastAPI route handlers
│   ├── inference/
│   │   ├── model_loader.py     # GGUF model management
│   │   └── prompt_runner.py    # Prompt execution engine
│   ├── prompts/                # Few-shot prompt templates
│   │   ├── grammar.txt
│   │   ├── rewrite_clear.txt
│   │   ├── professional.txt
│   │   ├── expand.txt
│   │   └── shorten.txt
│   ├── models/                 # GGUF model files (git-ignored)
│   ├── main.py                 # FastAPI + uvicorn entry point
│   └── requirements.txt        # Python dependencies
│
├── installer/                  # Windows installer
│   ├── windows/
│   │   └── grammar_assistant.iss   # Inno Setup script
│   └── scripts/
│       └── build_installer.bat     # One-click build
│
├── run.bat                     # Quick start (backend + frontend)
├── run_backend_only.bat        # Backend-only launcher
├── LICENSE                     # MIT License
└── README.md                   # This file
```

---

## 🤖 AI Model

This application uses **Qwen2.5-0.5B-Instruct** quantized to **Q4_K_M** format for fast, lightweight inference:

| Property | Value |
|---|---|
| Model | Qwen2.5-0.5B-Instruct |
| Quantization | Q4_K_M |
| File Size | ~380 MB |
| Context Window | 1024 tokens |
| Inference | CPU-only (8 threads) |
| RAM Usage | ~800 MB |

---

## ⚡ Performance

Tested on a standard Windows PC with no GPU acceleration:

| Action | Typical Response Time |
|---|---|
| Fix Grammar | ~500ms – 1.5s |
| Rewrite (Casual/Clear/Concise) | ~1–2s |
| Professional Tone | ~1–2s |
| Expand | ~3–5s |
| Shorten | ~1s |

---

## 🔧 Configuration

The backend can be configured using environment variables:

| Variable | Default | Description |
|---|---|---|
| `GRAMMAR_PORT` | `11434` | Port for the backend API server |
| `MODEL_PATH` | Auto-detected | Absolute path to the GGUF model file |
| `MODEL_THREADS` | CPU count | Number of threads for inference |
| `MODEL_CTX` | `1024` | Context window size (tokens) |
| `MODEL_BATCH` | `512` | Batch size for prompt evaluation |

---

## 🛠️ Building the Installer

To create a distributable `.exe` installer:

#### Prerequisites
- [Inno Setup 6](https://jrsoftware.org/isdl.php)

#### Steps

```bash
# One-click build — runs all 3 steps automatically
installer\scripts\build_installer.bat
```

The script performs:
1. **Prepares Embedded Python** — bundles Python 3.12 + all dependencies
2. **Flutter release build** — compiles the Windows desktop app
3. **Inno Setup compile** — packages everything into a single `.exe` installer

Output: `dist/GrammarAssistant_Setup_v1.0.0.exe` (~408 MB)

---

## 🗺️ Roadmap

- [x] Core grammar correction
- [x] Rewrite (Casual, Clear, Concise)
- [x] Professional tone conversion
- [x] Expand and Shorten
- [x] Dark / Light mode
- [x] Windows installer
- [ ] Floating assistant (Ctrl+Shift+G global hotkey)
- [ ] Linux support
- [ ] Custom prompt templates

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Qwen2.5](https://github.com/QwenLM/Qwen2.5) — AI model by Alibaba Cloud
- [llama.cpp](https://github.com/ggerganov/llama.cpp) — CPU inference engine by Georgi Gerganov
- [llama-cpp-python](https://github.com/abetlen/llama-cpp-python) — Python bindings for llama.cpp
- [Flutter](https://flutter.dev) — UI framework by Google
- [FastAPI](https://fastapi.tiangolo.com) — Python web framework by Sebastián Ramírez
- [Inno Setup](https://jrsoftware.org/isinfo.php) — Windows installer builder

---

<div align="center">

**Made with ❤️ — Fully offline, fully private.**

</div>
