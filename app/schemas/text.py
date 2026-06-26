import unicodedata
from typing import Any


def normalize_unicode_text(value: Any) -> Any:
    """Trim text while preserving Unicode letters, including Cyrillic."""
    if value is None or not isinstance(value, str):
        return value

    normalized = value.strip()
    if not normalized:
        raise ValueError("Text field cannot be empty")

    for character in normalized:
        if unicodedata.category(character).startswith("C") and character not in {"\n", "\r", "\t"}:
            raise ValueError("Text field contains unsupported control characters")

    return normalized
