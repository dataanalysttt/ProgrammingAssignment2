---
id: l1-m2-l3
title: "split and join: parsing a recap line"
minutes: 15
concepts: [split-join]
objectives:
- Split delimited text into a list of fields
- Unpack fields into named variables
- Join a list back into text with a separator
---

## Learn
`.split(sep)` cuts a string at every `sep` and returns a **list** of pieces. `sep.join(list)` does the reverse.

```python example
recap = "2026-03-14|Rheinwerk Galvanik|500|DAP|M+1"
parts = recap.split("|")
print(parts)
print(parts[2], type(parts[2]))
```

The pieces are still strings, so convert numbers before using them. You can **unpack** a list straight into variables when you know how many fields there are:

```python example
date, buyer, qty, incoterm, qp = "2026-03-14|Rheinwerk|500|DAP|M+1".split("|")
print(buyer, int(qty) * 2)
```

`split()` with no argument splits on any run of whitespace and drops empty pieces, which is handy for messy, space-aligned text.

Going back the other way:

```python example
fields = ["ZS-00412", "Rheinwerk", "500", "DAP"]
print(";".join(fields))
```

`join` only accepts strings: `",".join([1, 2])` is a `TypeError`.

## Desk
Recaps, bank MT messages and warehouse reports are all delimited text. Parsing them reliably is how you build an exceptions list (trades in the recap that aren't in the system) in minutes instead of an afternoon of copy-paste.

## Exercise
Parse `recap` and create:

- `trade_date`, `buyer`, `incoterm`, `qp`: strings (strip each one)
- `tonnes`: int
- `premium`: float
- `csv_line`: the fields `buyer`, `tonnes`, `incoterm` joined with commas, e.g. `"Rheinwerk Galvanik,500,DAP"`

```python starter
recap = "2026-03-14 | Rheinwerk Galvanik | 500 | DAP | M+1 | 247.5"

```

```python solution
recap = "2026-03-14 | Rheinwerk Galvanik | 500 | DAP | M+1 | 247.5"
fields = [f.strip() for f in recap.split("|")]
trade_date, buyer, qty, incoterm, qp, prem = fields
tonnes = int(qty)
premium = float(prem)
csv_line = ",".join([buyer, str(tonnes), incoterm])
```

```python test "text fields are clean"
assert buyer == "Rheinwerk Galvanik", f"buyer is {buyer!r}; did you strip the spaces around each field?"
assert trade_date == "2026-03-14" and incoterm == "DAP" and qp == "M+1", f"Got trade_date={trade_date!r}, incoterm={incoterm!r}, qp={qp!r}; strip every field."
```

```python test "numbers converted"
assert tonnes == 500 and isinstance(tonnes, int), f"tonnes is {tonnes!r}; expected the int 500."
assert premium == 247.5 and isinstance(premium, float), f"premium is {premium!r}; expected the float 247.5."
```

```python test "csv_line"
assert csv_line == "Rheinwerk Galvanik,500,DAP", f"csv_line is {csv_line!r}; expected 'Rheinwerk Galvanik,500,DAP'. join needs strings, so use str(tonnes)."
```

### Hint 1
Split on `"|"` first, then deal with the spaces around each piece.

### Hint 2
Unpacking: `a, b, c = ["x", "y", "z"]`. You can strip each field as you assign it, or strip all of them first. `",".join(...)` needs a list of strings.

### Hint 3
```python
parts = recap.split("|")
trade_date = parts[0].strip()
buyer = parts[1].strip()
tonnes = int(parts[2])
# ... and so on
csv_line = ",".join([buyer, str(tonnes), incoterm])
```

## Cards

### Card recall
concept: split-join
Q: What does `"ZS-1|500|DAP".split("|")` return, and what type is `500` in it?
A: `["ZS-1", "500", "DAP"]`, a list of strings. `"500"` is still text until you convert it with `int()`.

### Card code
concept: split-join
Q: Set `line` to the list `cells` joined with semicolons.
```python starter
cells = ["ZS-00412", "Rheinwerk", "DAP"]
```
```python solution
cells = ["ZS-00412", "Rheinwerk", "DAP"]
line = ";".join(cells)
```
```python test "line"
assert line == "ZS-00412;Rheinwerk;DAP", f"line is {line!r}; use ';'.join(cells)."
```

## Next
Finance wants the invoice line as "Rheinwerk Galvanik | 2,000.000 t @ USD 3,055.00 = USD 6,110,000.00". One f-string does it.
