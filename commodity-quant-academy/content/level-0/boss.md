---
id: l0-boss
type: boss
title: "Orientation check: first day on the desk"
minutes: 5
timeLimit: 300
passMark: 0.8
concepts: [print, errors-reading]
---

## Scenario
First morning on the zinc desk. Your desk head drops a broken script on your screen: "This should give me the gross value of the Rheinwerk cargo. Fix it and print the number. You've got five minutes."

## Exercise
The cargo is **750 t** at LME **2,812** plus a premium of **248** USD/t. Fix the script so that:

- it runs without errors,
- `gross_value` equals tonnes × (LME + premium),
- the last line printed is the gross value.

```python starter
tonnes = 750
lme = 2812
premium = 248
gross_value = tonnes * (lme + premum)
print("Cargo: Rheinwerk Galvanik)
print(gross_valu)
```

```python solution
tonnes = 750
lme = 2812
premium = 248
gross_value = tonnes * (lme + premium)
print("Cargo: Rheinwerk Galvanik")
print(gross_value)
```

```python test "Script runs"
assert "gross_value" in dir(), "gross_value is not defined. Fix the errors from the top down."
```

```python test "gross_value = 2,295,000"
assert gross_value == 2295000, f"gross_value is {gross_value}; expected 750 x (2812 + 248) = 2,295,000."
```

```python test "Cargo line printed"
assert "Cargo: Rheinwerk Galvanik" in __stdout__, "The cargo line should print 'Cargo: Rheinwerk Galvanik'. Is the closing quote there?"
```

```python test "Last line is the value"
assert __stdout__.strip().splitlines()[-1].strip() == "2295000", "The last printed line should be the value 2295000."
```

```python test "Premium uses the right variable"
assert "premum" not in globals(), "Don't create a new variable called premum: fix the typo so the existing premium is used."
```
