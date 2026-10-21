---
id: l1-m2-l2
title: Indexing and slicing contract references
minutes: 15
concepts: [slicing]
objectives:
- Index characters from the front and the back
- Slice with [start:stop] and understand stop is excluded
- Find positions with .find()
---

## Learn
Each character in a string has a position, starting at **0**. Negative indexes count from the end.

```
 Z  N  -  2  6  -  0  4  1  2  -  D  A  P  -  R  T  M
 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17
                                              -3 -2 -1
```

```python example
ref = "ZN-26-0412-DAP-RTM"
print(ref[0], ref[-1])
print(ref[3:5])      # from 3 up to, NOT including, 5
print(ref[-3:])      # last three characters
print(ref[:2])       # from the start
```

`s[start:stop]` includes `start` and excludes `stop`, so `stop - start` is the length of the slice. Leaving out `start` means "from the beginning"; leaving out `stop` means "to the end".

`s.find("DAP")` returns the index where `"DAP"` starts, or `-1` if it's not there.

Slicing works when the format is fixed-width. For delimited text (`-`, `|`, `,`) the next lesson's `.split()` is more robust.

## Desk
Contract and trade references encode metal, year, sequence, Incoterm and port. Being able to pull fields out of references quickly is what lets you reconcile a bank's payment advice against open invoices without retyping anything.

## Exercise
Reference format: `MM-YY-NNNN-INC-PPP` (metal, year, sequence, Incoterm, port code). Using indexing and slicing on `ref`, create:

- `metal`: first two characters
- `year`: the integer `2000 + YY` (i.e. 2026)
- `sequence`: characters 6 to 9 as text, i.e. `"0412"`
- `port`: last three characters
- `incoterm`: the three characters before the last `-` and the port

```python starter
ref = "ZN-26-0412-DAP-RTM"

```

```python solution
ref = "ZN-26-0412-DAP-RTM"
metal = ref[:2]
year = 2000 + int(ref[3:5])
sequence = ref[6:10]
port = ref[-3:]
incoterm = ref[-7:-4]
```

```python test "metal = 'ZN'"
assert metal == "ZN", f"metal is {metal!r}; expected 'ZN' = ref[:2]."
```

```python test "year = 2026 (int)"
assert year == 2026 and isinstance(year, int), f"year is {year!r}; take ref[3:5] ('26'), convert with int(), then add 2000."
```

```python test "sequence = '0412'"
assert sequence == "0412", f"sequence is {sequence!r}; positions 6,7,8,9 are ref[6:10] (stop is excluded)."
```

```python test "port and incoterm"
assert port == "RTM", f"port is {port!r}; expected 'RTM' = ref[-3:]."
assert incoterm == "DAP", f"incoterm is {incoterm!r}; expected 'DAP'. Counting from the end, it is ref[-7:-4]."
```

```python test "works for another reference"
r2 = "ZN-27-0099-CIF-DUR"
assert r2[:2] == "ZN" and r2[-7:-4] == "CIF", "Check your slices work on any reference with the same format."
```

### Hint 1
Write the reference out and number the positions from 0. The year is at positions 3 and 4.

### Hint 2
`ref[a:b]` stops *before* `b`. For four characters starting at 6 you need `ref[6:10]`. For the Incoterm, count from the end: `-RTM` takes the last 4 positions.

### Hint 3
```python
metal = ref[:2]
year = 2000 + int(ref[3:5])
sequence = ref[6:___]
port = ref[-3:]
incoterm = ref[-7:___]
```

## Cards

### Card recall
concept: slicing
Q: For `s = "ZN-26-0412"`, what is `s[3:5]` and why does it have two characters?
A: `"26"`. The slice includes index 3 and stops before index 5, so it has 5 − 3 = 2 characters.

### Card code
concept: slicing
Q: Set `port` to the last three characters of `ref`.
```python starter
ref = "ZN-26-0099-CIF-DUR"
```
```python solution
ref = "ZN-26-0099-CIF-DUR"
port = ref[-3:]
```
```python test "port = 'DUR'"
assert port == "DUR", f"port is {port!r}; use a negative slice: ref[-3:]."
```

## Next
A broker recap arrives as one line: "2026-03-14|Rheinwerk|500|DAP|M+1". One method turns it into five clean fields.
