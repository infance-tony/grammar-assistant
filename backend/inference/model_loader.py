"""
Singleton model loader.
Loads the GGUF model once at startup; subsequent calls return the cached instance.
Supports runtime model switching via switch_model().
"""

import os
import sys
import logging
import threading
from pathlib import Path

logger = logging.getLogger("grammar_assistant.model_loader")

# Per-model metadata: stop tokens, context window, and special flags
# no_think=True → Qwen3 thinking mode disabled (prepends /no_think to user message)
_MODEL_REGISTRY: dict[str, dict] = {
    "phi4mini.gguf":    {"stop": ["<|im_end|>", "<|end|>", "<|endoftext|>"], "n_ctx": 2048, "no_think": False},
    "qwen15b.gguf":     {"stop": ["<|im_end|>", "<|endoftext|>"],            "n_ctx": 2048, "no_think": False},
    "qwen3-1.7b.gguf":  {"stop": ["<|im_end|>", "<|endoftext|>"],            "n_ctx": 2048, "no_think": True},
    "qwen.gguf":        {"stop": ["<|im_end|>", "<|endoftext|>"],            "n_ctx": 1024, "no_think": False},
}
_DEFAULT_STOP = ["<|im_end|>", "<|endoftext|>"]
_DEFAULT_CTX = 2048


def _find_model_path() -> Path:
    """Find the GGUF model file.

    Priority: MODEL_PATH env var → phi4mini.gguf → qwen15b.gguf → qwen.gguf
    Searches dev, PyInstaller, and installed layouts.
    """
    env_path = os.environ.get("MODEL_PATH")
    if env_path:
        return Path(env_path)

    candidates: list[Path] = []

    if getattr(sys, "frozen", False):
        exe_dir = Path(sys.executable).parent
        candidates += [exe_dir, exe_dir.parent]
    else:
        src_dir = Path(__file__).parent.parent
        candidates += [src_dir, src_dir.parent]

    preferred = list(_MODEL_REGISTRY.keys())

    for name in preferred:
        for base in candidates:
            p = base / "models" / name
            if p.exists():
                return p

    # Fallback — return expected path for the best model so error message is clear
    return candidates[0] / "models" / "phi4mini.gguf"


class ModelLoader:
    _instance = None
    _lock = threading.Lock()
    _ready = False
    _active_model_name: str = ""
    _stop_tokens: list[str] = _DEFAULT_STOP
    _no_think: bool = False

    @classmethod
    def get_instance(cls):
        """Return the loaded Llama model, loading it on first call."""
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = cls._load(_find_model_path())
                    cls._ready = True
        return cls._instance

    @classmethod
    def is_ready(cls) -> bool:
        return cls._ready

    @classmethod
    def get_active_model_name(cls) -> str:
        return cls._active_model_name

    @classmethod
    def get_stop_tokens(cls) -> list[str]:
        return cls._stop_tokens

    @classmethod
    def is_no_think(cls) -> bool:
        """True when the loaded model needs /no_think to suppress chain-of-thought."""
        return cls._no_think

    @classmethod
    def switch_model(cls, filename: str) -> None:
        """Reload with a different GGUF file from the models/ directory."""
        # Resolve models directory from the current active path or standard location
        current_path = _find_model_path()
        models_dir = current_path.parent
        new_path = models_dir / filename

        if not new_path.exists():
            raise FileNotFoundError(
                f"Model file not found: {new_path}\n"
                f"Run: python download_model.py {filename.replace('.gguf', '')}"
            )

        with cls._lock:
            cls._instance = None
            cls._ready = False
            os.environ["MODEL_PATH"] = str(new_path)
            cls._instance = cls._load(new_path)
            cls._ready = True

    @classmethod
    def _load(cls, model_path: Path):
        from llama_cpp import Llama

        if not model_path.exists():
            raise FileNotFoundError(
                f"Model file not found at: {model_path}\n"
                "Run: python download_model.py phi4mini\n"
                "or:  python download_model.py qwen15b"
            )

        import multiprocessing
        cpu_count = multiprocessing.cpu_count()
        threads = int(os.environ.get("MODEL_THREADS", max(cpu_count, 4)))

        name = model_path.name
        meta = _MODEL_REGISTRY.get(name, {})
        n_ctx = int(os.environ.get("MODEL_CTX", meta.get("n_ctx", _DEFAULT_CTX)))

        logger.info("Loading model: %s (%d threads, n_ctx=%d)", name, threads, n_ctx)

        model = Llama(
            model_path=str(model_path),
            n_ctx=n_ctx,
            n_threads=threads,
            n_batch=int(os.environ.get("MODEL_BATCH", 512)),
            n_gpu_layers=int(os.environ.get("MODEL_GPU_LAYERS", 0)),
            verbose=False,
        )

        cls._active_model_name = name
        cls._stop_tokens = meta.get("stop", _DEFAULT_STOP)
        cls._no_think = bool(meta.get("no_think", False))

        logger.info("Model loaded: %s ✓ (no_think=%s)", name, cls._no_think)
        return model
