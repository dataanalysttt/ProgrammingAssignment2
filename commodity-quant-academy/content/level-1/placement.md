---
id: l1-placement
type: placement
title: Level 1 placement test
minutes: 30
xp: 0
concepts: [placement]
---

## Learn
Twelve items, two per module, no hints, no clock. Pass **both** items of a module to test out of it. Its lessons are marked complete and their review cards enter your queue (first review in 3 days), so anything you half-know gets caught by spaced repetition.

Answer honestly. Testing out of something you can't do from a blank editor just moves the struggle to Level 2.

## Exercise module=l1-m1
Set `value` to the gross invoice value of **1,250 t** at LME **2,904.5** plus **212** premium, and `boxes` to the number of 25 t containers needed for that tonnage (round up).

```python starter
```

```python solution
value = 1250 * (2904.5 + 212)
boxes = -(-1250 // 25)
```

```python test "value"
assert approx(value, 3895625.0), f"value is {value}; expected 1,250 x 3,116.5 = 3,895,625."
```

```python test "boxes"
assert boxes == 50, f"boxes is {boxes}; 1,250 / 25 = 50 exactly."
```

## Exercise module=l1-m1
`weight_text` came from a PDF. Set `tonnes` to it as a float, and `amount` to tonnes × 3,101.25 rounded to cents.

```python starter
weight_text = " 2,001.375 "
```

```python solution
weight_text = " 2,001.375 "
tonnes = float(weight_text.strip().replace(",", ""))
amount = round(tonnes * 3101.25, 2)
```

```python test "tonnes"
assert tonnes == 2001.375, f"tonnes is {tonnes!r}; strip, remove the comma, float()."
```

```python test "amount"
assert amount == 6206764.22, f"amount is {amount}; expected round(2001.375 x 3101.25, 2) = 6,206,764.22."
```

## Exercise module=l1-m2
Set `line` to exactly `Gulf Coil Coating | CFR | 1,250.000 t | USD 3,895,625.00` using the variables given.

```python starter
buyer = "  GULF COIL COATING "
term = "cfr"
tonnes = 1250
value = 3895625
```

```python solution
buyer = "  GULF COIL COATING "
term = "cfr"
tonnes = 1250
value = 3895625
line = f"{buyer.strip().title()} | {term.upper()} | {tonnes:,.3f} t | USD {value:,.2f}"
```

```python test "line"
assert line == "Gulf Coil Coating | CFR | 1,250.000 t | USD 3,895,625.00", f"line is {line!r}."
```

## Exercise module=l1-m2
From `recap`, set `buyer` (string), `tonnes` (int) and `qp` (string), all stripped.

```python starter
recap = "2026-05-02 ; Atlas Galvanisation ; 400 ; CIF ; M+1"
```

```python solution
recap = "2026-05-02 ; Atlas Galvanisation ; 400 ; CIF ; M+1"
parts = [p.strip() for p in recap.split(";")]
buyer, tonnes, qp = parts[1], int(parts[2]), parts[4]
```

```python test "fields"
assert buyer == "Atlas Galvanisation" and tonnes == 400 and qp == "M+1", f"Got buyer={buyer!r}, tonnes={tonnes!r}, qp={qp!r}."
```

## Exercise module=l1-m3
Set `qp_avg` (mean of `qp`, 2 decimals) and `top2` (two highest prices, highest first) without changing `qp`.

```python starter
qp = [2701.5, 2715.0, 2698.25, 2722.75, 2709.0]
```

```python solution
qp = [2701.5, 2715.0, 2698.25, 2722.75, 2709.0]
qp_avg = round(sum(qp) / len(qp), 2)
top2 = sorted(qp, reverse=True)[:2]
```

```python test "qp_avg"
assert qp_avg == 2709.3, f"qp_avg is {qp_avg}; expected 13,546.5 / 5 = 2,709.30."
```

```python test "top2 and order"
assert top2 == [2722.75, 2715.0], f"top2 is {top2}."
assert qp == [2701.5, 2715.0, 2698.25, 2722.75, 2709.0], "qp was modified; use sorted(), not .sort()."
```

## Exercise module=l1-m3
With one list comprehension, set `eur` to the USD prices of 3,000 or more converted to EUR at 1.10, rounded to 2 decimals.

```python starter
usd = [2950.0, 3010.0, 3101.5, 2999.99]
```

```python solution
usd = [2950.0, 3010.0, 3101.5, 2999.99]
eur = [round(p / 1.10, 2) for p in usd if p >= 3000]
```

```python test "eur"
assert eur == [2736.36, 2819.55], f"eur is {eur}; keep p >= 3000, divide by 1.10, round to 2."
```

## Exercise module=l1-m4
Update `trade`: premium + 7, add `"status": "priced"`. Set `fp` to `trade.get("final_price", 0)`.

```python starter
trade = {"id": "ZS-00701", "tonnes": 500, "premium": 238}
```

```python solution
trade = {"id": "ZS-00701", "tonnes": 500, "premium": 238}
trade["premium"] += 7
trade["status"] = "priced"
fp = trade.get("final_price", 0)
```

```python test "trade"
assert trade == {"id": "ZS-00701", "tonnes": 500, "premium": 245, "status": "priced"} and fp == 0, f"trade is {trade}, fp is {fp}."
```

## Exercise module=l1-m4
Build `by_cp`: total tonnes per counterparty.

```python starter
book = [("Rheinwerk", 500), ("Atlas", 400), ("Rheinwerk", 1000), ("Gulf Coil", 250), ("Atlas", 150)]
```

```python solution
book = [("Rheinwerk", 500), ("Atlas", 400), ("Rheinwerk", 1000), ("Gulf Coil", 250), ("Atlas", 150)]
by_cp = {}
for cp, t in book:
    by_cp[cp] = by_cp.get(cp, 0) + t
```

```python test "by_cp"
assert by_cp == {"Rheinwerk": 1500, "Atlas": 550, "Gulf Coil": 250}, f"by_cp is {by_cp}."
```

## Exercise module=l1-m5
`incoterm` is given (the test tries several). Set `seller_insures` to `True` only for CIF, and `risk_at` to `"destination"` for DAP or DDP, else `"origin"`. Don't assign `incoterm`.

```python setup
incoterm = "CIF"
```

```python starter
```

```python solution
seller_insures = incoterm == "CIF"
if incoterm in ("DAP", "DDP"):
    risk_at = "destination"
else:
    risk_at = "origin"
```

```python test "all terms"
for term, ins, risk in [("FCA", False, "origin"), ("CFR", False, "origin"), ("CIF", True, "origin"), ("DAP", False, "destination"), ("DDP", False, "destination")]:
    ns = rerun(incoterm=term)
    assert ns["seller_insures"] is ins and ns["risk_at"] == risk, f"{term}: expected seller_insures={ins}, risk_at={risk!r}; got {ns['seller_insures']!r}, {ns['risk_at']!r}."
```

## Exercise module=l1-m5
Allocate `lots` in order (skip `None`, which means on hold) until at least 1,000 t. Set `used` (count of lots allocated) and `total`.

```python starter
lots = [310.5, None, 295.0, 402.25, 288.0]
```

```python solution
lots = [310.5, None, 295.0, 402.25, 288.0]
used, total = 0, 0
for t in lots:
    if t is None:
        continue
    total += t
    used += 1
    if total >= 1000:
        break
```

```python test "allocation"
assert used == 3 and total == 1007.75, f"used={used}, total={total}; expected 3 lots totalling 1,007.75 t."
```

## Exercise module=l1-m6
Write `provisional(tonnes, price, premium, pct=0.9)` returning the amount rounded to 2 decimals. It must raise `ValueError` if tonnes ≤ 0.

```python starter
```

```python solution
def provisional(tonnes, price, premium, pct=0.9):
    if tonnes <= 0:
        raise ValueError(f"tonnes must be > 0, got {tonnes}")
    return round(pct * tonnes * (price + premium), 2)
```

```python test "values"
assert provisional(1000, 2800, 250) == 2745000.0 and provisional(1000, 2800, 250, pct=1) == 3050000, "Expected 2,745,000 at 90% and 3,050,000 at 100%."
```

```python test "raises"
try:
    provisional(0, 2800, 250)
    raise AssertionError("tonnes=0 should raise ValueError")
except ValueError:
    pass
```

## Exercise module=l1-m6
Write `parse_price(s)` returning a float, or `None` when `s` can't be parsed (`"tbc"`, `""`). Commas allowed.

```python starter
```

```python solution
def parse_price(s):
    try:
        return float(s.replace(",", ""))
    except ValueError:
        return None
```

```python test "parse_price"
assert parse_price("2,850.5") == 2850.5 and parse_price("tbc") is None and parse_price("") is None, "parse_price('2,850.5') -> 2850.5; bad input -> None."
```
