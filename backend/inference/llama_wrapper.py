"""
Thin wrapper around llama-cpp-python.
Handles ChatML inference and Qwen3 no-think mode.
"""

import re
import logging
from typing import Optional
from inference.model_loader import ModelLoader

logger = logging.getLogger("grammar_assistant.llama_wrapper")


def run_inference(
    system_prompt: str,
    user_text: str,
    max_tokens: int = 512,
    temperature: float = 0.2,
    top_p: float = 0.9,
    repeat_penalty: float = 1.1,
) -> str:
    model = ModelLoader.get_instance()

    # Qwen3: prepend /no_think to disable chain-of-thought reasoning blocks
    if ModelLoader.is_no_think():
        user_text = "/no_think\n" + user_text

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_text},
    ]

    logger.debug("Running inference: max_tokens=%d temp=%.2f", max_tokens, temperature)

    response = model.create_chat_completion(
        messages=messages,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        repeat_penalty=repeat_penalty,
        stop=ModelLoader.get_stop_tokens(),
    )

    content: Optional[str] = response["choices"][0]["message"].get("content", "")
    result = (content or "").strip()

    # Strip <think>...</think> blocks in case the model outputs them anyway
    result = re.sub(r"<think>[\s\S]*?</think>", "", result, flags=re.IGNORECASE).strip()

    return result
