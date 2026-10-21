---
id: l0-m1-l4
title: Where should you start?
minutes: 5
xp: 20
concepts: [orientation]
objectives:
- Decide whether to take the Level 1 placement test
- Know how mastery gating works
---

## Learn
You've touched Python before, but gaps matter more than coverage. Two routes:

1. **Start at Level 1, Module 1.** Best if you can't write a `for` loop or a function from memory right now.
2. **Take the [Level 1 placement test](#/lesson/l1-placement).** 12 short items, two per module, untimed and with no hints. Pass both items of a module and you test out of it: its lessons are marked complete and their review cards still enter your queue, so the knowledge gets checked over the following weeks.

**How levels unlock:** each level ends with a boss battle. Score 80%+ and the next level opens. Testing out of modules doesn't skip the level boss.

**Before Level 1 opens** you need 80% on the orientation check at the end of this level: a 5-minute warm-up on what you've just done.

## Desk
On a desk you're trusted with bigger books as you show you can handle smaller ones. Gating here works the same way: you move up when you've demonstrated the skill, not when the calendar says so.

## Exercise
One line: set `route` to `"placement"` if you'll take the placement test, or `"module1"` if you'll start from the beginning. Both are valid.

```python starter
route = ""
```

```python solution
route = "module1"
```

```python test "route is chosen"
assert route in ("placement", "module1"), f"route is {route!r}; set it to \"placement\" or \"module1\" (with quotes)."
```

### Hint 1
Put one of the two words between the quotes.

### Hint 2
Text values (strings) need quotes: `route = "placement"`.

### Hint 3
```python
route = "module1"
```

## Next
Orientation check: first day on the desk. Five minutes on the clock.
