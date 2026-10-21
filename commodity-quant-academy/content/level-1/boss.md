---
id: l1-boss
type: boss
title: Month-end close (level boss)
minutes: 15
timeLimit: 900
passMark: 0.8
concepts: [split-join, functions, grouping, validation]
---

## Scenario
Month-end close. The broker's recap of this month's sales arrived as raw text. Finance needs provisional invoices by counterparty tonight, and ops needs a list of the broken lines. You have 15 minutes. **80% unlocks Level 2.**

Each recap line is `trade_id;counterparty;tonnes;incoterm;premium`. LME provisional price is **2,875**; provisional invoices are **90%**.

## Exercise title="Parse"
Write `parse_line(line)` returning a dict with keys `id`, `counterparty`, `tonnes` (float), `incoterm` (upper case), `premium` (float), all stripped. Raise `ValueError` if the line doesn't have exactly 5 fields.

```python starter
def parse_line(line):
    pass
```

```python solution
def parse_line(line):
    parts = [p.strip() for p in line.split(";")]
    if len(parts) != 5:
        raise ValueError(f"expected 5 fields, got {len(parts)}: {line!r}")
    tid, cp, t, inc, prem = parts
    return {"id": tid, "counterparty": cp, "tonnes": float(t.replace(",", "")), "incoterm": inc.upper(), "premium": float(prem)}
```

```python test "parses a line"
r = parse_line(" ZS-00801 ; Rheinwerk Galvanik ; 1,000 ; dap ; 244 ")
assert r == {"id": "ZS-00801", "counterparty": "Rheinwerk Galvanik", "tonnes": 1000.0, "incoterm": "DAP", "premium": 244.0}, f"Got {r}."
```

```python test "wrong field count raises"
try:
    parse_line("ZS-00802;Atlas;400;CIF")
    raise AssertionError("A 4-field line should raise ValueError.")
except ValueError:
    pass
```

## Exercise title="Invoice"
Using your own `parse_line` (paste it in), process `recap`: skip lines that raise `ValueError` (record their **index** in `broken`), and build `prov_by_cp`: counterparty → total provisional amount (90% × tonnes × (2,875 + premium)), each total rounded to 2 decimals.

```python starter
recap = """ZS-00801;Rheinwerk Galvanik;1,000;dap;244
ZS-00802;Atlas Galvanisation;400;CIF
ZS-00803;Gulf Coil Coating;250;cfr;191
ZS-00804;Rheinwerk Galvanik;500;DAP;246
ZS-00805;Gulf Coil Coating;three hundred;CFR;190
ZS-00806;Saigon Galvanized;750;CFR;146"""
LME = 2875
```

```python solution
recap = """ZS-00801;Rheinwerk Galvanik;1,000;dap;244
ZS-00802;Atlas Galvanisation;400;CIF
ZS-00803;Gulf Coil Coating;250;cfr;191
ZS-00804;Rheinwerk Galvanik;500;DAP;246
ZS-00805;Gulf Coil Coating;three hundred;CFR;190
ZS-00806;Saigon Galvanized;750;CFR;146"""
LME = 2875


def parse_line(line):
    parts = [p.strip() for p in line.split(";")]
    if len(parts) != 5:
        raise ValueError("expected 5 fields")
    tid, cp, t, inc, prem = parts
    return {"id": tid, "counterparty": cp, "tonnes": float(t.replace(",", "")), "incoterm": inc.upper(), "premium": float(prem)}


broken, prov_by_cp = [], {}
for i, line in enumerate(recap.splitlines()):
    try:
        t = parse_line(line)
    except ValueError:
        broken.append(i)
        continue
    amount = 0.9 * t["tonnes"] * (LME + t["premium"])
    prov_by_cp[t["counterparty"]] = round(prov_by_cp.get(t["counterparty"], 0) + amount, 2)
```

```python test "broken lines"
assert broken == [1, 4], f"broken is {broken}; line 1 has 4 fields and line 4 has 'three hundred' tonnes (float() raises ValueError)."
```

```python test "Rheinwerk total"
assert approx(prov_by_cp.get("Rheinwerk Galvanik", 0), 4211550.0), f"Rheinwerk is {prov_by_cp.get('Rheinwerk Galvanik')}; expected 0.9 x (1,000 x 3,119 + 500 x 3,121) = 4,211,550."
```

```python test "other counterparties"
assert approx(prov_by_cp.get("Gulf Coil Coating", 0), 689850.0) and approx(prov_by_cp.get("Saigon Galvanized", 0), 2039175.0), f"prov_by_cp is {prov_by_cp}."
assert "Atlas Galvanisation" not in prov_by_cp, "Atlas's only line is broken, so Atlas shouldn't appear."
```

## Exercise title="Report"
Write `summary_line(cp, amount)` returning `f"{cp:<20}USD {amount:>14,.2f}"`-style text: the counterparty left-aligned in 20 characters, then `USD `, then the amount right-aligned in 14 characters with commas and 2 decimals.

```python starter
def summary_line(cp, amount):
    pass
```

```python solution
def summary_line(cp, amount):
    return f"{cp:<20}USD {amount:>14,.2f}"
```

```python test "format"
s = summary_line("Gulf Coil Coating", 689872.5)
assert s == "Gulf Coil Coating   USD     689,872.50", f"Got {s!r}; expected 'Gulf Coil Coating   USD     689,872.50'."
```
