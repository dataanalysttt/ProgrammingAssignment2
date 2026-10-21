---
id: l1-m3-l2
title: sum, min, max and the QP average
minutes: 15
concepts: [aggregation]
objectives:
- Aggregate lists with sum, len, min and max
- Compute a QP average and a price range
- Estimate a final price from partial QP data
---

## Learn
Built-in functions summarise a whole list:

```python example
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0]
print(sum(qp), len(qp), min(qp), max(qp))
qp_avg = sum(qp) / len(qp)
print(round(qp_avg, 2))
```

The **QP average** is the arithmetic mean of the official settlement prices over the quotational period, typically every LME business day of the agreed month. Days with no publication (holidays) are simply not in the list; they aren't filled.

**Estimating the final price mid-QP.** If `k` of `n` days are fixed with average `a`, and you assume the remaining days settle at today's forward price `f`:

`estimated_final = (k × a + (n − k) × f) / n`

This weighting is why price risk shrinks day by day during a QP: each fixed day is locked in.

`sum([])` is `0` but `len([])` is `0` too, so averaging an empty list divides by zero. Check for that before dividing.

## Desk
QP averages drive the final invoice. "We're 10 days into M+1, fixed at 2,859, so with the market at 2,870 the final lands around 2,865" is exactly the update sales, credit and risk want, and it comes straight from this formula.

## Exercise
For the 22-day M+1 QP, with 10 days fixed (`qp`) and today's forward price `fwd = 2870.0`, create:

- `avg_so_far`: mean of the fixed days, rounded to 2 decimals
- `price_range`: highest minus lowest fixed price
- `estimated_final`: weighted estimate (use the **unrounded** average), rounded to 2 decimals
- `est_final_value`: estimated final price **plus** a premium of 152 USD/t, times 1,500 t, rounded to 2 decimals

```python starter
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
n_days = 22
fwd = 2870.0
premium = 152
tonnes = 1500

```

```python solution
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
n_days = 22
fwd = 2870.0
premium = 152
tonnes = 1500
avg = sum(qp) / len(qp)
avg_so_far = round(avg, 2)
price_range = max(qp) - min(qp)
k = len(qp)
estimated_final = round((k * avg + (n_days - k) * fwd) / n_days, 2)
est_final_value = round((estimated_final + premium) * tonnes, 2)
```

```python test "avg_so_far = 2,859.15"
assert approx(avg_so_far, 2859.15, 1e-6), f"avg_so_far is {avg_so_far}; expected 28,591.5 / 10 = 2,859.15."
```

```python test "price_range = 50.5"
assert approx(price_range, 50.5, 1e-9), f"price_range is {price_range}; expected 2,880.75 - 2,830.25 = 50.5."
```

```python test "estimated_final = 2,865.07"
assert approx(estimated_final, 2865.07, 0.006), f"estimated_final is {estimated_final}; expected (10 x 2,859.15 + 12 x 2,870) / 22 = 2,865.07."
```

```python test "est_final_value = 4,525,605.00"
assert approx(est_final_value, 4525605.0, 0.01), f"est_final_value is {est_final_value}; expected (2,865.07 + 152) x 1,500 = 4,525,605.00."
```

### Hint 1
Average first, then the weighted estimate, then the value. Each depends on the previous one.

### Hint 2
Fixed days: `k = len(qp)`. Days remaining: `n_days - k`. Weighted average = (k × avg + remaining × fwd) / n_days.

### Hint 3
```python
avg = sum(qp) / len(qp)
k = len(qp)
estimated_final = round((k * avg + (n_days - k) * fwd) / n_days, 2)
est_final_value = round((estimated_final + premium) * ___, 2)
```

## Cards

### Card recall
concept: aggregation
Q: 10 of 22 QP days are fixed at an average of 2,859.15 and the forward is 2,870. Write the formula for the estimated final average.
A: `(10 × 2859.15 + 12 × 2870) / 22`, i.e. fixed days weighted by their average, plus remaining days at the forward.

### Card code
concept: aggregation
Q: Set `qp_avg` to the mean of `qp`, rounded to 2 decimals.
```python starter
qp = [2801.0, 2815.5, 2790.25, 2808.0]
```
```python solution
qp = [2801.0, 2815.5, 2790.25, 2808.0]
qp_avg = round(sum(qp) / len(qp), 2)
```
```python test "qp_avg"
assert approx(qp_avg, 2803.69, 0.006), f"qp_avg is {qp_avg}; expected 11,214.75 / 4 = 2,803.69."
```

## Next
Risk asks: what were the three highest settlements this QP, and how did the first week compare with the last?
