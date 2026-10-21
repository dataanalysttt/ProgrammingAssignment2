---
id: l1-m5-l1
title: "if / elif / else: who pays the freight?"
minutes: 15
concepts: [conditionals]
objectives:
- Branch with if, elif and else
- Combine conditions with and, or, not, and test membership with in
- Encode Incoterms 2020 cost and risk rules as code
---

## Learn
`if` runs a block only when its condition is `True`. `elif` checks the next condition only if the earlier ones were `False`. `else` catches everything left.

```python example
incoterm = "CIF"
if incoterm in ("FCA", "FOB"):
    print("Buyer books the main carriage")
elif incoterm in ("CFR", "CIF", "DAP", "DDP"):
    print("Seller books the main carriage")
else:
    print("Unknown Incoterm:", incoterm)
```

- Comparisons: `==`, `!=`, `<`, `<=`, `>`, `>=`. `=` assigns and `==` compares; mixing them up is the classic bug.
- Combine with `and`, `or`, `not`. `x in ("A", "B")` is cleaner than `x == "A" or x == "B"`.
- Indentation defines the block. Use 4 spaces and be consistent.

**Incoterms 2020, as used on a refined-metals desk:**

| Term | Seller books main carriage | Seller must insure | Risk passes |
|---|---|---|---|
| FCA | no | no | at origin (handed to buyer's carrier) |
| FOB | no | no | at origin (on board at load port) |
| CFR | yes | no | at origin (on board) |
| CIF | yes | yes (min. ICC C) | at origin (on board) |
| DAP | yes | no | at destination |
| DDP | yes | no | at destination (duties paid) |

Note that under CFR and CIF the seller pays the freight but risk has *already* passed at the load port. Cost and risk transfer at different points.

## Desk
Incoterm mistakes cost real money: a CIF sale quoted without insurance, a DAP offer that forgot destination port charges, a CFR claim where the seller wrongly assumed liability for transit damage. Encoding the rules once, correctly, means every netback and landed-cost calculation in Level 4 starts right.

## Exercise
`incoterm` is already set for you (the tests try every term). Write an `if / elif / else` that sets three variables:

- `seller_main_carriage`: `True` or `False`
- `seller_must_insure`: `True` only for CIF
- `risk_transfer`: `"origin"` for FCA, FOB, CFR, CIF; `"destination"` for DAP, DDP

For anything else, set all three to `None`. Don't assign `incoterm` yourself.

```python setup
incoterm = "CIF"
```

```python starter
# incoterm is given (e.g. "CIF"); do not overwrite it
print("Checking", incoterm)

```

```python solution
if incoterm in ("FCA", "FOB"):
    seller_main_carriage, seller_must_insure, risk_transfer = False, False, "origin"
elif incoterm in ("CFR", "CIF"):
    seller_main_carriage = True
    seller_must_insure = incoterm == "CIF"
    risk_transfer = "origin"
elif incoterm in ("DAP", "DDP"):
    seller_main_carriage, seller_must_insure, risk_transfer = True, False, "destination"
else:
    seller_main_carriage = seller_must_insure = risk_transfer = None
```

```python test "F terms: buyer books carriage"
for term in ("FCA", "FOB"):
    ns = rerun(incoterm=term)
    assert ns["seller_main_carriage"] is False and ns["seller_must_insure"] is False, f"{term}: seller_main_carriage and seller_must_insure should both be False."
    assert ns["risk_transfer"] == "origin", f"{term}: risk passes at origin."
```

```python test "CFR vs CIF: only CIF insures"
cfr, cif = rerun(incoterm="CFR"), rerun(incoterm="CIF")
assert cfr["seller_main_carriage"] is True and cif["seller_main_carriage"] is True, "Under CFR and CIF the seller books the main carriage."
assert cfr["seller_must_insure"] is False, "CFR: the seller is NOT obliged to insure. That's the difference between CFR and CIF."
assert cif["seller_must_insure"] is True, "CIF: the seller must insure."
assert cfr["risk_transfer"] == "origin" and cif["risk_transfer"] == "origin", "CFR/CIF: risk passes at origin (on board), even though the seller pays freight."
```

```python test "D terms: risk at destination"
for term in ("DAP", "DDP"):
    ns = rerun(incoterm=term)
    assert ns["seller_main_carriage"] is True and ns["seller_must_insure"] is False, f"{term}: seller books carriage; no insurance obligation."
    assert ns["risk_transfer"] == "destination", f"{term}: risk passes at destination."
```

```python test "unknown term -> None"
ns = rerun(incoterm="XYZ")
assert ns["seller_main_carriage"] is None and ns["seller_must_insure"] is None and ns["risk_transfer"] is None, "For an unknown Incoterm all three should be None (use else)."
```

```python test "incoterm not overwritten"
ns = rerun(incoterm="DAP")
assert ns["incoterm"] == "DAP", "Your code assigns incoterm itself. Remove that line; the value is given."
```

### Hint 1
Group the terms that behave the same: (FCA, FOB), (CFR, CIF), (DAP, DDP). That's three branches plus `else`.

### Hint 2
`incoterm in ("CFR", "CIF")` tests membership. Inside that branch, `seller_must_insure = incoterm == "CIF"` gives the right bool for both terms.

### Hint 3
```python
if incoterm in ("FCA", "FOB"):
    seller_main_carriage = False
    seller_must_insure = False
    risk_transfer = "origin"
elif incoterm in ("CFR", "CIF"):
    ...
elif incoterm in ("DAP", "DDP"):
    ...
else:
    ...
```

## Cards

### Card recall
concept: conditionals
Q: Under CFR, who pays the main freight, and where does risk pass?
A: The seller pays the freight, but risk passes to the buyer at origin, once the goods are on board at the load port.

### Card recall
concept: conditionals
Q: What's the difference between CFR and CIF?
A: CIF adds the seller's obligation to insure the cargo (minimum ICC C cover). Freight and the risk transfer point are the same.

## Next
Six open trades, one LME price: compute every provisional invoice and a running total in five lines.
