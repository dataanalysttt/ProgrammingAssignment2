---
id: l1-m2-boss
type: boss
title: The confirmation that went out wrong
minutes: 10
timeLimit: 600
concepts: [strings, slicing, split-join, fstrings]
---

## Scenario
Lombardia Zincatura calls: the confirmation you sent shows the wrong Incoterm and a garbled quantity. The source was a recap line pasted from chat. Rebuild the confirmation correctly before they escalate to your desk head. Ten minutes, no hints.

## Exercise
From `recap`, produce:

- `ref`, `buyer` (title case), `incoterm` (upper case), `port` (last 3 characters of the reference)
- `tonnes` (float) and `premium` (float)
- `confirmation`, exactly: `ZN-26-0533-CIF-GOA | Lombardia Zincatura Spa | 1,250.000 t SHG zinc | CIF GOA | LME cash M+1 avg + USD 238.50/t`

The QP (`M+1`) also comes from the recap.

```python starter
recap = "  zn-26-0533-cif-goa ;LOMBARDIA ZINCATURA SPA; 1,250.000 ;cif; m+1 ; 238.5 "

```

```python solution
recap = "  zn-26-0533-cif-goa ;LOMBARDIA ZINCATURA SPA; 1,250.000 ;cif; m+1 ; 238.5 "
fields = [f.strip() for f in recap.split(";")]
ref = fields[0].upper()
buyer = fields[1].title()
tonnes = float(fields[2].replace(",", ""))
incoterm = fields[3].upper()
qp = fields[4].upper()
premium = float(fields[5])
port = ref[-3:]
confirmation = f"{ref} | {buyer} | {tonnes:,.3f} t SHG zinc | {incoterm} {port} | LME cash {qp} avg + USD {premium:,.2f}/t"
```

```python test "ref and port"
assert ref == "ZN-26-0533-CIF-GOA", f"ref is {ref!r}; strip and upper-case the first field."
assert port == "GOA", f"port is {port!r}; last three characters of ref."
```

```python test "buyer and incoterm"
assert buyer == "Lombardia Zincatura Spa", f"buyer is {buyer!r}; strip and title-case."
assert incoterm == "CIF", f"incoterm is {incoterm!r}."
```

```python test "numbers"
assert tonnes == 1250.0, f"tonnes is {tonnes!r}; remove the comma then float()."
assert premium == 238.5, f"premium is {premium!r}."
```

```python test "confirmation text"
expected = "ZN-26-0533-CIF-GOA | Lombardia Zincatura Spa | 1,250.000 t SHG zinc | CIF GOA | LME cash M+1 avg + USD 238.50/t"
assert confirmation == expected, f"Got      {confirmation!r}\nExpected {expected!r}"
```
