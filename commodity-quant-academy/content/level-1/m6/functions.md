---
id: l1-m6-l1
title: Defining functions
minutes: 15
concepts: [functions]
objectives:
- Define functions with def, parameters and return
- Call them with different inputs
- Tell print from return
---

## Learn
A **function** packages a calculation so you can reuse it with different inputs:

```python example
def invoice_value(tonnes, lme, premium):
    return tonnes * (lme + premium)

print(invoice_value(2000, 2810, 245))
print(invoice_value(500, 2905.5, 190))
```

- `def name(parameters):` starts the definition; the indented block is the body.
- `return` sends a value back to the caller and ends the function.
- Calling `invoice_value(2000, 2810, 245)` fills the parameters in order.
- Variables created inside a function are **local**: they disappear when it returns.

**`print` vs `return`:** `print` shows a value on screen; `return` hands it back so other code can use it. A function without `return` returns `None`, so `x = f()` gives `x = None` even if `f` printed something. Tests (and other code) can only use what you return.

Name functions with verbs or what they produce: `qp_average`, `to_eur`, `provisional_invoice`.

## Desk
Desk spreadsheets copy the same formula into 500 cells, and one cell that was edited by hand breaks the month-end. A function is one formula, defined once, tested once, used everywhere. That's why every CV project in this course is built from small, tested functions.

## Exercise
Write three functions:

- `invoice_value(tonnes, lme, premium)` → tonnes × (lme + premium)
- `qp_average(prices)` → the mean of a list, rounded to 2 decimals
- `to_eur(usd, eurusd)` → USD converted to EUR (EUR/USD is USD per 1 EUR), rounded to 2 decimals

They must **return** values, not print them.

```python starter
def invoice_value(tonnes, lme, premium):
    pass


```

```python solution
def invoice_value(tonnes, lme, premium):
    return tonnes * (lme + premium)


def qp_average(prices):
    return round(sum(prices) / len(prices), 2)


def to_eur(usd, eurusd):
    return round(usd / eurusd, 2)
```

```python test "invoice_value"
assert invoice_value(2000, 2810, 245) == 6110000, f"invoice_value(2000, 2810, 245) returned {invoice_value(2000, 2810, 245)}; expected 6,110,000. Use return, not print."
assert invoice_value(500, 2905.5, 190) == 1547750, "invoice_value(500, 2905.5, 190) should be 1,547,750."
```

```python test "qp_average"
assert qp_average([2850, 2861, 2839, 2870, 2845]) == 2853.0, f"qp_average returned {qp_average([2850, 2861, 2839, 2870, 2845])}; expected 2853.0."
assert qp_average([2801.0, 2815.5, 2790.25, 2808.0]) == 2803.69, "qp_average([2801.0, 2815.5, 2790.25, 2808.0]) should be 2803.69 (rounded to 2 decimals)."
```

```python test "to_eur"
assert to_eur(1_250_000, 1.085) == 1152073.73, f"to_eur(1250000, 1.085) returned {to_eur(1_250_000, 1.085)}; expected 1,152,073.73. Divide by EUR/USD."
```

### Hint 1
Each function is two lines: `def ...:` and a `return ...` line indented by 4 spaces.

### Hint 2
`pass` does nothing and returns `None`. Replace it with `return <expression>`. Parameters are just variables you can use in the body.

### Hint 3
```python
def qp_average(prices):
    return round(sum(prices) / len(prices), 2)


def to_eur(usd, eurusd):
    return round(___, 2)
```

## Cards

### Card recall
concept: functions
Q: A function prints its result but has no `return`. What does `x = f()` store in `x`?
A: `None`. Printing shows the value but doesn't hand it back to the caller.

### Card code
concept: functions
Q: Write `premium_total(tonnes, premium)` returning tonnes × premium.
```python starter
```
```python solution
def premium_total(tonnes, premium):
    return tonnes * premium
```
```python test "premium_total"
assert premium_total(500, 245) == 122500 and premium_total(250, 190) == 47500, "premium_total(500, 245) should return 122,500."
```

## Next
Most provisional invoices are 90%, but some contracts say 95% or 100%. One default argument covers all of them.
