---
id: l0-m1-l2
title: Reading errors without panic
minutes: 12
xp: 40
concepts: [errors-reading]
objectives:
- Read a Python error message from the bottom up
- Recognise SyntaxError and NameError
- Fix a broken script line by line
---

## Learn
Errors are information, not failure. Python stops at the **first** problem and tells you three things:

1. **Where:** `Line 3: ...` shows the line it was executing.
2. **What kind:** e.g. `SyntaxError`, `NameError`, `TypeError`.
3. **Detail:** e.g. `name 'premum' is not defined`.

The two you'll see most at the start:

| Error | Meaning | Typical cause |
|---|---|---|
| `SyntaxError` | Python can't parse the line | missing `)` or quote, stray character |
| `NameError` | a name isn't defined | typo, or using a variable before creating it |

Run this to see a NameError, then fix the typo:

```python example
premium = 245
print(premum)
```

Fix one error, run again, read the next one. Don't try to fix everything at once.

## Desk
Desk systems break at the worst times, usually at month-end. Whoever reads the error message calmly and reports "line 3, `premum` isn't defined" gets it fixed in two minutes. Whoever says "it's broken" waits for IT.

## Exercise
This script should compute a provisional invoice value but has **three** errors. Fix them so it runs and creates `provisional_value` equal to `tonnes * (lme_cash + premium)`.

Fix one error at a time: Run, read, fix, repeat.

```python starter
tonnes = 500
lme_cash = 2850
premium = 245
provisional_value = tonnes * (lme_cash + premum
print("Provisional value:", provisional_value))
print("Per tonne:", lme_cash + premium_usd)
```

```python solution
tonnes = 500
lme_cash = 2850
premium = 245
provisional_value = tonnes * (lme_cash + premium)
print("Provisional value:", provisional_value)
print("Per tonne:", lme_cash + premium)
```

```python test "Script runs and provisional_value exists"
assert "provisional_value" in dir(), "provisional_value was not created; check line 4."
```

```python test "provisional_value = 1,547,500"
assert provisional_value == 1547500, f"provisional_value is {provisional_value}; expected 500 x (2850 + 245) = 1,547,500."
```

```python test "Per-tonne price printed"
assert "3095" in __stdout__, "The per-tonne line should print 3095 (2850 + 245). Is the variable name on the last line right?"
```

### Hint 1
Run it and look only at the first error. It's a `SyntaxError` on line 4: count the brackets.

### Hint 2
Every `(` needs exactly one matching `)`. Line 4 is missing one; line 5 has one too many. After that, look for names that were never created: `premum` and `premium_usd` aren't variables in this script.

### Hint 3
```python
provisional_value = tonnes * (lme_cash + premium)
print("Provisional value:", provisional_value)
```

## Cards

### Card recall
concept: errors-reading
Q: Python reports `NameError: name 'premum' is not defined`. What are the two most likely causes?
A: A typo in the name (here `premum` instead of `premium`), or using the variable before the line that creates it.

### Card recall
concept: errors-reading
Q: You get a `SyntaxError` that points at a line that looks fine. Where else should you look?
A: The line before it. An unclosed bracket or quote on the previous line often shows up as an error on the next one.

## Next
How many hours does Level 1 actually take, and when will you finish it? Let's put your study plan into numbers.
