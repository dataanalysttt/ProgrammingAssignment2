---
id: l1-m6-l3
title: Errors and try / except
minutes: 15
concepts: [exceptions]
objectives:
- Catch specific exceptions with try / except
- Decide what a function should return when input is bad
- Avoid bare except that hides real bugs
---

## Learn
When something goes wrong at runtime Python raises an **exception**. `try / except` lets you handle it:

```python example
def parse_weight(text):
    try:
        return float(text.replace(",", "").replace("t", "").strip())
    except ValueError:
        return None

for raw in ["1,998.725", " 500 t", "n/a", ""]:
    print(repr(raw), "->", parse_weight(raw))
```

Common exceptions:

| Exception | Example |
|---|---|
| `ValueError` | `float("n/a")` |
| `ZeroDivisionError` | average of an empty list |
| `KeyError` | `trade["final_price"]` missing |
| `TypeError` | `"500" + 5` |
| `IndexError` | `prices[30]` on a 22-day QP |

Rules that keep you out of trouble:

1. **Catch the specific exception** you expect (`except ValueError:`). A bare `except:` also swallows typos and real bugs.
2. **Keep the `try` block small**: just the line that can fail.
3. **Decide the fallback deliberately.** `None` means "unknown"; `0` would silently understate a weight.

## Desk
Desk data is messy: warehouse lists with "n/a", PDFs with stray units, blank cells. A script that crashes at the first bad row helps nobody at month-end; one that silently treats "n/a" as 0 t is worse, because it understates an invoice. The right behaviour is to flag the bad rows and keep going, which is what you'll build here.

## Exercise
Write:

- `parse_weight(text)`: returns a float from strings like `"1,998.725"`, `" 500 t"`, `"402.0T"`; returns `None` when it can't parse (catch `ValueError` only)
- `safe_average(values)`: mean of a list, or `None` for an empty list (catch `ZeroDivisionError`)

Then use them on `raw_weights`: `weights` (the parsed floats, skipping `None`), `bad_rows` (indexes of rows that failed) and `avg_weight` (rounded to 3 decimals).

```python starter
raw_weights = ["425.500", "n/a", "1,010.25 t", "402.0T", "", "398.75"]

```

```python solution
raw_weights = ["425.500", "n/a", "1,010.25 t", "402.0T", "", "398.75"]


def parse_weight(text):
    cleaned = text.replace(",", "").replace("t", "").replace("T", "").strip()
    try:
        return float(cleaned)
    except ValueError:
        return None


def safe_average(values):
    try:
        return sum(values) / len(values)
    except ZeroDivisionError:
        return None


weights, bad_rows = [], []
for i, raw in enumerate(raw_weights):
    w = parse_weight(raw)
    if w is None:
        bad_rows.append(i)
    else:
        weights.append(w)
avg_weight = round(safe_average(weights), 3)
```

```python test "parse_weight handles formats"
assert parse_weight("1,998.725") == 1998.725, f"parse_weight('1,998.725') returned {parse_weight('1,998.725')!r}."
assert parse_weight(" 500 t") == 500.0 and parse_weight("402.0T") == 402.0, "Strip spaces and the unit (t or T) before converting."
```

```python test "parse_weight returns None on bad input"
assert parse_weight("n/a") is None and parse_weight("") is None, "Bad input should return None, not crash and not 0."
```

```python test "safe_average"
assert safe_average([]) is None, "safe_average([]) should return None (catch ZeroDivisionError)."
assert safe_average([2, 4]) == 3, "safe_average([2, 4]) should be 3."
```

```python test "results on raw_weights"
assert weights == [425.5, 1010.25, 402.0, 398.75], f"weights is {weights}."
assert bad_rows == [1, 4], f"bad_rows is {bad_rows}; rows 1 ('n/a') and 4 ('') fail."
assert approx(avg_weight, 559.125, 1e-9), f"avg_weight is {avg_weight}; expected 2,236.5 / 4 = 559.125."
```

### Hint 1
Clean the text first (remove `,`, `t`, `T`, spaces), then `try: return float(...)`.

### Hint 2
`except ValueError: return None`. For the average, `len([])` is 0, so dividing raises `ZeroDivisionError`. Use `enumerate` to know each row's index.

### Hint 3
```python
def parse_weight(text):
    cleaned = text.replace(",", "").replace("t", "").replace("T", "").strip()
    try:
        return float(cleaned)
    except ValueError:
        return None
```

## Cards

### Card recall
concept: exceptions
Q: Why is `except:` (bare) dangerous in pricing code?
A: It catches every error, including typos (`NameError`) and real bugs, and hides them. Catch the specific exception you expect, e.g. `except ValueError:`.

### Card code
concept: exceptions
Q: Write `to_float(s)` returning `float(s)`, or `None` if it raises `ValueError`.
```python starter
```
```python solution
def to_float(s):
    try:
        return float(s)
    except ValueError:
        return None
```
```python test "to_float"
assert to_float("2850.5") == 2850.5 and to_float("tbc") is None, "to_float('tbc') should return None."
```

## Next
Some inputs aren't just messy, they're wrong: negative tonnes, an Incoterm that doesn't exist. Your function should refuse them loudly.
