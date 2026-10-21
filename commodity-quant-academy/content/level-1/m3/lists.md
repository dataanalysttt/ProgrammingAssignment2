---
id: l1-m3-l1
title: "Lists: a QP's daily prices"
minutes: 12
concepts: [lists]
objectives:
- Create lists and read items by index
- Use len() and negative indexes
- Add, change and remove items
---

## Learn
A **list** holds an ordered sequence of values in square brackets. A QP's daily LME cash settlements are a natural list:

```python example
qp_prices = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0]
print(qp_prices[0])       # first published day
print(qp_prices[-1])      # latest day
print(len(qp_prices))     # days published so far
```

Lists are **mutable**, so you can change them in place:

```python example
qp_prices = [2841.5, 2856.0, 2830.25]
qp_prices.append(2862.75)     # a new settlement is published
qp_prices[1] = 2855.5         # correction to day 2
qp_prices.remove(2830.25)     # remove by value
print(qp_prices)
```

- `append(x)` adds to the end; `insert(i, x)` at position `i`.
- `pop()` removes and returns the last item; `pop(i)` the item at `i`.
- `x in lst` checks membership.
- Indexes run from `0` to `len(lst) - 1`. Asking for `lst[len(lst)]` gives `IndexError`.

## Desk
While a QP is running, the price is not known. You have a growing list of published settlements and a number of days still to come. Tracking "days fixed vs days to go" is exactly what tells sales and risk how much of a cargo is already priced.

## Exercise
The M+1 QP for a Selangor Zinc cargo has **22** LME business days. Ten settlements are published so far (`qp`). Today's settlement of **2,869.0** has just come out, and the LME has corrected day 3 to **2,831.0**.

Do, in order:

1. append today's price
2. correct day 3 (the third item)
3. create `days_fixed` (how many prices you have) and `days_to_go` (22 minus that)
4. create `first_price` and `latest_price`

```python starter
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
qp_days_total = 22

```

```python solution
qp = [2841.5, 2856.0, 2830.25, 2862.75, 2849.0, 2871.5, 2866.25, 2858.0, 2880.75, 2875.5]
qp_days_total = 22
qp.append(2869.0)
qp[2] = 2831.0
days_fixed = len(qp)
days_to_go = qp_days_total - days_fixed
first_price = qp[0]
latest_price = qp[-1]
```

```python test "today's price appended"
assert len(qp) == 11 and qp[-1] == 2869.0, f"qp has {len(qp)} items ending in {qp[-1]}; append 2869.0 once."
```

```python test "day 3 corrected"
assert qp[2] == 2831.0, f"qp[2] is {qp[2]}; the third item has index 2 (counting from 0)."
```

```python test "days fixed and to go"
assert days_fixed == 11, f"days_fixed is {days_fixed}; use len(qp) after appending."
assert days_to_go == 11, f"days_to_go is {days_to_go}; expected 22 - 11 = 11."
```

```python test "first and latest"
assert first_price == 2841.5 and latest_price == 2869.0, f"first_price={first_price}, latest_price={latest_price}; use qp[0] and qp[-1]."
```

### Hint 1
Four small steps, one line each. Do the append before computing `len`.

### Hint 2
The third item is at index 2 because indexes start at 0. `lst[-1]` is always the last item.

### Hint 3
```python
qp.append(2869.0)
qp[2] = 2831.0
days_fixed = len(qp)
days_to_go = qp_days_total - ___
```

## Cards

### Card recall
concept: lists
Q: `prices = [2841.5, 2856.0, 2830.25]`. What are `prices[1]` and `prices[-1]`?
A: `2856.0` (index 1 is the second item) and `2830.25` (the last item).

### Card code
concept: lists
Q: Append `2870.0` to `qp`, then set `n` to the number of prices.
```python starter
qp = [2841.5, 2856.0]
```
```python solution
qp = [2841.5, 2856.0]
qp.append(2870.0)
n = len(qp)
```
```python test "append and count"
assert qp == [2841.5, 2856.0, 2870.0] and n == 3, f"qp={qp}, n={n}; append once, then n = len(qp)."
```

## Next
The counterparty wants an indication of the final price before the QP ends. What's the average so far, and how far can it still move?
