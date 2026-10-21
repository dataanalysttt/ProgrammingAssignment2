---
id: l1-m5-l3
title: "while, break and continue: allocating lots"
minutes: 15
concepts: [while-loops]
objectives:
- Loop until a condition is met with while
- Skip items with continue and stop early with break
- Avoid infinite loops
---

## Learn
`while condition:` repeats its block as long as the condition stays `True`. Use it when you don't know in advance how many steps you need, such as "add lots until the order is filled".

```python example
order = 1000
lots = [425.5, 410.25, 402.0, 395.75]
allocated = 0
i = 0
while allocated < order and i < len(lots):
    allocated += lots[i]
    i += 1
print(i, "lots,", allocated, "t")
```

- `continue` jumps to the next iteration (skip this item).
- `break` leaves the loop immediately.
- Both also work in `for` loops.

**Infinite loops:** if nothing inside the loop moves you towards ending it (here `i += 1`), it runs forever. The app stops your code after 20 seconds, but the habit to build is: *what changes each time round, and when does it stop?*

## Desk
Allocation (matching warehouse lots or warrants to sales orders) is a daily ops task. Orders have a tolerance (often ±2%), lots come in uneven sizes, and some lots are on hold for quality or documents. The rules "skip held lots, stop once filled, check tolerance" are exactly `continue`, `break` and a final comparison.

## Exercise
Allocate lots **in order** to a 2,000 t order:

- skip lots whose `ok` flag is `False` (`continue`)
- stop as soon as the allocated tonnage reaches the order (whole lots only, so you may overfill slightly)

Create `allocated_ids` (list), `allocated_t`, `over_t` (allocated minus order) and `within_tolerance` (over-allocation ≤ 2% of the order).

```python starter
order_t = 2000
lots = [("W-101", 425.5, True), ("W-102", 398.0, False), ("W-103", 410.25, True),
        ("W-104", 402.0, True), ("W-105", 395.75, True), ("W-106", 400.0, True), ("W-107", 405.0, True)]

```

```python solution
order_t = 2000
lots = [("W-101", 425.5, True), ("W-102", 398.0, False), ("W-103", 410.25, True),
        ("W-104", 402.0, True), ("W-105", 395.75, True), ("W-106", 400.0, True), ("W-107", 405.0, True)]
allocated_ids = []
allocated_t = 0
i = 0
while i < len(lots):
    lot_id, tonnes, ok = lots[i]
    i += 1
    if not ok:
        continue
    allocated_ids.append(lot_id)
    allocated_t += tonnes
    if allocated_t >= order_t:
        break
over_t = allocated_t - order_t
within_tolerance = over_t <= 0.02 * order_t
```

```python test "held lot skipped"
assert "W-102" not in allocated_ids, "W-102 is on hold (ok=False) and must be skipped with continue."
```

```python test "stops once filled"
assert allocated_ids == ["W-101", "W-103", "W-104", "W-105", "W-106"], f"allocated_ids is {allocated_ids}; you should stop after W-106, when the total first reaches 2,000 t."
```

```python test "tonnages"
assert approx(allocated_t, 2033.5, 1e-9), f"allocated_t is {allocated_t}; expected 2,033.5."
assert approx(over_t, 33.5, 1e-9), f"over_t is {over_t}; expected 33.5."
```

```python test "tolerance"
assert within_tolerance is True, f"within_tolerance is {within_tolerance!r}; 33.5 t is within 2% of 2,000 t (40 t)."
```

### Hint 1
Each lot is a tuple: unpack it with `lot_id, tonnes, ok = lots[i]`. Increment `i` before any `continue`, or you'll loop forever on the held lot.

### Hint 2
Check the order is filled *after* adding a lot, and `break` if it is. A `for` loop over `lots` works too.

### Hint 3
```python
for lot_id, tonnes, ok in lots:
    if not ok:
        continue
    allocated_ids.append(lot_id)
    allocated_t += tonnes
    if allocated_t >= order_t:
        break
```

## Cards

### Card recall
concept: while-loops
Q: What's the difference between `break` and `continue`?
A: `continue` skips the rest of this iteration and moves to the next item. `break` exits the loop completely.

### Card code
concept: while-loops
Q: Using a loop, set `n` to how many lots (in order) are needed to reach at least 1,000 t.
```python starter
lots = [300, 250, 400, 200]
```
```python solution
lots = [300, 250, 400, 200]
total, n = 0, 0
while total < 1000:
    total += lots[n]
    n += 1
```
```python test "n"
assert n == 4, f"n is {n}; 300+250+400 = 950 < 1,000, so you need the 4th lot."
```

## Next
Pair QP dates with prices, number invoice lines and find the day the market dropped hardest, without index bugs.
