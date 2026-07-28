"""Keyword-rule categorization + macro-impact tagging.

An item can match multiple categories and multiple macro tags. Matching is a
simple case-insensitive substring search of each rule's keywords against the
item's title + summary text. This is intentionally simple/transparent so the
YAML rule files stay easy to edit without touching code.
"""
from app.yaml_config import load_categories, load_macro_tags


def _match_rules(text: str, rules: dict[str, dict]) -> list[str]:
    haystack = f" {text.lower()} "
    matched = []
    for key, rule in rules.items():
        for keyword in rule.get("keywords", []):
            if keyword.lower() in haystack:
                matched.append(key)
                break
    return matched


def tag_item(title: str, summary: str) -> dict[str, list[str]]:
    """Return {"category": [...], "macro": [...]} tag keys for an item."""
    text = f"{title} {summary}"
    categories = _match_rules(text, load_categories())
    macro = _match_rules(text, load_macro_tags())
    return {"category": categories, "macro": macro}
