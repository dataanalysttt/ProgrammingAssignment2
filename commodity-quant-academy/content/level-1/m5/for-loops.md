---
id: l1-m5-l2
title: for loops over a trade book
minutes: 15
concepts: [for-loops]
objectives:
- Loop over a list and do work per item
- Build results with accumulators, lists and dicts
- Track the "best so far" inside a loop
---

## Learn
A `for` loop runs its block once for each item:

```python example
trades = [{"id": "ZS-00501", "tonnes": 500, "premium": 245},
          {"id": "ZS-00502", "tonnes": 250, "premium": 190}]
lme = 2880
for t in trades:
    prov = 0.9 * t["tonnes"] * (lme + t["premium"])
    print(t["id"], f"{prov:,.2f}")
```

Patterns you'll reuse forever:

- **Accumulator:** `total = 0` before the loop, `total += x` inside.
- **Collector:** `out = []` before, `out.append(...)` inside.
- **Mapping:** `d = {}` before, `d[key] = value` inside.
- **Best so far:** start with the first item (or `None`) and replace it when you see something bigger.
- **Running total:** append the accumulator after each step to get cumulative values.

`x += y` is short for `x = x + y`.

## Desk
Every batch job on a desk (month-end provisional invoicing, daily MTM, exposure reports) is a loop over trades. The four patterns above cover most of them. Writing them by hand once makes the pandas versions in Level 2 easy to read and to check.

## Exercise
For each trade at `lme = 2880`, the provisional invoice is **90% × tonnes × (LME + premium)**. Using one `for` loop, create:

- `provisional_by_id`: dict id → provisional amount, rounded to 2 decimals
- `total_provisional`: sum of all provisional amounts
- `running_total`: list of the cumulative total after each trade
- `biggest_id`: id of the largest provisional invoice (track it inside the loop)

```python starter
lme = 2880
trades = [
    {"id": "ZS-00501", "tonnes": 500, "premium": 245},
    {"id": "ZS-00502", "tonnes": 250, "premium": 190},
    {"id": "ZS-00503", "tonnes": 1000, "premium": 242},
    {"id": "ZS-00504", "tonnes": 750, "premium": 145},
]

```

```python solution
lme = 2880
trades = [
    {"id": "ZS-00501", "tonnes": 500, "premium": 245},
    {"id": "ZS-00502", "tonnes": 250, "premium": 190},
    {"id": "ZS-00503", "tonnes": 1000, "premium": 242},
    {"id": "ZS-00504", "tonnes": 750, "premium": 145},
]
provisional_by_id = {}
total_provisional = 0
running_total = []
biggest_id, biggest = None, 0
for t in trades:
    prov = round(0.9 * t["tonnes"] * (lme + t["premium"]), 2)
    provisional_by_id[t["id"]] = prov
    total_provisional += prov
    running_total.append(total_provisional)
    if prov > biggest:
        biggest_id, biggest = t["id"], prov
```

```python test "provisional_by_id"
exp = {"ZS-00501": 1406250.0, "ZS-00502": 690750.0, "ZS-00503": 2809800.0, "ZS-00504": 2041875.0}
assert provisional_by_id == exp, f"provisional_by_id is {provisional_by_id}; e.g. ZS-00501 = 0.9 x 500 x (2,880 + 245) = 1,406,250."
```

```python test "total = 6,948,675"
assert approx(total_provisional, 6948675), f"total_provisional is {total_provisional}; expected 6,948,675."
```

```python test "running_total"
assert [round(x) for x in running_total] == [1406250, 2097000, 4906800, 6948675], f"running_total is {running_total}; append the total after adding each trade."
```

```python test "biggest_id"
assert biggest_id == "ZS-00503", f"biggest_id is {biggest_id!r}; ZS-00503 (2,809,800) is the largest."
```

### Hint 1
Set up four empty results before the loop (`{}`, `0`, `[]`, `None`), then update all of them inside it.

### Hint 2
The running total is the accumulator's value after each addition: `running_total.append(total_provisional)`. For the biggest, keep two variables (`biggest_id`, `biggest`) and update both when `prov > biggest`.

### Hint 3
```python
for t in trades:
    prov = round(0.9 * t["tonnes"] * (lme + t["premium"]), 2)
    provisional_by_id[t["id"]] = prov
    total_provisional += prov
    running_total.append(total_provisional)
    if prov > biggest:
        ...
```

## Cards

### Card recall
concept: for-loops
Q: Name the four loop patterns from this lesson.
A: Accumulator (`total += x`), collector (`out.append(x)`), mapping (`d[k] = v`), best-so-far (`if x > best: best = x`). Plus running totals: append the accumulator each step.

### Card code
concept: for-loops
Q: With a loop, set `total` to the sum of `t * p` over the pairs in `lots`.
```python starter
lots = [(500, 3125), (250, 3070)]
```
```python solution
lots = [(500, 3125), (250, 3070)]
total = 0
for t, p in lots:
    total += t * p
```
```python test "total"
assert total == 2330000, f"total is {total}; expected 500 x 3125 + 250 x 3070 = 2,330,000."
```

## Next
The warehouse has lots of about 400 t, one of them quality-rejected. Allocate exactly enough to fill a 2,000 t order and stop.
