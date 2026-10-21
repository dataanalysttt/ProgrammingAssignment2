---
id: l1-m5-l4
title: enumerate, zip and range
minutes: 15
concepts: [enumerate-zip]
objectives:
- Number items with enumerate
- Walk two lists in step with zip
- Generate index sequences with range for day-on-day changes
---

## Learn
Three helpers that make loops cleaner and less error-prone:

```python example
dates = ["2026-04-01", "2026-04-02", "2026-04-06"]
prices = [2861.5, 2870.0, 2855.25]

for i, d in enumerate(dates, start=1):     # numbered
    print(i, d)

for d, p in zip(dates, prices):            # in step
    print(d, p)

price_on = dict(zip(dates, prices))        # two lists -> dict
print(price_on["2026-04-02"])

for i in range(1, len(prices)):            # 1, 2 (pairs of neighbours)
    print(dates[i], prices[i] - prices[i - 1])
```

- `enumerate(x, start=1)` gives `(number, item)` pairs.
- `zip(a, b)` gives `(a[0], b[0]), (a[1], b[1]), …` and stops at the shorter list.
- `range(n)` is `0 … n-1`; `range(a, b)` is `a … b-1`; `range(a, b, step)`.

Prefer `zip` over `for i in range(len(a)): a[i], b[i]`: it reads better and can't go out of range.

## Desk
Daily price series, invoice lines and QP calendars are always "this date with that price". Off-by-one errors here produce the classic dispute where a QP average uses the wrong set of days. `zip` and `enumerate` remove most of the chances to get it wrong.

## Exercise
Create:

- `price_on`: dict date → price
- `lines`: numbered strings like `"1. 2026-04-01  2,861.50"` (number, dot, space, date, **two** spaces, price with commas and 2 decimals)
- `daily_changes`: list of day-on-day changes (each price minus the previous one), length 4
- `biggest_drop_date`: the date with the most negative change

```python starter
dates = ["2026-04-01", "2026-04-02", "2026-04-06", "2026-04-07", "2026-04-08"]
prices = [2861.5, 2870.0, 2855.25, 2849.75, 2866.0]

```

```python solution
dates = ["2026-04-01", "2026-04-02", "2026-04-06", "2026-04-07", "2026-04-08"]
prices = [2861.5, 2870.0, 2855.25, 2849.75, 2866.0]
price_on = dict(zip(dates, prices))
lines = [f"{i}. {d}  {p:,.2f}" for i, (d, p) in enumerate(zip(dates, prices), start=1)]
daily_changes = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
worst = min(daily_changes)
biggest_drop_date = dates[daily_changes.index(worst) + 1]
```

```python test "price_on"
assert price_on == {"2026-04-01": 2861.5, "2026-04-02": 2870.0, "2026-04-06": 2855.25, "2026-04-07": 2849.75, "2026-04-08": 2866.0}, f"price_on is {price_on}; use dict(zip(dates, prices))."
```

```python test "numbered lines"
assert lines[0] == "1. 2026-04-01  2,861.50", f"lines[0] is {lines[0]!r}; expected '1. 2026-04-01  2,861.50'."
assert len(lines) == 5 and lines[-1] == "5. 2026-04-08  2,866.00", f"lines[-1] is {(lines[-1] if lines else None)!r}; numbering should start at 1."
```

```python test "daily_changes"
assert daily_changes == [8.5, -14.75, -5.5, 16.25], f"daily_changes is {daily_changes}; each is prices[i] - prices[i-1] for i from 1."
```

```python test "biggest drop"
assert biggest_drop_date == "2026-04-06", f"biggest_drop_date is {biggest_drop_date!r}; the -14.75 move happened ON 2026-04-06 (change i belongs to dates[i+1])."
```

### Hint 1
`dict(zip(...))`, an `enumerate(..., start=1)` loop or comprehension, and a `range(1, len(prices))` loop.

### Hint 2
`daily_changes[0]` is the move from day 1 to day 2, so change number `k` belongs to `dates[k + 1]`. `lst.index(value)` finds the position of a value.

### Hint 3
```python
lines = []
for i, (d, p) in enumerate(zip(dates, prices), start=1):
    lines.append(f"{i}. {d}  {p:,.2f}")
daily_changes = [prices[i] - prices[i - 1] for i in range(1, len(prices))]
biggest_drop_date = dates[daily_changes.index(min(daily_changes)) + ___]
```

## Cards

### Card recall
concept: enumerate-zip
Q: What does `list(zip(["a", "b", "c"], [1, 2]))` return?
A: `[("a", 1), ("b", 2)]`. zip stops at the shorter list.

### Card code
concept: enumerate-zip
Q: Set `total` to the sum of tonnes × price, using zip on the two lists.
```python starter
tonnes = [500, 250]
prices = [3125, 3070]
```
```python solution
tonnes = [500, 250]
prices = [3125, 3070]
total = sum(t * p for t, p in zip(tonnes, prices))
```
```python test "total"
assert total == 2330000, f"total is {total}; expected 2,330,000."
```

## Next
Boss battle: two buyers, one warehouse, a held lot, and logistics wants the allocation sheet before the trucks arrive.
