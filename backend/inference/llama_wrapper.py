"""
Thin wrapper around llama-cpp-python.
Handles the chat-completion call with Qwen2.5 chat template format.
"""

import logging
from typing import Optional
from inference.model_loader import ModelLoader

logger = logging.getLogger("grammar_assistant.llama_wrapper")

# Qwen2.5-Instruct uses the standard ChatML format
_SYSTEM_ROLE = "system"
_USER_ROLE = "user"


def run_inference(
    system_prompt: str,
    user_text: str,
    max_tokens: int = 512,
    temperature: float = 0.2,
    top_p: float = 0.9,
    repeat_penalty: float = 1.1,
) -> str:
    """
    Run inference using the loaded Llama model.

    Args:
        system_prompt: The task instruction (e.g. 'Fix grammar…')
        user_text:     The raw user input text
        max_tokens:    Max tokens to generate
        temperature:   Sampling temperature (lower = more deterministic)
        top_p:         Nucleus sampling threshold
        repeat_penalty: Penalty for repeated tokens

    Returns:
        The model's generated text (stripped).
    """
    model = ModelLoader.get_instance()

    messages = [
        {"role": _SYSTEM_ROLE, "content": system_prompt},
        {"role": _USER_ROLE,   "content": user_text},
    ]

    logger.debug("Running inference: max_tokens=%d temp=%.2f", max_tokens, temperature)

    response = model.create_chat_completion(
        messages=messages,
        max_tokens=max_tokens,
        temperature=temperature,
        top_p=top_p,
        repeat_penalty=repeat_penalty,
        stop=["<|im_end|>", "<|endoftext|>"],
    )

    content: Optional[str] = response["choices"][0]["message"].get("content", "")
    return (content or "").strip()
