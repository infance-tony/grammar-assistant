"""
Grammar Assistant API router.
POST /process   → run an AI action on the provided text.
GET  /models    → list available GGUF files and active model.
POST /switch_model → switch active model at runtime.
"""

import re
import sys
import time
import logging
from pathlib import Path

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from inference.prompt_runner import PromptRunner
from inference.model_loader import ModelLoader

logger = logging.getLogger("grammar_assistant.api")
router = APIRouter(prefix="/api", tags=["grammar"])


# ── Schemas ────────────────────────────────────────────────────────────────

class ProcessRequest(BaseModel):
    action: str = Field(
        ...,
        description=(
            "One of: grammar, rewrite_casual, rewrite_clear, rewrite_concise, "
            "professional, expand, shorten, explain, tone, suggest_multi, email"
        ),
        examples=["grammar"],
    )
    text: str = Field(..., min_length=1, max_length=8000, description="Input text")


class TextStats(BaseModel):
    word_count: int
    char_count: int
    sentence_count: int
    reading_time_sec: int


class ProcessResponse(BaseModel):
    result: str
    elapsed_ms: int
    action: str
    alternatives: list[str] = []
    tone: str | None = None
    stats: TextStats | None = None


class SwitchModelRequest(BaseModel):
    filename: str


VALID_ACTIONS = {
    "grammar",
    "rewrite_casual",
    "rewrite_clear",
    "rewrite_concise",
    "professional",
    "expand",
    "shorten",
    "explain",
    "tone",
    "suggest_multi",
    "email",
}


# ── Helpers ────────────────────────────────────────────────────────────────

def _compute_stats(text: str) -> TextStats:
    words = len(text.split()) if text.strip() else 0
    chars = len(text)
    sentences = max(1, len(re.findall(r'[.!?]+', text)))
    reading_time_sec = max(1, words * 60 // 200)
    return TextStats(
        word_count=words,
        char_count=chars,
        sentence_count=sentences,
        reading_time_sec=reading_time_sec,
    )


def _get_models_dir() -> Path:
    if getattr(sys, "frozen", False):
        # PyInstaller exe is at {app}\grammar_backend_python\grammar_backend.exe
        # models are installed at {app}\models\
        return Path(sys.executable).parent.parent / "models"
    return Path(__file__).parent.parent / "models"


# ── Endpoints ──────────────────────────────────────────────────────────────

@router.post("/process", response_model=ProcessResponse)
async def process_text(req: ProcessRequest):
    if req.action not in VALID_ACTIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid action '{req.action}'. Must be one of: {sorted(VALID_ACTIONS)}",
        )

    logger.info("action=%s  text_len=%d", req.action, len(req.text))

    stats = _compute_stats(req.text)
    alternatives: list[str] = []
    tone_result: str | None = None

    t0 = time.perf_counter()
    try:
        if req.action == "suggest_multi":
            alternatives = PromptRunner.run_multi("suggest_multi", req.text, n=3)
            result = alternatives[0] if alternatives else req.text
        else:
            result = PromptRunner.run(action=req.action, text=req.text)
            if req.action == "tone":
                tone_result = result.strip().lower()
    except Exception as exc:
        logger.exception("Inference failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Inference error: {exc}") from exc

    elapsed_ms = int((time.perf_counter() - t0) * 1000)
    logger.info("action=%s  elapsed_ms=%d", req.action, elapsed_ms)

    return ProcessResponse(
        result=result,
        elapsed_ms=elapsed_ms,
        action=req.action,
        alternatives=alternatives,
        tone=tone_result,
        stats=stats,
    )


@router.get("/models")
async def list_models():
    """Return list of available GGUF files and the currently active model."""
    models_dir = _get_models_dir()
    gguf_files = sorted(f.name for f in models_dir.glob("*.gguf")) if models_dir.exists() else []
    return {"models": gguf_files, "active": ModelLoader.get_active_model_name()}


@router.post("/switch_model")
async def switch_model(req: SwitchModelRequest):
    """Reload the backend with a different GGUF model file."""
    if not req.filename.endswith(".gguf"):
        raise HTTPException(status_code=400, detail="filename must end in .gguf")
    try:
        ModelLoader.switch_model(req.filename)
    except FileNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.exception("Model switch failed: %s", e)
        raise HTTPException(status_code=500, detail=f"Model switch failed: {e}")
    return {"status": "ok", "active": req.filename}
