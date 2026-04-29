#!/usr/bin/env python3
"""Token measurement helper for the caveman evals harness.

Uses tiktoken (cl100k_base) when available — that matches the OpenAI / Anthropic
tokenisers closely enough to defend savings claims in numbers an LLM team will
recognise. Falls back to whitespace word count when tiktoken is unavailable, so
the harness can run in restricted environments (no PyPI, sandboxes, CI without
the optional dep installed).

Public API:
    count_tokens(text: str) -> tuple[int, str]
        Returns (token_count, method) where method is one of
        "tiktoken-cl100k_base" or "word-count".

    method() -> str
        Returns the resolved method without consuming a string.
"""

from __future__ import annotations


def _resolve_method() -> tuple[str, object]:
    try:
        import tiktoken  # type: ignore
    except Exception:
        return "word-count", None
    try:
        enc = tiktoken.get_encoding("cl100k_base")
    except Exception:
        return "word-count", None
    return "tiktoken-cl100k_base", enc


_METHOD, _ENC = _resolve_method()


def method() -> str:
    return _METHOD


def count_tokens(text: str) -> tuple[int, str]:
    if _ENC is not None:
        return len(_ENC.encode(text)), _METHOD
    # Word-count fallback. Matches the in-script fallback in
    # scripts/understudy-compress so the two surfaces report comparable numbers.
    return len(text.split()), _METHOD


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 2:
        print("usage: measure.py FILE [FILE ...]", file=sys.stderr)
        sys.exit(2)

    print(f"# method: {method()}")
    for path in sys.argv[1:]:
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        n, _ = count_tokens(text)
        print(f"{n}\t{path}")
