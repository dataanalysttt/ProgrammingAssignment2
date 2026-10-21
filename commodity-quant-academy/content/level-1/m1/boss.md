---
id: l1-m1-boss
type: boss
title: Freight desk at 4:55pm
minutes: 10
timeLimit: 600
concepts: [variables, types, rounding, operators]
---

## Scenario
4:55pm. The booking cut-off for Friday's sailing to Jebel Ali is at 5:15. Gulf Coil Coating has confirmed **1,215.5 t**, but the order came through as text from their email. Logistics needs the box count and finance needs the provisional invoice figure. No hints, ten minutes.

## Exercise
From the text values, create:

- `tonnes` (float) from `order_text`
- `boxes`: 25 t containers needed (round up)
- `unit_price`: LME + premium, rounded to 2 decimals (both arrive as text)
- `provisional`: 90% of tonnes × unit price, rounded to 2 decimals
- `freight_total`: boxes × `box_rate`

```python starter
order_text = "1,215.500"
lme_text = "2,904.375"
premium_text = "191.5"
box_rate = 485   # USD per 20-ft box, Nhava Sheva to Jebel Ali

```

```python solution
order_text = "1,215.500"
lme_text = "2,904.375"
premium_text = "191.5"
box_rate = 485
tonnes = float(order_text.replace(",", ""))
boxes = -(-tonnes // 25)
unit_price = round(float(lme_text.replace(",", "")) + float(premium_text), 2)
provisional = round(0.9 * tonnes * unit_price, 2)
freight_total = boxes * box_rate
```

```python test "tonnes = 1215.5"
assert approx(tonnes, 1215.5, 1e-9), f"tonnes is {tonnes!r}; expected the float 1215.5."
```

```python test "49 boxes"
assert boxes == 49, f"boxes is {boxes}; 1215.5 / 25 = 48.62, which rounds up to 49."
```

```python test "unit_price = 3,095.88"
assert approx(unit_price, 3095.88, 1e-6), f"unit_price is {unit_price}; expected round(2904.375 + 191.5, 2) = 3095.88 (round(3095.875, 2) gives 3095.88)."
```

```python test "provisional = 3,386,737.93"
assert approx(provisional, 3386737.93, 0.011), f"provisional is {provisional}; expected round(0.9 x 1215.5 x 3095.88, 2) = 3,386,737.93."
```

```python test "freight_total = 23,765"
assert approx(freight_total, 23765), f"freight_total is {freight_total}; expected 49 boxes x 485 = 23,765."
```
