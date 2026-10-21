---
id: l1-m2-l1
title: Strings and string methods
minutes: 15
concepts: [strings]
objectives:
- Create strings and combine them
- Clean names with strip, upper, title and replace
- Check contents with in, startswith and endswith
---

## Learn
A string is text in quotes, single or double. Strings have **methods**, functions attached with a dot. Methods return a **new** string; the original is unchanged.

```python example
raw = "   rheinwerk galvanik gmbh  "
clean = raw.strip().title()
print(repr(raw), "->", repr(clean))
print("GMBH" in clean.upper())
```

| Method | Does | Example |
|---|---|---|
| `.strip()` | removes spaces/newlines at both ends | `" DAP\n".strip()` → `"DAP"` |
| `.upper()` / `.lower()` / `.title()` | changes case | `"cif".upper()` → `"CIF"` |
| `.replace(a, b)` | swaps text | `"Sp. z o.o."` → ... |
| `.startswith(x)` / `.endswith(x)` | checks ends → bool | `"ZS-00412".startswith("ZS")` |
| `x in s` | substring check → bool | `"GmbH" in name` |
| `len(s)` | number of characters | `len("SHG")` → `3` |

`+` joins strings: `"LME " + "zinc"`. You can't add a string and a number: `"Price: " + 2850` is a `TypeError`. Convert with `str()` or use an f-string (lesson 4).

Common gotcha: `name.strip()` alone does nothing useful. You must keep the result: `name = name.strip()`.

## Desk
The same counterparty shows up as "RHEINWERK GALVANIK GMBH", "Rheinwerk Galvanik GmbH " and "rheinwerk galvanik" across the CRM, the contract and the bank remittance. Exposure reports that don't normalise names undercount risk on that name, which is how credit limits get breached without anyone noticing.

## Exercise
Clean three fields copied from an email:

- `counterparty`: strip spaces, then convert to title case
- `incoterm`: strip and upper-case
- `is_gmbh`: `True` if the cleaned counterparty ends with `"Gmbh"` (that's how `.title()` writes it)
- `label`: the cleaned counterparty, then `" / "`, then the incoterm, joined with `+`

```python starter
counterparty_raw = "   RHEINWERK GALVANIK GMBH \n"
incoterm_raw = " dap "

```

```python solution
counterparty_raw = "   RHEINWERK GALVANIK GMBH \n"
incoterm_raw = " dap "
counterparty = counterparty_raw.strip().title()
incoterm = incoterm_raw.strip().upper()
is_gmbh = counterparty.endswith("Gmbh")
label = counterparty + " / " + incoterm
```

```python test "counterparty cleaned"
assert counterparty == "Rheinwerk Galvanik Gmbh", f"counterparty is {counterparty!r}; expected 'Rheinwerk Galvanik Gmbh' (strip, then title)."
```

```python test "incoterm = 'DAP'"
assert incoterm == "DAP", f"incoterm is {incoterm!r}; expected 'DAP' (strip and upper)."
```

```python test "is_gmbh is True"
assert is_gmbh is True, f"is_gmbh is {is_gmbh!r}; use counterparty.endswith('Gmbh') on the CLEANED name."
```

```python test "label"
assert label == "Rheinwerk Galvanik Gmbh / DAP", f"label is {label!r}; expected 'Rheinwerk Galvanik Gmbh / DAP'."
```

### Hint 1
Methods can be chained left to right: `.strip()` first, then `.title()`.

### Hint 2
`.endswith("Gmbh")` returns a bool. Use it on the cleaned string, because the raw one ends with a space and a newline.

### Hint 3
```python
counterparty = counterparty_raw.strip().title()
incoterm = incoterm_raw.strip().___()
label = counterparty + " / " + incoterm
```

## Cards

### Card recall
concept: strings
Q: After `ref = " ZS-1 "` and `ref.strip()`, what is `ref`, and why?
A: Still `" ZS-1 "`. Strings are immutable and `.strip()` returns a new string; you must assign it: `ref = ref.strip()`.

### Card code
concept: strings
Q: Set `clean` to `raw` stripped and upper-cased.
```python starter
raw = "  cfr  "
```
```python solution
raw = "  cfr  "
clean = raw.strip().upper()
```
```python test "clean = 'CFR'"
assert clean == "CFR", f"clean is {clean!r}; expected 'CFR'."
```

## Next
Your contract references look like "ZN-26-0412-DAP-RTM". Every part means something. Can you pull out the year and the delivery port with two characters of code?
