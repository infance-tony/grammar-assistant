"""
Singleton model loader.
Loads the GGUF model once at startup; subsequent calls return the cached instance.
"""

import os
import sys
import logging
import threading
from pathlib import Path

logger = logging.getLogger("grammar_assistant.model_loader")

# ── Locate the model file ──────────────────────────────────────────────────
_MODEL_NAME = "qwen.gguf"

def _find_model_path() -> Path:
    """Find the GGUF model file.
    Searches multiple directories to support dev, PyInstaller, and embedded Python layouts.
    """
    # 1. Explicit override via env var
    env_path = os.environ.get("MODEL_PATH")
    if env_path:
        return Path(env_path)

    # Build list of candidate base directories
    candidates = []

    if getattr(sys, 'frozen', False):
        # PyInstaller bundle
        exe_dir = Path(sys.executable).parent
        candidates.append(exe_dir)
        candidates.append(exe_dir.parent)
    else:
        # Normal Python — check relative to source file (backend/inference/ → backend/)
        src_dir = Path(__file__).parent.parent
        candidates.append(src_dir)
        candidates.append(src_dir.parent)  # installed: grammar_backend_python/../

    # 2. Search candidates
    for base in candidates:
        p = base / "models" / _MODEL_NAME
        if p.exists():
            return p

    # 3. Fallback — return first candidate (will raise FileNotFoundError later)
    return candidates[0] / "models" / _MODEL_NAME

_DEFAULT_MODEL_PATH = _find_model_path()


class ModelLoader:
    _instance = None
    _lock = threading.Lock()
    _ready = False

    @classmethod
    def get_instance(cls):
        """Return the loaded Llama model, loading it on first call."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls._load()
                    cls._ready = True
        return cls._instance

    @classmethod
    def is_ready(cls) -> bool:
        return cls._ready

    @classmethod
    def _load(cls):
        from llama_cpp import Llama  # imported here so startup is fast if model missing

        model_path = _DEFAULT_MODEL_PATH

        if not model_path.exists():
            raise FileNotFoundError(
                f"Model file not found at: {model_path}\n"
                "Download Qwen2.5-0.5B-Instruct Q4_K_M GGUF and place it at "
                "backend/models/qwen.gguf"
            )

        import multiprocessing
        cpu_count = multiprocessing.cpu_count()
        # Use all physical cores for max speed
        threads = int(os.environ.get("MODEL_THREADS", max(cpu_count, 4)))

        logger.info("Loading model from %s … (%d threads)", model_path, threads)

        model = Llama(
            model_path=str(model_path),
            n_ctx=int(os.environ.get("MODEL_CTX", 1024)),    # 1024 is enough; saves RAM
            n_threads=threads,
            n_batch=int(os.environ.get("MODEL_BATCH", 512)), # larger batch = faster prompt eval
            n_gpu_layers=int(os.environ.get("MODEL_GPU_LAYERS", 0)),  # CPU-only by default
            verbose=False,
        )

        logger.info("Model loaded successfully ✓ (%d threads, n_ctx=1024)", threads)
        return model
