---
id: l1-m1-l1
title: "Variables: naming the numbers on an invoice"
minutes: 12
concepts: [variables]
objectives:
- Create variables with clear, desk-style names
- Combine them with + - * / to price a cargo
- Reassign a variable when a number changes
---

## Learn
A variable is a label stuck on a value. `=` means "store the right-hand side under this name", not "equals".

```python example
tonnes = 2000
lme_cash = 2812.50      # USD/t, LME official cash settlement
premium = 245           # USD/t, agreed with the counterparty
price_per_t = lme_cash + premium
invoice_value = tonnes * price_per_t
print(invoice_value)
```

Rules for names: letters, digits and `_`; can't start with a digit; case matters (`Tonnes` ≠ `tonnes`). Use `snake_case` and include the unit when it isn't obvious: `freight_usd_t`, `qp_days`.

A variable can be **reassigned**. The new value replaces the old one, and later lines use the new value:

```python example
premium = 245
premium = premium + 10   # sales renegotiated +$10/t
print(premium)
```

Lines run top to bottom. If you change `premium` *after* computing `price_per_t`, `price_per_t` does not update by itself.

## Desk
Every desk spreadsheet is a set of named cells: LME, premium, tonnes, FX. Python variables are the same idea, written down. The habit that matters is naming: `p2` is unreadable in an audit, while `premium_usd_t` explains itself to the controller checking your invoice.

## Exercise
A provisional invoice for **Rheinwerk Galvanik**: **2,000 t** of SHG zinc at LME cash **2,810** plus a **245** USD/t premium. The provisional invoice is for **90%** of the value.

Create:

- `tonnes`, `lme_cash`, `premium`
- `price_per_t`: LME + premium
- `gross_value`: tonnes × price per tonne
- `provisional_invoice`: 90% of the gross value

```python starter
# Rheinwerk provisional invoice
tonnes = 2000

```

```python solution
tonnes = 2000
lme_cash = 2810
premium = 245
price_per_t = lme_cash + premium
gross_value = tonnes * price_per_t
provisional_invoice = 0.90 * gross_value
print(provisional_invoice)
```

```python test "price_per_t = 3,055"
assert price_per_t == 3055, f"price_per_t is {price_per_t}; expected 2,810 + 245 = 3,055."
```

```python test "gross_value = 6,110,000"
assert gross_value == 6110000, f"gross_value is {gross_value:,}; expected 2,000 t x 3,055 = 6,110,000."
```

```python test "provisional_invoice = 5,499,000"
assert approx(provisional_invoice, 5499000), f"provisional_invoice is {provisional_invoice:,}; expected 90% of 6,110,000 = 5,499,000. 90% is 0.90, not 90."
```

### Hint 1
Write one variable per line, in the order listed. Each later line can use the earlier names.

### Hint 2
Percentages become decimals in code: 90% is `0.90`. Multiplying by `90` gives a number 100× too big.

### Hint 3
```python
price_per_t = lme_cash + premium
gross_value = tonnes * price_per_t
provisional_invoice = ___ * gross_value
```

## Cards

### Card recall
concept: variables
Q: After `premium = 245`, `price = 2810 + premium`, `premium = 260`, what is `price`?
A: `3055`. `price` was computed when that line ran; changing `premium` afterwards doesn't update it.

### Card code
concept: variables
Q: Create `invoice_value` for **750 t** at LME **2,900** plus **180** premium.
```python starter
tonnes = 750
```
```python solution
tonnes = 750
invoice_value = tonnes * (2900 + 180)
```
```python test "invoice_value = 2,310,000"
assert invoice_value == 2310000, f"invoice_value is {invoice_value}; expected 750 x (2,900 + 180) = 2,310,000."
```

## Next
The weight certificate arrives as the text "2,000.450". Python can't multiply text by a price, so how do you turn it into a number?
