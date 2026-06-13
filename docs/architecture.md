# Architecture — Grammar Assistant

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter Desktop App (Windows)                               │
│                                                             │
│  ┌─────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │ HomeScreen   │  │ BackendService   │  │ HistoryService│  │
│  │ SettingsScr  │  │ (HTTP Client)    │  │ (SQLite FFI)  │  │
│  └──────┬───────┘  └────────┬─────────┘  └───────────────┘  │
│         │                   │                                │
└─────────┼───────────────────┼────────────────────────────────┘
          │        HTTP REST   │  127.0.0.1:11434
          │        (loopback)  │
┌─────────▼───────────────────▼────────────────────────────────┐
│  Python FastAPI Backend                                       │
│                                                              │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────┐ │
│  │ /health     │  │ /api/process │  │ PromptRunner        │ │
│  │ (readiness) │  │ (main route) │  │ (loads .txt prompt) │ │
│  └─────────────┘  └──────┬───────┘  └──────────┬──────────┘ │
│                           │                     │           │
│                    ┌──────▼─────────────────────▼─────────┐ │
│                    │  ModelLoader (Singleton)              │ │
│                    │  llama-cpp-python                     │ │
│                    └──────────────┬────────────────────────┘ │
└───────────────────────────────────┼──────────────────────────┘
                                    │
                        ┌───────────▼───────────┐
                        │  Qwen2.5-0.5B GGUF    │
                        │  Q4_K_M (~400 MB)     │
                        │  CPU Inference         │
                        └───────────────────────┘
```

## Key Design Decisions

### IPC: HTTP on Loopback
- Flutter calls `http://127.0.0.1:11434` — simple, debuggable, language-agnostic
- Loopback only — never accessible over the network

### Process Lifecycle
- Flutter's `BackendLauncher` spawns the Python process on startup
- `Process.kill()` is called on `AppLifecycleState.detached`
- `/health` polling ensures UI doesn't display until model is ready

### Model Loading
- `ModelLoader` is a singleton — model loads once at startup
- `n_ctx=2048`, `n_threads=4`, `n_gpu_layers=0` (CPU-only)
- Configurable via environment variables

### Prompt Engineering
- Each action has its own `.txt` system prompt file
- Prompts are cached in memory after first load
- All prompts instruct the model to return ONLY the result (no meta-commentary)

### Storage
- **History**: SQLite via `sqflite_common_ffi` at `%APPDATA%\GrammarAssistant\history.db`
- **Settings**: `SharedPreferences` for theme persistence

## Data Flow

```
User types text
      │
      ▼
HomeScreen._runAction(actionId)
      │
      ▼
BackendService.processText(action, text)
  → POST /api/process  {action, text}
      │
      ▼
PromptRunner.run(action, text)
  → loads prompt from prompts/<action>.txt
  → calls llama_wrapper.run_inference(system, user)
      │
      ▼
ModelLoader.get_instance().create_chat_completion(messages)
  → Qwen2.5 GGUF model on CPU
      │
      ▼
Response: {result, elapsed_ms, action}
      │
      ▼
HomeScreen shows result in TextOutputPanel
HistoryService.insert(entry)  [async, non-blocking]
```
