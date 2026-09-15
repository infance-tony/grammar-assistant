#!/usr/bin/env python3
"""
Download Grammar Assistant GGUF models from HuggingFace.

Usage:
    python download_model.py [qwen3-1.7b|phi4mini|qwen15b|qwen05b]

qwen3-1.7b — Qwen3 1.7B Q4_K_M (~1.1 GB, latest, best ~1 GB model)
phi4mini   — Phi-4-mini-instruct Q4_K_M (~2.3 GB, best quality overall)
qwen15b    — Qwen2.5-1.5B-Instruct Q4_K_M (~900 MB, solid under 1 GB)
qwen05b    — Qwen2.5-0.5B-Instruct Q4_K_M (~380 MB, legacy/minimum)
"""
import urllib.request
import os
import sys
from pathlib import Path

MODELS = {
    "qwen3-1.7b": {
        "url": "https://huggingface.co/unsloth/Qwen3-1.7B-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf",
        "filename": "qwen3-1.7b.gguf",
        "size_hint": "~1.1 GB",
    },
    "phi4mini": {
        "url": "https://huggingface.co/bartowski/Phi-4-mini-instruct-GGUF/resolve/main/Phi-4-mini-instruct-Q4_K_M.gguf",
        "filename": "phi4mini.gguf",
        "size_hint": "~2.3 GB",
    },
    "qwen15b": {
        "url": "https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf",
        "filename": "qwen15b.gguf",
        "size_hint": "~900 MB",
    },
    "qwen05b": {
        "url": "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf",
        "filename": "qwen.gguf",
        "size_hint": "~380 MB",
    },
}


def download(key: str) -> None:
    m = MODELS[key]
    dest = Path(__file__).parent / "models" / m["filename"]
    dest.parent.mkdir(exist_ok=True)

    if dest.exists():
        print(f"Already exists: {dest}")
        return

    print(f"Downloading {key} ({m['size_hint']}) ...")
    print(f"  Destination: {dest}")

    last_pct = [-1]

    def progress(count: int, block_size: int, total_size: int) -> None:
        if total_size <= 0:
            return
        pct = min(100, count * block_size * 100 // total_size)
        if pct != last_pct[0]:
            bar = "#" * (pct // 2) + "-" * (50 - pct // 2)
            mb_done = count * block_size / 1_048_576
            mb_total = total_size / 1_048_576
            sys.stdout.write(f"\r  [{bar}] {pct:3d}%  {mb_done:.0f}/{mb_total:.0f} MB")
            sys.stdout.flush()
            last_pct[0] = pct

    tmp = dest.with_suffix(".tmp")
    try:
        urllib.request.urlretrieve(m["url"], str(tmp), reporthook=progress)
        tmp.rename(dest)
        print(f"\nDone: {dest}")
    except Exception as e:
        if tmp.exists():
            tmp.unlink()
        print(f"\nError: {e}")
        sys.exit(1)


def main() -> None:
    key = sys.argv[1] if len(sys.argv) > 1 else "phi4mini"
    if key not in MODELS:
        print(f"Unknown model '{key}'. Choose from: {list(MODELS.keys())}")
        sys.exit(1)
    download(key)


if __name__ == "__main__":
    main()
