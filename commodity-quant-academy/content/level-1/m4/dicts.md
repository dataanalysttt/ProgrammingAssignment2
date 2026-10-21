---
id: l1-m4-l1
title: Dictionaries as trade records
minutes: 15
concepts: [dicts]
objectives:
- Store a trade as key-value pairs
- Read values with [] and .get()
- Add, update and delete fields
---

## Learn
A **dictionary** maps keys to values. It's the natural shape for one trade:

```python example
trade = {
    "id": "ZS-00412",
    "counterparty": "Rheinwerk Galvanik",
    "tonnes": 500,
    "incoterm": "DAP",
    "qp": "M+1",
    "premium": 245,
}
print(trade["counterparty"], trade["tonnes"])
```

- `d[key]` reads a value; a missing key raises `KeyError`.
- `d.get(key, default)` returns `default` instead of failing. Use it for optional fields.
- `d[key] = value` adds a new key or overwrites an existing one.
- `del d[key]` removes a key; `key in d` checks for it.
- `d.keys()`, `d.values()`, `d.items()` give views you can loop over.

```python example
trade = {"id": "ZS-00412", "tonnes": 500, "premium": 245}
trade["premium"] = 250                 # amendment
trade["status"] = "provisional"        # new field
print(trade.get("final_price", "not priced"))
print(trade)
```

Keys must be immutable (strings and numbers are usual). Values can be anything, including lists and other dicts.

## Desk
A trade ticket is a dictionary: fixed fields, each with one value. Amendments (premium renegotiated, tonnage cut, Incoterm switched to CIF) are updates to individual keys, and an audit trail is the list of those updates. Thinking of trades this way makes later tools (pandas, databases, JSON from APIs) obvious.

## Exercise
Starting from `trade`:

1. The counterparty agreed to cut the quantity to **450 t** and increase the premium by **5**. Update both.
2. Add `"status": "provisional"`.
3. Create `final_price` with `.get()`: the trade's `"final_price"` value if present, otherwise `None`.
4. Create `value`: tonnes × (`lme` + premium).

```python starter
trade = {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "qp": "M+1", "premium": 245}
lme = 2880

```

```python solution
trade = {"id": "ZS-00412", "counterparty": "Rheinwerk Galvanik", "tonnes": 500, "incoterm": "DAP", "qp": "M+1", "premium": 245}
lme = 2880
trade["tonnes"] = 450
trade["premium"] = trade["premium"] + 5
trade["status"] = "provisional"
final_price = trade.get("final_price")
value = trade["tonnes"] * (lme + trade["premium"])
```

```python test "amendments applied"
assert trade["tonnes"] == 450, f"trade['tonnes'] is {trade['tonnes']}; set it to 450."
assert trade["premium"] == 250, f"trade['premium'] is {trade['premium']}; increase 245 by 5."
```

```python test "status added"
assert trade.get("status") == "provisional", f"status is {trade.get('status')!r}; add the key 'status' with value 'provisional'."
```

```python test "final_price via get"
assert final_price is None, f"final_price is {final_price!r}; the trade has no 'final_price' key, so .get() should return None."
assert "final_price" not in trade, "Don't add 'final_price' to the trade; just read it with .get()."
```

```python test "value = 1,408,500"
assert value == 1408500, f"value is {value}; expected 450 x (2,880 + 250) = 1,408,500."
```

### Hint 1
Assignment works on dict keys just like variables: `trade["tonnes"] = ...`.

### Hint 2
`trade.get("final_price")` returns `None` when the key is missing, without raising `KeyError`.

### Hint 3
```python
trade["tonnes"] = 450
trade["premium"] = trade["premium"] + 5
trade["status"] = "provisional"
final_price = trade.get("final_price")
value = trade["tonnes"] * (lme + trade["___"])
```

## Cards

### Card recall
concept: dicts
Q: What's the difference between `trade["final_price"]` and `trade.get("final_price")` when the key is missing?
A: `trade["final_price"]` raises `KeyError`. `.get()` returns `None` (or the default you pass).

### Card code
concept: dicts
Q: Set the trade's `"incoterm"` to `"CIF"` and add `"insured": True`.
```python starter
trade = {"id": "ZS-00416", "incoterm": "CFR"}
```
```python solution
trade = {"id": "ZS-00416", "incoterm": "CFR"}
trade["incoterm"] = "CIF"
trade["insured"] = True
```
```python test "updated"
assert trade == {"id": "ZS-00416", "incoterm": "CIF", "insured": True}, f"trade is {trade}."
```

## Next
One trade is a dict. A month of trades is a list of dicts, and that's already a trade book.
