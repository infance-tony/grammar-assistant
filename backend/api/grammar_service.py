"""
Grammar Assistant API router.
POST /process  →  run an AI action on the provided text.
"""

import time
import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from inference.prompt_runner import PromptRunner

logger = logging.getLogger("grammar_assistant.api")
router = APIRouter(prefix="/api", tags=["grammar"])


# ── Request / Response schemas ─────────────────────────────────────────────
class ProcessRequest(BaseModel):
    action: str = Field(
        ...,
        description=(
            "One of: grammar, rewrite_casual, rewrite_clear, "
            "rewrite_concise, professional, expand, shorten"
        ),
        examples=["grammar"],
    )
    text: str = Field(..., min_length=1, max_length=4000, description="Input text")


class ProcessResponse(BaseModel):
    result: str
    elapsed_ms: int
    action: str


VALID_ACTIONS = {
    "grammar",
    "rewrite_casual",
    "rewrite_clear",
    "rewrite_concise",
    "professional",
    "expand",
    "shorten",
}


# ── Endpoint ───────────────────────────────────────────────────────────────
@router.post("/process", response_model=ProcessResponse)
async def process_text(req: ProcessRequest):
    if req.action not in VALID_ACTIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid action '{req.action}'. Must be one of: {sorted(VALID_ACTIONS)}",
        )

    logger.info("action=%s  text_len=%d", req.action, len(req.text))

    t0 = time.perf_counter()
    try:
        result = PromptRunner.run(action=req.action, text=req.text)
    except Exception as exc:
        logger.exception("Inference failed: %s", exc)
        raise HTTPException(status_code=500, detail=f"Inference error: {exc}") from exc

    elapsed_ms = int((time.perf_counter() - t0) * 1000)
    logger.info("action=%s  elapsed_ms=%d", req.action, elapsed_ms)

    return ProcessResponse(result=result, elapsed_ms=elapsed_ms, action=req.action)
