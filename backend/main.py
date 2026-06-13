"""
Grammar Assistant Backend — FastAPI entry point.
Serves on 127.0.0.1:11434 (loopback only).
"""

import sys
import os
import logging
from contextlib import asynccontextmanager

# ── PyInstaller support ───────────────────────────────────────────────────
if getattr(sys, 'frozen', False):
    # Running from PyInstaller bundle: set working dir to _MEIPASS
    os.chdir(sys._MEIPASS)
    if sys._MEIPASS not in sys.path:
        sys.path.insert(0, sys._MEIPASS)

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from inference.model_loader import ModelLoader
from api.grammar_service import router as grammar_router

# ── Logging ────────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s  %(levelname)-8s  %(name)s  %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("grammar_assistant")


# ── Lifespan (startup / shutdown) ──────────────────────────────────────────
@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("🚀  Loading AI model — please wait…")
    ModelLoader.get_instance()          # loads model into memory once
    logger.info("✅  Model ready — server accepting requests")
    yield
    logger.info("👋  Shutting down")


# ── App ────────────────────────────────────────────────────────────────────
app = FastAPI(
    title="Grammar Assistant AI Service",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # loopback only; harmless
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(grammar_router)


@app.get("/health")
async def health():
    ready = ModelLoader.is_ready()
    return {"status": "ready" if ready else "loading"}


# ── Entry ──────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    port = int(os.environ.get("GRAMMAR_PORT", 11434))
    uvicorn.run(
        app,                     # pass object directly (required for PyInstaller)
        host="127.0.0.1",
        port=port,
        log_level="info",
        workers=1,               # must be 1 — model is a singleton
    )
