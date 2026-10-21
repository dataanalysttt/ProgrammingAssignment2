---
id: l1-m1-l2
title: "Types: int, float, str and bool"
minutes: 15
concepts: [types]
objectives:
- Tell int, float, str and bool apart with type()
- Convert text from documents into numbers with float() and int()
- Clean "2,000.450"-style strings before converting
---

## Learn
Every value has a **type**:

| Type | Example | Use on a desk |
|---|---|---|
| `int` | `2000` | lot counts, days in a QP |
| `float` | `2812.5` | prices, tonnes with decimals, FX |
| `str` | `"DAP"` | counterparty names, Incoterms, refs |
| `bool` | `True` | flags: priced? hedged? |

```python example
print(type(2000), type(2812.5), type("DAP"), type(True))
```

Data from emails, PDFs and spreadsheets often arrives as **text**. `"2000" * 2` is `"20002000"`, not 4000. Convert first:

```python example
weight_text = "2,000.450"
weight = float(weight_text.replace(",", ""))   # remove the thousands separator first
print(weight * 2)
```

- `float("2812.5")` → `2812.5`. `int("12")` → `12`. `int("12.5")` fails; use `float` first.
- `str(2000)` → `"2000"` (for building text).
- Comparisons give a `bool`: `2812.5 > 2800` is `True`.

## Desk
Most "wrong invoice" incidents come from data types: a weight pasted as text, a price with a stray comma, `"2.000"` read with European decimals. Knowing which type you're holding is the first check before any number goes on an invoice.

## Exercise
The weight certificate for a Nordhavn lot was pasted from a PDF as text. Create:

- `net_weight`: a **float** from `weight_text` (strip the comma first)
- `price`: a float from `price_text`
- `value`: `net_weight * price`
- `is_large_lot`: a **bool**, `True` when `net_weight` is more than 1,000 t

```python starter
weight_text = "1,998.725"
price_text = "3047.50"

```

```python solution
weight_text = "1,998.725"
price_text = "3047.50"
net_weight = float(weight_text.replace(",", ""))
price = float(price_text)
value = net_weight * price
is_large_lot = net_weight > 1000
```

```python test "net_weight is the float 1998.725"
assert isinstance(net_weight, float), f"net_weight is a {type(net_weight).__name__}; convert it with float()."
assert approx(net_weight, 1998.725, 1e-9), f"net_weight is {net_weight}; expected 1998.725."
```

```python test "price is a float"
assert isinstance(price, float) and approx(price, 3047.5, 1e-9), f"price should be the float 3047.5, got {price!r}."
```

```python test "value = 6,091,114.44"
assert approx(value, 6091114.4375, 0.01), f"value is {value}; expected 1,998.725 x 3,047.50 = 6,091,114.44."
```

```python test "is_large_lot is a bool"
assert is_large_lot is True, f"is_large_lot is {is_large_lot!r}; it should be the comparison net_weight > 1000, which is True."
```

### Hint 1
`float("1,998.725")` fails because of the comma. Remove it first.

### Hint 2
Strings have a `.replace(old, new)` method: `"1,998".replace(",", "")` gives `"1998"`. A comparison like `a > b` already produces `True` or `False`.

### Hint 3
```python
net_weight = float(weight_text.replace(",", ""))
price = float(price_text)
is_large_lot = net_weight > ___
```

## Cards

### Card recall
concept: types
Q: What does `"500" * 2` give, and why?
A: `"500500"`. It's a string, and `*` on a string repeats it. Convert with `int()` or `float()` first.

### Card code
concept: types
Q: Convert `qty = "12,500"` (tonnes, text) into an int `tonnes`.
```python starter
qty = "12,500"
```
```python solution
qty = "12,500"
tonnes = int(qty.replace(",", ""))
```
```python test "tonnes = 12500 (int)"
assert tonnes == 12500 and isinstance(tonnes, int), f"tonnes is {tonnes!r}; expected the int 12500. Remove the comma, then int()."
```

## Next
0.1 + 0.2 isn't exactly 0.3 in Python. That matters when an invoice is off by a cent and the counterparty's AP team rejects it.
