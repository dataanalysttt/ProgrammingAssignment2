---
id: l0-m1-l1
title: How the academy works
minutes: 10
xp: 30
concepts: [print]
objectives:
- Run Python in the browser and read its output
- Know the difference between Run and Submit
- Understand XP, reviews, streaks and backups
---

## Learn
Every lesson has the same loop: **read a short explanation → write code → submit it to hidden tests → the key ideas become review cards.**

- **Run** executes your code and shows what it prints. Use it as often as you like.
- **Submit** runs hidden tests. Each test has a name, and when it fails it tells you what was wrong.
- **Hints** come in three steps (nudge → concept → partial code) and cost 5, 10 and 15 XP. Try first; spend XP when stuck.
- Before your first submission you rate your confidence. Over time the Stats page shows whether your confidence matches your accuracy. Traders get paid for that judgment.

Python runs inside your browser (Pyodide). The first run downloads about 10 MB; after that it's cached. Nothing you type leaves the laptop.

`print()` shows a value. Text goes in quotes:

```python example
print("LME zinc cash settlement")
print(2850 + 245)
```

**Your streak** counts days with at least one session. Every 7 days in a row earns a *hedge token* (max 2) that covers a missed day automatically. A Sunday review and one rest day per week are built in.

**Back up.** Progress lives in this browser. Settings → *Export progress* saves a file. You'll get a reminder every 7 days.

## Desk
On a desk, nobody trusts a number they can't reproduce. Running small pieces of code and checking the output before you "submit" is the same habit as checking a provisional invoice against the contract before it goes to the counterparty.

## Exercise
Edit the code so it prints exactly two lines:

1. `Desk: Zinc, Mumbai`
2. the LME price plus the premium, as a number: `2850 + 245`

Click **Run** to check the output yourself, then **Submit**.

```python starter
print("Desk: ???")
```

```python solution
print("Desk: Zinc, Mumbai")
print(2850 + 245)
```

```python test "First line is the desk name"
lines = __stdout__.strip().splitlines()
assert len(lines) >= 1 and lines[0].strip() == "Desk: Zinc, Mumbai", f"First line printed was {(lines[0] if lines else 'nothing')!r}; expected 'Desk: Zinc, Mumbai' (check spelling, comma and capitals)."
```

```python test "Second line is 3095"
lines = __stdout__.strip().splitlines()
assert len(lines) >= 2, "Only one line was printed. Add a second print() for 2850 + 245."
assert lines[1].strip() == "3095", f"Second line was {lines[1]!r}; expected 3095. Print the sum without quotes: print(2850 + 245)."
```

### Hint 1
You need two `print()` calls, one per line.

### Hint 2
Text in quotes is printed as-is. A calculation *without* quotes is evaluated first: `print(1 + 2)` prints `3`, while `print("1 + 2")` prints `1 + 2`.

### Hint 3
```python
print("Desk: Zinc, Mumbai")
print(2850 + ___)
```

## Cards

### Card recall
concept: print
Q: What is the difference between `print("2850 + 245")` and `print(2850 + 245)`?
A: The first prints the text `2850 + 245` (it's a string). The second evaluates the sum and prints `3095`.

## Next
Your first error message: a provisional invoice script that won't run. Can you read what Python is telling you?
