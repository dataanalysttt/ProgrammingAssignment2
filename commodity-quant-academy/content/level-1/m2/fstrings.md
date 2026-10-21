---
id: l1-m2-l4
title: f-strings and number formatting
minutes: 15
concepts: [fstrings]
objectives:
- Embed variables and expressions in f-strings
- Format money with thousands separators and fixed decimals
- Format percentages and align columns
---

## Learn
An **f-string** has an `f` before the quote and puts expressions inside `{}`:

```python example
buyer, tonnes, price = "Rheinwerk", 2000, 3055
print(f"{buyer}: {tonnes} t @ {price} = {tonnes * price}")
```

Add a **format spec** after a colon:

| Spec | Meaning | `{x:...}` with x = 6110000.456 |
|---|---|---|
| `,.2f` | thousands separator, 2 decimals | `6,110,000.46` |
| `.0f` | no decimals | `6110000` |
| `,.3f` | 3 decimals (tonnes) | `6,110,000.456` |
| `.1%` | percent, 1 decimal | `0.0425` → `4.2%` |
| `>12` | right-align in 12 characters | for tables |
| `+,.2f` | always show the sign | `+1,250.00` / `-300.00` |

```python example
value = 6110000.456
print(f"USD {value:,.2f}")
print(f"{'Rheinwerk':<12}|{2000:>10,.3f} t")
print(f"Margin {0.0425:.1%}")
```

f-strings round for **display only**; the variable keeps full precision.

## Desk
Invoices, recaps and position reports are read by people who sign off money. `6110000.456` invites mistakes; `USD 6,110,000.46` doesn't. Consistent formatting (3 decimals on tonnes, 2 on money, sign on P&L) is the difference between a report management reads and one it forwards back with questions.

## Exercise
Build `invoice_line` exactly in this format (the test compares character by character):

`Rheinwerk Galvanik | 1,998.725 t @ USD 3,055.00 = USD 6,106,104.88`

Tonnes with 3 decimals and commas, price and value with 2 decimals and commas. Also create `variance_text` for the change versus the provisional amount, as `Variance vs provisional: +USD 609,104.88` (sign always shown).

```python starter
buyer = "Rheinwerk Galvanik"
tonnes = 1998.725
price = 3055
value = tonnes * price
provisional = 5_497_000

```

```python solution
buyer = "Rheinwerk Galvanik"
tonnes = 1998.725
price = 3055
value = tonnes * price
provisional = 5_497_000
invoice_line = f"{buyer} | {tonnes:,.3f} t @ USD {price:,.2f} = USD {value:,.2f}"
variance_text = f"Variance vs provisional: {'+' if value - provisional >= 0 else '-'}USD {abs(value - provisional):,.2f}"
```

```python test "invoice_line format"
expected = "Rheinwerk Galvanik | 1,998.725 t @ USD 3,055.00 = USD 6,106,104.88"
assert invoice_line == expected, f"Got      {invoice_line!r}\nExpected {expected!r}\nCompare spacing, commas and decimals: tonnes {{:,.3f}}, money {{:,.2f}}."
```

```python test "variance_text"
expected = "Variance vs provisional: +USD 609,104.88"
assert variance_text == expected, f"Got {variance_text!r}; expected {expected!r}. The sign goes before 'USD'."
```

### Hint 1
Start with `f"{buyer} | {tonnes} t ..."` and add format specs one at a time, running each time.

### Hint 2
`{tonnes:,.3f}` gives `1,998.725`. Money uses `,.2f`. For the variance, the sign sits before `USD`, so work it out separately (`'+' if diff >= 0 else '-'`) and format `abs(diff)`.

### Hint 3
```python
invoice_line = f"{buyer} | {tonnes:,.3f} t @ USD {price:,.2f} = USD {value:___}"
diff = value - provisional
variance_text = f"Variance vs provisional: {'+' if diff >= 0 else '-'}USD {abs(diff):,.2f}"
```

## Cards

### Card recall
concept: fstrings
Q: What does `f"{1234567.891:,.2f}"` produce?
A: `1,234,567.89`

### Card code
concept: fstrings
Q: Set `s` to `"USD 2,310,000.00"` using an f-string on `value`.
```python starter
value = 2310000
```
```python solution
value = 2310000
s = f"USD {value:,.2f}"
```
```python test "s"
assert s == "USD 2,310,000.00", f"s is {s!r}; use the format spec ,.2f."
```

## Next
Boss battle: a contract confirmation went out with the wrong fields. The counterparty is on the phone.
