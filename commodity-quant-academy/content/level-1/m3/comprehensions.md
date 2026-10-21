---
id: l1-m3-l4
title: List comprehensions
minutes: 15
concepts: [comprehensions]
objectives:
- Transform every item of a list in one expression
- Filter items with a condition
- Know when a plain loop is clearer
---

## Learn
A **list comprehension** builds a new list from an old one:

`[expression for item in list if condition]`

```python example
prices_usd = [3055.0, 3102.5, 2987.25]
eurusd = 1.0850
prices_eur = [round(p / eurusd, 2) for p in prices_usd]
print(prices_eur)

lots = [100, 150, 200, 250, 300, 400, 500, 750, 1000]
large = [t for t in lots if t >= 500]
print(large, sum(large))
```

Read it left to right as English: "round p / eurusd, **for each** p in prices_usd". The `if` part is optional and filters.

You can transform and filter together: `[t * 1.0 for t in lots if t >= 500]`.

Use a comprehension for one clear transform or filter. If you need several steps, an `if/else` chain or printing along the way, a normal `for` loop (Module 5) is easier to read and to debug.

## Desk
Desk data work is mostly "apply this to every row" (convert currency, add premium) and "keep only these rows" (open trades, large lots, one region). Comprehensions are the plain-Python version of that; pandas in Level 2 does the same thing on whole tables.

## Exercise
Create:

- `prices_eur`: each USD price converted to EUR (divide by `eurusd`), rounded to 2 decimals
- `large_lots`: lots of **500 t or more**
- `large_share`: the share of total tonnage in large lots, as a fraction rounded to 4 decimals
- `with_premium`: each price plus `premium`

```python starter
prices_usd = [3055.0, 3102.5, 2987.25]
eurusd = 1.0850
lots = [100, 150, 200, 250, 300, 400, 500, 750, 1000]
premium = 240

```

```python solution
prices_usd = [3055.0, 3102.5, 2987.25]
eurusd = 1.0850
lots = [100, 150, 200, 250, 300, 400, 500, 750, 1000]
premium = 240
prices_eur = [round(p / eurusd, 2) for p in prices_usd]
large_lots = [t for t in lots if t >= 500]
large_share = round(sum(large_lots) / sum(lots), 4)
with_premium = [p + premium for p in prices_usd]
```

```python test "prices_eur"
assert prices_eur == [2815.67, 2859.45, 2753.23], f"prices_eur is {prices_eur}; expected [2815.67, 2859.45, 2753.23]. Divide by EUR/USD, round each to 2."
```

```python test "large_lots"
assert large_lots == [500, 750, 1000], f"large_lots is {large_lots}; keep t >= 500 (500 itself included)."
```

```python test "large_share = 0.6164"
assert approx(large_share, 0.6164, 1e-6), f"large_share is {large_share}; expected 2,250 / 3,650 = 0.6164."
```

```python test "with_premium"
assert with_premium == [3295.0, 3342.5, 3227.25], f"with_premium is {with_premium}."
```

### Hint 1
Each of these is one line: `[... for p in prices_usd]` or `[... for t in lots if ...]`.

### Hint 2
"500 t or more" is `t >= 500`. For the share, divide the sum of large lots by the sum of all lots.

### Hint 3
```python
prices_eur = [round(p / eurusd, 2) for p in prices_usd]
large_lots = [t for t in lots if t >= 500]
large_share = round(sum(large_lots) / sum(___), 4)
```

## Cards

### Card recall
concept: comprehensions
Q: Write a comprehension that keeps only lots of at least 500 t from `lots`.
A: `[t for t in lots if t >= 500]`

### Card code
concept: comprehensions
Q: Set `inr` to each USD amount in `usd` multiplied by `usdinr`, rounded to 0 decimals.
```python starter
usd = [1000, 2500]
usdinr = 83.25
```
```python solution
usd = [1000, 2500]
usdinr = 83.25
inr = [round(x * usdinr) for x in usd]
```
```python test "inr"
assert inr == [83250, 208125], f"inr is {inr}; multiply each by usdinr and round."
```

## Next
Boss battle: the counterparty says your QP average is wrong. They're right, and you need to find out why.
