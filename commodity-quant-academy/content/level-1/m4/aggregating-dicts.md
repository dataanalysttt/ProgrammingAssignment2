---
id: l1-m4-l3
title: "Grouping with dicts: tonnes by counterparty"
minutes: 15
concepts: [grouping]
objectives:
- Group and sum with a dict accumulator
- Use .get(key, 0) to start new groups
- Find the largest group
---

## Learn
To total tonnes **per counterparty**, use a dict whose keys are counterparties and whose values are running totals:

```python example
book = [
    {"counterparty": "Rheinwerk", "tonnes": 500},
    {"counterparty": "Gulf Coil", "tonnes": 250},
    {"counterparty": "Rheinwerk", "tonnes": 1000},
]
by_cp = {}
for t in book:
    cp = t["counterparty"]
    by_cp[cp] = by_cp.get(cp, 0) + t["tonnes"]
print(by_cp)
```

`by_cp.get(cp, 0)` returns the running total, or `0` the first time a counterparty appears. This group-and-sum pattern is what SQL `GROUP BY` and pandas `groupby` (Level 2) do for you.

To find the biggest group: `max(by_cp, key=by_cp.get)` returns the **key** with the largest value. Loop over pairs with `.items()`:

```python example
by_cp = {"Rheinwerk": 1500, "Gulf Coil": 250}
for cp, tonnes in by_cp.items():
    print(f"{cp:<12}{tonnes:>8,} t")
```

## Desk
Concentration is a risk in its own right. If one counterparty takes 45% of a month's tonnage, a payment delay or a quality claim from them hits the whole book. Tonnes by counterparty, by Incoterm and by month are the first three cuts any risk report asks for.

## Exercise
From `book`, build three dicts and two summary values:

- `by_counterparty`, `by_incoterm`, `by_month`: total tonnes per key
- `largest_cp`: the counterparty with the most tonnes
- `largest_share`: that counterparty's share of total tonnes, rounded to 4 decimals

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
by_counterparty, by_incoterm, by_month = {}, {}, {}
for t in book:
    by_counterparty[t["counterparty"]] = by_counterparty.get(t["counterparty"], 0) + t["tonnes"]
    by_incoterm[t["incoterm"]] = by_incoterm.get(t["incoterm"], 0) + t["tonnes"]
    by_month[t["month"]] = by_month.get(t["month"], 0) + t["tonnes"]
largest_cp = max(by_counterparty, key=by_counterparty.get)
largest_share = round(by_counterparty[largest_cp] / sum(by_counterparty.values()), 4)
```

```python test "by_counterparty"
assert by_counterparty == {"Rheinwerk Galvanik": 1500, "Gulf Coil Coating": 550, "Saigon Galvanized": 750, "Atlas Galvanisation": 400}, f"by_counterparty is {by_counterparty}."
```

```python test "by_incoterm and by_month"
assert by_incoterm == {"DAP": 1500, "CFR": 1300, "CIF": 400}, f"by_incoterm is {by_incoterm}."
assert by_month == {"2026-03": 1150, "2026-04": 2050}, f"by_month is {by_month}."
```

```python test "largest counterparty"
assert largest_cp == "Rheinwerk Galvanik", f"largest_cp is {largest_cp!r}; use max(by_counterparty, key=by_counterparty.get)."
assert approx(largest_share, 0.4688, 1e-6), f"largest_share is {largest_share}; expected 1,500 / 3,200 = 0.4688."
```

### Hint 1
One loop over `book` can update all three dicts.

### Hint 2
`d[k] = d.get(k, 0) + amount` adds to an existing total or starts a new one at 0.

### Hint 3
```python
by_counterparty = {}
for t in book:
    cp = t["counterparty"]
    by_counterparty[cp] = by_counterparty.get(cp, 0) + t["tonnes"]
largest_cp = max(by_counterparty, key=by_counterparty.get)
```

## Cards

### Card recall
concept: grouping
Q: Write the one line that adds `t["tonnes"]` to a running total per counterparty in dict `by_cp`.
A: `by_cp[t["counterparty"]] = by_cp.get(t["counterparty"], 0) + t["tonnes"]`

### Card code
concept: grouping
Q: Build `count` mapping each Incoterm in `terms` to how many times it appears.
```python starter
terms = ["CFR", "DAP", "CFR", "CIF", "CFR"]
```
```python solution
terms = ["CFR", "DAP", "CFR", "CIF", "CFR"]
count = {}
for x in terms:
    count[x] = count.get(x, 0) + 1
```
```python test "count"
assert count == {"CFR": 3, "DAP": 1, "CIF": 1}, f"count is {count}."
```

## Next
Boss battle: month-end. Risk wants the value of the book by shipment month, now.
