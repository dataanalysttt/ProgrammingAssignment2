---
id: l1-m3-boss
type: boss
title: QP average dispute
minutes: 10
timeLimit: 600
concepts: [lists, aggregation, list-slicing, comprehensions]
---

## Scenario
Your desk head, 4:40pm: "The Saigon Galvanized final invoice came out $170k below the estimate we gave them yesterday. Nobody believes the market moved that much. Find out what's wrong before it goes." Ops pulled the M+1 settlements from a spreadsheet, and the list has two problems: one settlement was pasted **twice** in a row, and a holiday was entered as **0.0** instead of being left out. Ten minutes.

## Exercise
Create:

- `clean`: the QP list with the zero removed and the duplicated consecutive entry removed (keep one copy). Keep date order.
- `wrong_avg`: average of the original `raw` list, rounded to 2 decimals
- `correct_avg`: average of `clean`, rounded to 2 decimals
- `invoice_error`: (wrong_avg − correct_avg) × `tonnes`, rounded to 2 decimals (negative means the invoice was understated)

```python starter
raw = [2841.5, 2856.0, 2830.25, 2862.75, 2862.75, 2849.0, 0.0, 2871.5, 2866.25, 2858.0]
tonnes = 600

```

```python solution
raw = [2841.5, 2856.0, 2830.25, 2862.75, 2862.75, 2849.0, 0.0, 2871.5, 2866.25, 2858.0]
tonnes = 600
no_zero = [p for p in raw if p > 0]
clean = [p for i, p in enumerate(no_zero) if i == 0 or p != no_zero[i - 1]]
wrong_avg = round(sum(raw) / len(raw), 2)
correct_avg = round(sum(clean) / len(clean), 2)
invoice_error = round((wrong_avg - correct_avg) * tonnes, 2)
```

```python test "clean list"
assert clean == [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0], f"clean is {clean}; remove 0.0 and one of the two consecutive 2862.75 entries, keeping date order."
```

```python test "wrong_avg = 2,569.80"
assert approx(wrong_avg, 2569.8, 0.006), f"wrong_avg is {wrong_avg}; expected the plain average of raw = 2,569.80."
```

```python test "correct_avg = 2,854.41"
assert approx(correct_avg, 2854.41, 0.006), f"correct_avg is {correct_avg}; expected 22,835.25 / 8 = 2,854.41."
```

```python test "invoice_error = -170,766.00"
assert approx(invoice_error, -170766.0, 0.02), f"invoice_error is {invoice_error}; expected (2,569.80 - 2,854.41) x 600 = -170,766.00 (the zero dragged the average down)."
```
