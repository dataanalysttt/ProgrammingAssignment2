---
id: l1-m4-l2
title: "A trade book: lists of dicts"
minutes: 15
concepts: [list-of-dicts]
objectives:
- Represent a trade book as a list of dicts
- Loop over trades with a for statement
- Compute totals and a tonnage-weighted average premium
---

## Learn
Put many trade dicts in a list and you have a table: each dict is a row, each key a column.

```python example
book = [
    {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "premium": 245},
    {"id": "ZS-00413", "counterparty": "Gulf Coil Coating", "tonnes": 250, "premium": 190},
]
print(book[1]["counterparty"])
```

You've used `for` inside comprehensions. The **statement** form runs a block of code once per item. The indented lines are the block:

```python example
book = [{"tonnes": 500, "premium": 245}, {"tonnes": 250, "premium": 190}]
total = 0
for trade in book:
    total = total + trade["tonnes"]
print(total)
```

The pattern *start at 0, add each row* is an **accumulator**. Module 5 covers loops in depth.

**Weighted average.** The average premium across a book must be weighted by tonnes: a 1,000 t lot at 242 matters more than a 250 t lot at 190.

`weighted_avg = Σ(tonnes × premium) / Σ tonnes`

A comprehension can do it in two lines: `sum(t["tonnes"] * t["premium"] for t in book) / sum(t["tonnes"] for t in book)`.

## Desk
"What's our average premium this month?" is one of the most common questions on a physical desk, and the unweighted answer is wrong every time lot sizes differ. Management compares it with published premium assessments, so getting the weighting right affects how your sales performance is judged.

## Exercise
Using `book`, create:

- `total_tonnes`
- `simple_avg_premium`: plain average of the premiums, rounded to 2 decimals
- `weighted_avg_premium`: tonnage-weighted, rounded to 2 decimals
- `ids_over_400`: list of trade ids with more than 400 t, in book order

```python starter
book = [
    {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "month": "2026-03", "premium": 245},
    {"id": "ZS-00413", "counterparty": "Gulf Coil Coating", "tonnes": 250, "incoterm": "CFR", "month": "2026-03", "premium": 190},
    {"id": "ZS-00414", "counterparty": "Rheinwerk Galvanik", "tonnes": 1000, "incoterm": "DAP", "month": "2026-04", "premium": 242},
    {"id": "ZS-00415", "counterparty": "Saigon Galvanized", "tonnes": 750, "incoterm": "CFR", "month": "2026-04", "premium": 145},
    {"id": "ZS-00416", "counterparty": "Atlas Galvanisation", "tonnes": 400, "incoterm": "CIF", "month": "2026-03", "premium": 215},
    {"id": "ZS-00417", "counterparty": "Gulf Coil Coating", "tonnes": 300, "incoterm": "CFR", "month": "2026-04", "premium": 192},
]

```

```python solution
book = [
    {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "month": "2026-03", "premium": 245},
    {"id": "ZS-00413", "counterparty": "Gulf Coil Coating", "tonnes": 250, "incoterm": "CFR", "month": "2026-03", "premium": 190},
    {"id": "ZS-00414", "counterparty": "Rheinwerk Galvanik", "tonnes": 1000, "incoterm": "DAP", "month": "2026-04", "premium": 242},
    {"id": "ZS-00415", "counterparty": "Saigon Galvanized", "tonnes": 750, "incoterm": "CFR", "month": "2026-04", "premium": 145},
    {"id": "ZS-00416", "counterparty": "Atlas Galvanisation", "tonnes": 400, "incoterm": "CIF", "month": "2026-03", "premium": 215},
    {"id": "ZS-00417", "counterparty": "Gulf Coil Coating", "tonnes": 300, "incoterm": "CFR", "month": "2026-04", "premium": 192},
]
total_tonnes = 0
weighted_sum = 0
for t in book:
    total_tonnes += t["tonnes"]
    weighted_sum += t["tonnes"] * t["premium"]
simple_avg_premium = round(sum(t["premium"] for t in book) / len(book), 2)
weighted_avg_premium = round(weighted_sum / total_tonnes, 2)
ids_over_400 = [t["id"] for t in book if t["tonnes"] > 400]
```

```python test "total_tonnes = 3,200"
assert total_tonnes == 3200, f"total_tonnes is {total_tonnes}; expected 3,200."
```

```python test "simple average = 204.83"
assert approx(simple_avg_premium, 204.83, 0.006), f"simple_avg_premium is {simple_avg_premium}; expected 1,229 / 6 = 204.83."
```

```python test "weighted average = 207.61"
assert approx(weighted_avg_premium, 207.61, 0.006), f"weighted_avg_premium is {weighted_avg_premium}; expected sum(tonnes x premium) / sum(tonnes) = 664,350 / 3,200 = 207.61."
```

```python test "ids_over_400"
assert ids_over_400 == ["ZS-00412", "ZS-00414", "ZS-00415"], f"ids_over_400 is {ids_over_400}; more than 400 t means 400 itself is excluded."
```

### Hint 1
Each trade is `t`; its tonnes are `t["tonnes"]`. Use an accumulator loop or `sum(...)` with a comprehension.

### Hint 2
Weighted average: add up `tonnes * premium` for every trade, then divide by total tonnes.

### Hint 3
```python
weighted_sum = 0
for t in book:
    weighted_sum += t["tonnes"] * t["premium"]
weighted_avg_premium = round(weighted_sum / total_tonnes, 2)
ids_over_400 = [t["id"] for t in book if t["tonnes"] ___ 400]
```

## Cards

### Card recall
concept: list-of-dicts
Q: Formula for the tonnage-weighted average premium of a book?
A: Σ(tonnes × premium) ÷ Σ tonnes.

### Card code
concept: list-of-dicts
Q: Set `total` to the total tonnes in `book` (any method).
```python starter
book = [{"tonnes": 500}, {"tonnes": 250}, {"tonnes": 1000}]
```
```python solution
book = [{"tonnes": 500}, {"tonnes": 250}, {"tonnes": 1000}]
total = sum(t["tonnes"] for t in book)
```
```python test "total = 1750"
assert total == 1750, f"total is {total}; expected 1,750."
```

## Next
Credit asks for tonnes by counterparty, and logistics for tonnes by Incoterm. Same pattern, one dictionary each.
