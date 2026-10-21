---
id: l1-m6-l2
title: Return values, defaults and keyword arguments
minutes: 15
concepts: [function-args]
objectives:
- Give parameters default values
- Call functions with keyword arguments
- Return several values as a tuple or dict
---

## Learn
**Defaults** make a parameter optional:

```python example
def provisional_invoice(tonnes, price, premium, pct=0.9):
    return round(pct * tonnes * (price + premium), 2)

print(provisional_invoice(2000, 2812, 248))            # 90%
print(provisional_invoice(2000, 2812, 248, pct=1.0))   # 100% for this contract
```

**Keyword arguments** name the parameter at the call: `provisional_invoice(tonnes=2000, price=2812, premium=248)`. They're clearer than positional arguments when there are several numbers in a row, because you can't swap price and premium by accident.

**Return several values** as a tuple and unpack them, or as a dict when there are many:

```python example
def final_balance(final_value, provisional_paid):
    balance = round(final_value - provisional_paid, 2)
    note = "debit note" if balance > 0 else "credit note"
    return balance, note

amount, doc = final_balance(6_197_348.50, 5_508_000)
print(amount, doc)
```

Defaults must come after non-defaults in the `def` line. Never use a mutable default like `def f(x=[])`: the same list is shared across calls.

## Desk
Contracts differ in small parameters: provisional %, rounding, which price is the provisional basis. Defaults capture the house standard (90%) while letting one call override it for the one counterparty with a 95% clause. And the final invoice always produces two things, an amount and a document type: debit note if the buyer owes more, credit note if you owe them.

## Exercise
Write:

- `provisional_invoice(tonnes, price, premium, pct=0.9)` → amount rounded to 2 decimals
- `final_settlement(final_tonnes, qp_avg, premium, provisional_paid)` → a **tuple** `(balance, note)`, where the final value is tonnes × (QP average + premium), balance = final value − provisional paid (rounded to 2 decimals), and note is `"debit note"` if balance > 0, `"credit note"` if < 0, `"nil"` if exactly 0.

```python starter
def provisional_invoice(tonnes, price, premium):
    pass


```

```python solution
def provisional_invoice(tonnes, price, premium, pct=0.9):
    return round(pct * tonnes * (price + premium), 2)


def final_settlement(final_tonnes, qp_avg, premium, provisional_paid):
    balance = round(final_tonnes * (qp_avg + premium) - provisional_paid, 2)
    if balance > 0:
        note = "debit note"
    elif balance < 0:
        note = "credit note"
    else:
        note = "nil"
    return balance, note
```

```python test "default 90%"
assert provisional_invoice(2000, 2812, 248) == 5508000.0, f"provisional_invoice(2000, 2812, 248) returned {provisional_invoice(2000, 2812, 248)}; expected 90% x 2,000 x 3,060 = 5,508,000."
```

```python test "pct override, by keyword"
assert provisional_invoice(2000, 2812, 248, pct=0.95) == 5814000.0, "With pct=0.95 the result should be 5,814,000. Add pct=0.9 as a default parameter."
assert provisional_invoice(tonnes=500, premium=190, price=2905.5) == 1392975.0, "Keyword arguments in any order should work: expected 1,392,975."
```

```python test "debit note"
r = final_settlement(1998.5, 2853.0, 248, 5_508_000)
assert isinstance(r, tuple) and len(r) == 2, f"final_settlement should return a tuple (balance, note), got {r!r}."
assert r == (689348.5, "debit note"), f"Got {r}; expected (689348.5, 'debit note'): 1,998.5 x 3,101 - 5,508,000."
```

```python test "credit note and nil"
assert final_settlement(1990, 2500.0, 248, 5_508_000)[1] == "credit note", "1,990 t x (2,500 + 248) = 5,468,520 is less than the 5,508,000 paid, so the note is 'credit note'."
assert final_settlement(1000, 2752.0, 248, 3_000_000) == (0.0, "nil"), "A zero balance should give (0.0, 'nil')."
```

### Hint 1
Add `pct=0.9` to the end of the parameter list and use `pct` instead of `0.9` in the formula.

### Hint 2
Compute the balance, then use `if / elif / else` to pick the note, then `return balance, note`.

### Hint 3
```python
def final_settlement(final_tonnes, qp_avg, premium, provisional_paid):
    balance = round(final_tonnes * (qp_avg + premium) - provisional_paid, 2)
    if balance > 0:
        note = "debit note"
    elif ...
    return balance, note
```

## Cards

### Card recall
concept: function-args
Q: Why prefer `f(price=2812, premium=248)` over `f(2812, 248)` in pricing code?
A: Keyword arguments make the call self-documenting and stop you silently swapping two numbers of the same type.

### Card code
concept: function-args
Q: Write `fx(amount, rate=83.25)` returning amount × rate.
```python starter
```
```python solution
def fx(amount, rate=83.25):
    return amount * rate
```
```python test "fx"
assert fx(100) == 8325.0 and fx(100, rate=84) == 8400, "fx(100) should use the default 83.25; fx(100, rate=84) should give 8400."
```

## Next
A weight list from the warehouse contains "n/a", "1,998.725 t" and blanks. Your code shouldn't crash on any of them.
