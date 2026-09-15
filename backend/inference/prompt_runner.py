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
        return Path(sys._MEIPASS) / "prompts"
    return Path(__file__).parent.parent / "prompts"

_PROMPTS_DIR = _get_prompts_dir()

# Map action name → (prompt_file, max_tokens, temperature, uses_output_tag)
_ACTION_CONFIG: dict[str, tuple[str, int, float, bool]] = {
    "grammar":          ("grammar.txt",          400,  0.0,  True),
    "rewrite_casual":   ("rewrite_casual.txt",   250,  0.4,  True),
    "rewrite_clear":    ("rewrite_clear.txt",    250,  0.2,  True),
    "rewrite_concise":  ("rewrite_concise.txt",  150,  0.1,  True),
    "professional":     ("professional.txt",     350,  0.1,  True),
    "expand":           ("expand.txt",           900,  0.4,  True),
    "shorten":          ("shorten.txt",          120,  0.1,  True),
    "explain":          ("explain.txt",          500,  0.2,  False),
    "tone":             ("tone.txt",              20,  0.1,  False),
    "suggest_multi":    ("grammar.txt",          300,  0.5,  True),
    "email":            ("email.txt",            600,  0.3,  False),
}

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
    """Extract the LAST output-marker block from the model response.

    The model sometimes echoes few-shot examples before the real answer, so we
    must take the LAST occurrence of any output marker, not the first.
    """
    # All markers used across all prompt files
    _MARKER = (
        r'(?:[Oo]utput'
        r'|[Cc]lear rewrite'
        r'|[Cc]oncise rewrite'
        r'|[Ee]xpanded(?: version)?'
        r'|[Ss]hortened(?: version)?'
        r'|[Pp]rofessional(?: version| rewrite)?'
        r'|[Cc]asual(?: rewrite)?'
        r'|[Cc]orrected'
        r'|[Rr]ewritten)'
    )
    pattern = re.compile(
        r'(?:^|\n)\s*' + _MARKER + r'\s*:\s*(.+)',
        re.DOTALL,
    )

    # Take the LAST match — earlier ones are from few-shot examples
    last_match = None
    for m in pattern.finditer(raw):
        last_match = m
    if last_match:
        return last_match.group(1).strip()

    # Fallback: strip common AI preamble phrases
    preamble_patterns = [
        r'^(?:Here is|Here\'s|Sure[,!]?|The corrected|Corrected[:]?)[\s\S]{0,40}:\s*',
        r'^(?:The (?:rewritten|shortened|expanded|professional|casual|clear|concise) (?:version|text)[:]?)\s*',
        r'^(?:Certainly[!,]?|Of course[!,]?|Absolutely[!,]?)\s*',
    ]
    result = raw
    for pat in preamble_patterns:
        result = re.sub(pat, '', result, flags=re.IGNORECASE).strip()
    return result


class PromptRunner:
    @staticmethod
    def run(action: str, text: str) -> str:
        """Run the appropriate prompt template for the given action."""
        if action not in _ACTION_CONFIG:
            raise ValueError(f"Unknown action: {action}")

        prompt_file, max_tokens, temperature, uses_output_tag = _ACTION_CONFIG[action]

        template = _load_prompt(prompt_file)
        full_prompt = template.replace("{text}", text)

        logger.info("Running action='%s' max_tokens=%d temp=%.2f", action, max_tokens, temperature)

        result = run_inference(
            system_prompt="You are a helpful text processing assistant. Follow instructions exactly.",
            user_text=full_prompt,
            max_tokens=max_tokens,
            temperature=temperature,
        )

        result = result.strip()

        if uses_output_tag:
            result = _extract_output(result)

        if not result or result.lower().strip() == text.lower().strip():
            logger.warning("Model returned empty or echoed input for action=%s", action)
            return text

        return result

    @staticmethod
    def run_multi(action: str, text: str, n: int = 3) -> list[str]:
        """Run inference n times and return a list of distinct non-echo results."""
        results: list[str] = []
        seen: set[str] = set()
        for _ in range(n):
            try:
                r = PromptRunner.run(action, text)
                key = r.strip().lower()
                if key not in seen and key != text.lower().strip():
                    seen.add(key)
                    results.append(r)
            except Exception as e:
                logger.warning("run_multi attempt failed: %s", e)
        return results if results else [text]
