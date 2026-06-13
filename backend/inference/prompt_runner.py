"""
Prompt runner: loads the right prompt template for each action,
injects user text, and calls the llama wrapper.
"""

import logging
import re
import sys
from pathlib import Path
from inference.llama_wrapper import run_inference

logger = logging.getLogger("grammar_assistant.prompt_runner")

def _get_prompts_dir() -> Path:
    """Resolve prompts directory for both dev and PyInstaller modes."""
    if getattr(sys, 'frozen', False):
        # PyInstaller: prompts bundled inside _MEIPASS temp dir
        return Path(sys._MEIPASS) / "prompts"
    return Path(__file__).parent.parent / "prompts"

_PROMPTS_DIR = _get_prompts_dir()

# Map action name → (prompt_file, max_tokens, temperature, uses_output_tag)
# Lower max_tokens = faster response. Grammar/rewrite actions are short.
# uses_output_tag: True means the prompt ends with "Output:" and we extract after it
_ACTION_CONFIG: dict[str, tuple[str, int, float, bool]] = {
    "grammar":          ("grammar.txt",          200,  0.05, True),
    "rewrite_casual":   ("rewrite_casual.txt",   250,  0.4,  True),
    "rewrite_clear":    ("rewrite_clear.txt",    250,  0.2,  True),
    "rewrite_concise":  ("rewrite_concise.txt",  150,  0.1,  True),
    "professional":     ("professional.txt",      250,  0.1,  True),
    "expand":           ("expand.txt",            600,  0.4,  True),
    "shorten":          ("shorten.txt",           120,  0.1,  True),
}

# Cache loaded prompt files in memory (cleared on restart)
_prompt_cache: dict[str, str] = {}


def _load_prompt(filename: str) -> str:
    if filename not in _prompt_cache:
        path = _PROMPTS_DIR / filename
        if not path.exists():
            raise FileNotFoundError(f"Prompt file not found: {path}")
        _prompt_cache[filename] = path.read_text(encoding="utf-8").strip()
        logger.debug("Loaded prompt: %s", filename)
    return _prompt_cache[filename]


def _extract_output(raw: str) -> str:
    """
    If the model echoes 'Output: ...' in the response, extract only what follows.
    Also strips common preamble phrases the model might add.
    """
    # Look for "Output:" marker (case-insensitive)
    match = re.search(r'(?:^|\n)\s*[Oo]utput\s*:\s*(.+)', raw, re.DOTALL)
    if match:
        return match.group(1).strip()

    # Strip common preamble phrases
    preamble_patterns = [
        r'^(Here is|Here\'s|Sure[,!]?|The corrected|Corrected[:]?)[\s\S]{0,40}:\s*',
        r'^(The (?:rewritten|shortened|expanded|professional|casual|clear|concise) version[:]?)\s*',
    ]
    result = raw
    for pat in preamble_patterns:
        result = re.sub(pat, '', result, flags=re.IGNORECASE).strip()

    return result


class PromptRunner:
    @staticmethod
    def run(action: str, text: str) -> str:
        """
        Run the appropriate prompt template for the given action.

        Args:
            action: One of the VALID_ACTIONS keys
            text:   The user's input text

        Returns:
            The AI-generated result string.
        """
        if action not in _ACTION_CONFIG:
            raise ValueError(f"Unknown action: {action}")

        prompt_file, max_tokens, temperature, uses_output_tag = _ACTION_CONFIG[action]

        # Build the full prompt by injecting user text into template
        template = _load_prompt(prompt_file)
        full_prompt = template.replace("{text}", text)

        logger.info("Running action='%s' max_tokens=%d temp=%.2f", action, max_tokens, temperature)

        # For few-shot prompts, pass entire prompt as the user message
        # The system message is kept minimal to not confuse the model
        result = run_inference(
            system_prompt="You are a helpful text processing assistant. Follow instructions exactly.",
            user_text=full_prompt,
            max_tokens=max_tokens,
            temperature=temperature,
        )

        result = result.strip()

        # Extract only the relevant output (strips preamble/echoes)
        if uses_output_tag:
            result = _extract_output(result)

        # Final safety: if model returned empty or full echo, return original
        if not result or result.lower().strip() == text.lower().strip():
            logger.warning("Model returned empty or echoed input for action=%s", action)
            return text

        return result
