---
id: l1-m1-l4
title: Floor division, modulo and powers
minutes: 12
concepts: [operators]
objectives:
- Use // and % for containers and remainders
- Use ** for compounding
- Apply operator precedence correctly
---

## Learn
Three operators you'll use constantly:

| Operator | Meaning | Example |
|---|---|---|
| `//` | floor division (whole part) | `1060 // 25` → `42` |
| `%` | remainder (modulo) | `1060 % 25` → `10` |
| `**` | power | `1.05 ** 2` → `1.1025` |

```python example
tonnes = 1060
per_box = 25
full_boxes = tonnes // per_box
leftover = tonnes % per_box
print(full_boxes, "full boxes and", leftover, "t left over")
```

**Rounding up** a booking: if there's a remainder you need one more box. `full_boxes + (1 if leftover else 0)`, or the trick `-(-tonnes // per_box)`.

**Compounding:** financing a cargo at 6% a year, compounded monthly for 3 months: `value * (1 + 0.06 / 12) ** 3`.

**Precedence:** `**` first, then `* / // %`, then `+ -`. When in doubt, add brackets. They cost nothing and make the formula readable.

## Desk
Logistics thinks in boxes and bookings, finance thinks in compounding. A trader who can turn "1,060 t" into "43 boxes, last one 10 t short" instantly, or estimate carry on a 90-day financing, is the one who spots when a freight quote or a finance charge doesn't add up.

## Exercise
A **1,060 t** order for Saigon Galvanized. Create:

- `full_boxes` and `leftover_t` using `//` and `%` (25 t per box)
- `boxes_to_book`: full boxes plus one more if there's any leftover
- `finance_cost`: interest on a cargo value of **3,250,000** USD financed for **3 months** at **6.5%** a year compounded monthly, i.e. `value * (1 + rate/12) ** months - value`, rounded to 2 decimals

```python starter
tonnes = 1060
per_box = 25
cargo_value = 3_250_000
rate = 0.065
months = 3

```

```python solution
tonnes = 1060
per_box = 25
cargo_value = 3_250_000
rate = 0.065
months = 3
full_boxes = tonnes // per_box
leftover_t = tonnes % per_box
boxes_to_book = full_boxes + (1 if leftover_t > 0 else 0)
finance_cost = round(cargo_value * (1 + rate / 12) ** months - cargo_value, 2)
```

```python test "42 full boxes, 10 t left"
assert full_boxes == 42, f"full_boxes is {full_boxes}; 1060 // 25 = 42."
assert leftover_t == 10, f"leftover_t is {leftover_t}; 1060 % 25 = 10."
```

```python test "book 43 boxes"
assert boxes_to_book == 43, f"boxes_to_book is {boxes_to_book}; 42 full boxes + 1 for the 10 t left over = 43."
```

```python test "finance_cost = 53,099.08"
assert approx(finance_cost, 53099.08, 0.01), f"finance_cost is {finance_cost}; expected 3,250,000 x (1 + 0.065/12)^3 - 3,250,000 = 53,099.08. Check brackets: (1 + rate / 12) ** months."
```

### Hint 1
`//` gives whole boxes, `%` gives what's left. For the finance cost, compute the grown value, then subtract the original.

### Hint 2
`x if condition else y` picks one of two values. `**` binds tighter than `*`, so `value * (1 + r) ** n` raises `(1 + r)` to `n` first.

### Hint 3
```python
boxes_to_book = full_boxes + (1 if leftover_t > 0 else 0)
finance_cost = round(cargo_value * (1 + rate / 12) ** months - ___, 2)
```

## Cards

### Card recall
concept: operators
Q: What are `1060 // 25` and `1060 % 25`?
A: `42` (whole boxes) and `10` (tonnes left over).

### Card code
concept: operators
Q: Set `boxes` to the number of 25 t containers needed for **740 t** (round up).
```python starter
tonnes = 740
```
```python solution
tonnes = 740
boxes = -(-tonnes // 25)
```
```python test "boxes = 30"
assert boxes == 30, f"boxes is {boxes}; 740 / 25 = 29.6, which rounds up to 30."
```

## Next
Boss battle: it's 4:55pm and the freight desk needs a booking and an invoice checked before the cut-off.
