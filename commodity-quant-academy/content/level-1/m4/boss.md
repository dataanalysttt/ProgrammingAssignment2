---
id: l1-m4-boss
type: boss
title: Month-end position check
minutes: 10
timeLimit: 600
concepts: [dicts, list-of-dicts, grouping]
---

## Scenario
Last business day of the month, 4:50pm. The risk manager needs indicative value by shipment month at today's LME of **2,880**, plus the premium-weighted picture, for the 5:30 risk call. One trade was also amended this afternoon. Ten minutes.

## Exercise
1. Trade `ZS-00415` was amended to **600 t**. Update it in `book` (find it by id; don't rely on its position).
2. `value_by_month`: dict of month → Σ tonnes × (LME + premium)
3. `tonnes_by_month`: dict of month → Σ tonnes
4. `avg_price_by_month`: month → value ÷ tonnes, rounded to 2 decimals

```python starter
lme = 2880
book = [
    {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "month": "2026-03", "premium": 245},
    {"id": "ZS-00413", "counterparty": "Gulf Coil Coating", "tonnes": 250, "incoterm": "CFR", "month": "2026-03", "premium": 190},
    {"id": "ZS-00414", "counterparty": "Rheinwerk Galvanik", "tonnes": 1000, "incoterm": "DAP", "month": "2026-04", "premium": 242},
    {"id": "ZS-00415", "counterparty": "Saigon Galvanized", "tonnes": 750, "incoterm": "CFR", "month": "2026-04", "premium": 145},
    {"id": "ZS-00416", "counterparty": "Atlas Galvanisation", "tonnes": 400, "incoterm": "CIF", "month": "2026-03", "premium": 215},
    {"id": "ZS-00417", "counterparty": "Gulf Coil Coating", "tonnes": 300, "incoterm": "CFR", "month": "2026-04", "premium": 192},
]

```

```python solution
lme = 2880
book = [
    {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "month": "2026-03", "premium": 245},
    {"id": "ZS-00413", "counterparty": "Gulf Coil Coating", "tonnes": 250, "incoterm": "CFR", "month": "2026-03", "premium": 190},
    {"id": "ZS-00414", "counterparty": "Rheinwerk Galvanik", "tonnes": 1000, "incoterm": "DAP", "month": "2026-04", "premium": 242},
    {"id": "ZS-00415", "counterparty": "Saigon Galvanized", "tonnes": 750, "incoterm": "CFR", "month": "2026-04", "premium": 145},
    {"id": "ZS-00416", "counterparty": "Atlas Galvanisation", "tonnes": 400, "incoterm": "CIF", "month": "2026-03", "premium": 215},
    {"id": "ZS-00417", "counterparty": "Gulf Coil Coating", "tonnes": 300, "incoterm": "CFR", "month": "2026-04", "premium": 192},
]
for t in book:
    if t["id"] == "ZS-00415":
        t["tonnes"] = 600
value_by_month, tonnes_by_month = {}, {}
for t in book:
    m = t["month"]
    value_by_month[m] = value_by_month.get(m, 0) + t["tonnes"] * (lme + t["premium"])
    tonnes_by_month[m] = tonnes_by_month.get(m, 0) + t["tonnes"]
avg_price_by_month = {m: round(value_by_month[m] / tonnes_by_month[m], 2) for m in value_by_month}
```

```python test "amendment applied by id"
t415 = [t for t in book if t["id"] == "ZS-00415"][0]
assert t415["tonnes"] == 600, f"ZS-00415 has {t415['tonnes']} t; set it to 600."
assert sum(t["tonnes"] for t in book) == 3050, "Only ZS-00415 should change; total should be 3,050 t."
```

```python test "tonnes_by_month"
assert tonnes_by_month == {"2026-03": 1150, "2026-04": 1900}, f"tonnes_by_month is {tonnes_by_month}."
```

```python test "value_by_month"
assert value_by_month == {"2026-03": 3568000, "2026-04": 5858600}, f"value_by_month is {value_by_month}; expected March 3,568,000 and April 5,858,600 after the amendment."
```

```python test "avg_price_by_month"
assert avg_price_by_month == {"2026-03": 3102.61, "2026-04": 3083.47}, f"avg_price_by_month is {avg_price_by_month}."
```
