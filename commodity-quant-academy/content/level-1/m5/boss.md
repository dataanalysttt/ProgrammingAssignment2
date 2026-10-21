---
id: l1-m5-boss
type: boss
title: Allocation crunch
minutes: 12
timeLimit: 720
concepts: [conditionals, for-loops, while-loops, enumerate-zip]
---

## Scenario
Rotterdam warehouse, 4:45pm local. Two DAP orders ship next week, in priority order: **Rheinwerk Galvanik 800 t**, then **Atlas Galvanisation 600 t**. The warehouse list has one lot on quality hold. Logistics needs the allocation sheet before the warehouse closes. Twelve minutes.

## Exercise
Allocate lots **in list order**: fill the first buyer completely (whole lots, stop once the order is reached), then continue with the **next unused lot** for the second buyer. Skip held lots.

Create:

- `allocation`: dict buyer → list of lot ids
- `allocated_t`: dict buyer → tonnes allocated
- `unused`: list of OK lot ids left over
- `rejected`: list of held lot ids

```python starter
orders = [("Rheinwerk Galvanik", 800), ("Atlas Galvanisation", 600)]
lots = [("W-201", 210.0, True), ("W-202", 205.5, True), ("W-203", 198.0, False), ("W-204", 202.25, True),
        ("W-205", 199.5, True), ("W-206", 201.0, True), ("W-207", 204.75, True), ("W-208", 197.25, True),
        ("W-209", 203.0, True)]

```

```python solution
orders = [("Rheinwerk Galvanik", 800), ("Atlas Galvanisation", 600)]
lots = [("W-201", 210.0, True), ("W-202", 205.5, True), ("W-203", 198.0, False), ("W-204", 202.25, True),
        ("W-205", 199.5, True), ("W-206", 201.0, True), ("W-207", 204.75, True), ("W-208", 197.25, True),
        ("W-209", 203.0, True)]
allocation, allocated_t = {}, {}
rejected = [lot_id for lot_id, t, ok in lots if not ok]
i = 0
for buyer, qty in orders:
    allocation[buyer], allocated_t[buyer] = [], 0
    while i < len(lots) and allocated_t[buyer] < qty:
        lot_id, t, ok = lots[i]
        i += 1
        if not ok:
            continue
        allocation[buyer].append(lot_id)
        allocated_t[buyer] += t
unused = [lot_id for lot_id, t, ok in lots[i:] if ok]
```

```python test "Rheinwerk allocation"
assert allocation.get("Rheinwerk Galvanik") == ["W-201", "W-202", "W-204", "W-205"], f"Rheinwerk got {allocation.get('Rheinwerk Galvanik')}; expected W-201, W-202, W-204, W-205 (W-203 is held)."
```

```python test "Atlas continues from the next lot"
assert allocation.get("Atlas Galvanisation") == ["W-206", "W-207", "W-208"], f"Atlas got {allocation.get('Atlas Galvanisation')}; it should start at W-206, the next unused lot."
```

```python test "tonnes allocated"
assert approx(allocated_t.get("Rheinwerk Galvanik", 0), 817.25, 1e-9) and approx(allocated_t.get("Atlas Galvanisation", 0), 603.0, 1e-9), f"allocated_t is {allocated_t}; expected 817.25 and 603.0."
```

```python test "unused and rejected"
assert unused == ["W-209"], f"unused is {unused}; only W-209 is left."
assert rejected == ["W-203"], f"rejected is {rejected}."
```
