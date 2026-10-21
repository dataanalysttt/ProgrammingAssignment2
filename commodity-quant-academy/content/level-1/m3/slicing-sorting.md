---
id: l1-m3-l3
title: Slicing and sorting
minutes: 12
concepts: [list-slicing]
objectives:
- Slice lists the same way as strings
- Sort with sorted() and list.sort(), ascending and descending
- Take the top or bottom N values
---

## Learn
Lists slice exactly like strings: `lst[start:stop]`, stop excluded.

```python example
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
first_week = qp[:5]
last_week = qp[-5:]
print(first_week, last_week)
```

Sorting:

- `sorted(lst)` returns a **new** sorted list; the original keeps its order. Use it when the order matters (QP prices are in date order!).
- `lst.sort()` sorts **in place** and returns `None`. `x = lst.sort()` is a classic bug: `x` becomes `None`.
- `reverse=True` sorts descending.

```python example
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0]
top3 = sorted(qp, reverse=True)[:3]
print(top3, qp)    # qp unchanged
```

## Desk
Desk questions are usually "top N": biggest lots, highest settlements, largest exposures. And comparing the start and end of a QP (did the market trend through the month?) tells you whether averaging helped or hurt the counterparty, which comes up in every price negotiation.

## Exercise
From `qp` (in date order) and `lots` (tonnes of this month's open sales), create:

- `first5_avg` and `last5_avg`: averages of the first and last 5 settlements, each rounded to 2 decimals
- `trend`: `last5_avg - first5_avg`, rounded to 2 decimals
- `top3_prices`: the three highest settlements, highest first
- `biggest_lots_total`: the sum of the three biggest lots
- `qp` must still be in its original date order at the end

```python starter
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
lots = [500, 250, 1000, 150, 750, 400, 300]

```

```python solution
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
lots = [500, 250, 1000, 150, 750, 400, 300]
first5_avg = round(sum(qp[:5]) / 5, 2)
last5_avg = round(sum(qp[-5:]) / 5, 2)
trend = round(last5_avg - first5_avg, 2)
top3_prices = sorted(qp, reverse=True)[:3]
biggest_lots_total = sum(sorted(lots, reverse=True)[:3])
```

```python test "first and last week averages"
assert approx(first5_avg, 2847.9, 0.006), f"first5_avg is {first5_avg}; expected mean of qp[:5] = 2,847.90."
assert approx(last5_avg, 2870.4, 0.006), f"last5_avg is {last5_avg}; expected mean of qp[-5:] = 2,870.40."
```

```python test "trend = +22.50"
assert approx(trend, 22.5, 0.006), f"trend is {trend}; expected 2,870.40 - 2,847.90 = 22.50."
```

```python test "top3_prices"
assert top3_prices == [2880.75, 2875.5, 2871.5], f"top3_prices is {top3_prices}; expected [2880.75, 2875.5, 2871.5] (sorted descending, first three)."
```

```python test "biggest lots"
assert biggest_lots_total == 2250, f"biggest_lots_total is {biggest_lots_total}; expected 1,000 + 750 + 500 = 2,250."
```

```python test "qp still in date order"
assert qp == [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5], "qp was re-ordered. Use sorted(qp), which returns a copy, not qp.sort()."
```

### Hint 1
Slices for the weeks, `sorted(..., reverse=True)` for the top values.

### Hint 2
`sorted()` leaves the original list alone; `.sort()` changes it. Chain a slice after sorting: `sorted(x, reverse=True)[:3]`.

### Hint 3
```python
first5_avg = round(sum(qp[:5]) / 5, 2)
last5_avg = round(sum(qp[-5:]) / 5, 2)
top3_prices = sorted(qp, reverse=True)[:3]
biggest_lots_total = sum(sorted(lots, reverse=True)[___])
```

## Cards

### Card recall
concept: list-slicing
Q: What's the difference between `sorted(qp)` and `qp.sort()`?
A: `sorted(qp)` returns a new sorted list and leaves `qp` unchanged. `qp.sort()` sorts `qp` in place and returns `None`.

### Card code
concept: list-slicing
Q: Set `top2` to the two largest values in `lots`, largest first.
```python starter
lots = [300, 1200, 450, 800]
```
```python solution
lots = [300, 1200, 450, 800]
top2 = sorted(lots, reverse=True)[:2]
```
```python test "top2"
assert top2 == [1200, 800], f"top2 is {top2}; sort descending and take [:2]."
```

## Next
Convert a whole list of USD prices to EUR in one line, and filter out the small lots in another.
