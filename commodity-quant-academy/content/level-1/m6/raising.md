---
id: l1-m6-l4
title: "Raising errors: validating inputs"
minutes: 15
concepts: [validation]
objectives:
- Raise ValueError with a specific message
- Validate a trade before pricing it
- Test that bad input is rejected
---

## Learn
Catching errors handles *messy* input. **Raising** errors stops *wrong* input from going any further:

```python example
VALID_INCOTERMS = {"FCA", "FOB", "CFR", "CIF", "DAP", "DDP"}

def check_incoterm(term):
    if term not in VALID_INCOTERMS:
        raise ValueError(f"Unknown Incoterm {term!r}; expected one of {sorted(VALID_INCOTERMS)}")
    return term

try:
    check_incoterm("CNF")
except ValueError as e:
    print("Rejected:", e)
```

- `raise ValueError("message")` stops the function immediately.
- Write messages that say **what** is wrong and **what was expected**. The person reading it may be you, at 11pm, at month-end.
- `except ValueError as e:` gives you the exception; `str(e)` is its message.
- `{...}` with values and no colons is a **set**: fast membership checks, no duplicates.

Validate at the **edges**, where data enters your code (parsing a recap, reading a file), so the rest of the code can trust it.

## Desk
A trade with −500 t or "CNF" as Incoterm should never reach an invoice. Rejecting it loudly at entry, with a message ops can act on ("ZS-00517: tonnes must be > 0, got -500"), is worth more than any amount of downstream checking.

## Exercise
Write `validate_trade(trade)` that raises `ValueError` with a message containing the trade id when:

- `tonnes` is not greater than 0 (message must contain `"tonnes"`)
- `incoterm` is not one of FCA, FOB, CFR, CIF, DAP, DDP (message must contain `"incoterm"`)
- `premium` is outside −100 to 1,000 USD/t inclusive (message must contain `"premium"`)

Return `True` for a valid trade. Then build `rejected`: a dict of trade id → error message for every invalid trade in `book`.

```python starter
book = [
    {"id": "ZS-00601", "tonnes": 500, "incoterm": "DAP", "premium": 245},
    {"id": "ZS-00602", "tonnes": -250, "incoterm": "CFR", "premium": 190},
    {"id": "ZS-00603", "tonnes": 1000, "incoterm": "CNF", "premium": 242},
    {"id": "ZS-00604", "tonnes": 750, "incoterm": "CIF", "premium": 1450},
    {"id": "ZS-00605", "tonnes": 300, "incoterm": "FCA", "premium": -20},
]

```

```python solution
book = [
    {"id": "ZS-00601", "tonnes": 500, "incoterm": "DAP", "premium": 245},
    {"id": "ZS-00602", "tonnes": -250, "incoterm": "CFR", "premium": 190},
    {"id": "ZS-00603", "tonnes": 1000, "incoterm": "CNF", "premium": 242},
    {"id": "ZS-00604", "tonnes": 750, "incoterm": "CIF", "premium": 1450},
    {"id": "ZS-00605", "tonnes": 300, "incoterm": "FCA", "premium": -20},
]
VALID = {"FCA", "FOB", "CFR", "CIF", "DAP", "DDP"}


def validate_trade(trade):
    tid = trade["id"]
    if not trade["tonnes"] > 0:
        raise ValueError(f"{tid}: tonnes must be > 0, got {trade['tonnes']}")
    if trade["incoterm"] not in VALID:
        raise ValueError(f"{tid}: incoterm {trade['incoterm']!r} is not valid")
    if not -100 <= trade["premium"] <= 1000:
        raise ValueError(f"{tid}: premium {trade['premium']} outside -100..1000")
    return True


rejected = {}
for t in book:
    try:
        validate_trade(t)
    except ValueError as e:
        rejected[t["id"]] = str(e)
```

```python test "valid trade returns True"
assert validate_trade({"id": "X", "tonnes": 500, "incoterm": "DAP", "premium": 245}) is True, "A valid trade should return True."
assert validate_trade({"id": "X", "tonnes": 1, "incoterm": "FCA", "premium": -100}) is True, "Premium -100 is inside the inclusive range."
```

```python test "bad tonnes raise"
try:
    validate_trade({"id": "T1", "tonnes": 0, "incoterm": "DAP", "premium": 200})
    raise AssertionError("tonnes = 0 should raise ValueError")
except ValueError as e:
    assert "tonnes" in str(e) and "T1" in str(e), f"Message was {str(e)!r}; include the trade id and the word 'tonnes'."
```

```python test "bad incoterm and premium raise"
for bad, word in (({"id": "T2", "tonnes": 5, "incoterm": "CNF", "premium": 0}, "incoterm"), ({"id": "T3", "tonnes": 5, "incoterm": "CIF", "premium": 1001}, "premium")):
    try:
        validate_trade(bad)
        raise AssertionError(f"{bad} should raise ValueError")
    except ValueError as e:
        assert word in str(e).lower() and bad["id"] in str(e), f"Message was {str(e)!r}; include the id and '{word}'."
```

```python test "rejected dict"
assert sorted(rejected) == ["ZS-00602", "ZS-00603", "ZS-00604"], f"rejected has {sorted(rejected)}; ZS-00605's premium of -20 is valid."
assert "tonnes" in rejected["ZS-00602"] and "premium" in rejected["ZS-00604"], "Each message should name the problem field."
```

### Hint 1
Three `if` checks, each with a `raise ValueError(f"...")`, then `return True` at the end.

### Hint 2
Chained comparison: `-100 <= premium <= 1000`. In the loop, wrap `validate_trade(t)` in `try` and store `str(e)` in the `except ValueError as e:` block.

### Hint 3
```python
def validate_trade(trade):
    tid = trade["id"]
    if not trade["tonnes"] > 0:
        raise ValueError(f"{tid}: tonnes must be > 0, got {trade['tonnes']}")
    ...
    return True
```

## Cards

### Card recall
concept: validation
Q: What makes a good error message for a rejected trade?
A: It names the trade, the field, the bad value and what was expected, e.g. `ZS-00602: tonnes must be > 0, got -250`.

### Card code
concept: validation
Q: Write `check_pct(p)` that raises `ValueError` unless 0 < p ≤ 1, and returns `p` otherwise.
```python starter
```
```python solution
def check_pct(p):
    if not 0 < p <= 1:
        raise ValueError(f"pct must be in (0, 1], got {p}")
    return p
```
```python test "check_pct"
assert check_pct(0.9) == 0.9, "check_pct(0.9) should return 0.9."
try:
    check_pct(90)
    raise AssertionError("check_pct(90) should raise ValueError (90 is not 90%).")
except ValueError:
    pass
```

## Next
Boss battle, 4:55pm: the final invoice function has five bugs and the counterparty has already spotted one.
