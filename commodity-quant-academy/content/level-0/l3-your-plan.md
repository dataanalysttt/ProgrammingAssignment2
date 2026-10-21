---
id: l0-m1-l3
title: Your plan, in numbers
minutes: 12
xp: 40
concepts: [variables-intro]
objectives:
- Use variables to hold numbers
- Turn a weekly study plan into a finish date estimate
- Write your implementation intention
---

## Learn
At setup you wrote an *implementation intention*: "I'll study at [time] after [habit]." Attaching a new habit to an existing one (morning chai, the commute) beats relying on motivation. You can edit it any time in Settings.

Now check the plan with arithmetic. A **variable** is a name for a value:

```python example
sessions_per_week = 5
minutes_per_session = 20
weekly_minutes = sessions_per_week * minutes_per_session
print(weekly_minutes)
```

`*` multiplies, `/` divides, `+` and `-` do what you expect. `/` always gives a decimal (a *float*): `120 / 60` is `2.0`.

Level 1 has 23 lessons of roughly 15 minutes, plus 6 boss battles of about 10 minutes and a project of about 120 minutes.

## Desk
Desks run on capacity planning: tonnes per month, vessels per quarter, credit lines per counterparty. If 10 kt/month has to ship, you work back to containers, bookings and dates. Treat your learning the same way: hours available decide the finish date, not hope.

## Exercise
Create these variables:

- `sessions_per_week = 5` and `minutes_per_session = 25`
- `weekly_minutes`: sessions per week × minutes per session
- `level1_minutes`: 23 lessons × 15 + 6 bosses × 10 + 120 for the project
- `weeks_to_finish`: `level1_minutes / weekly_minutes`

Then print `weeks_to_finish`.

```python starter
sessions_per_week = 5
minutes_per_session = 25

```

```python solution
sessions_per_week = 5
minutes_per_session = 25
weekly_minutes = sessions_per_week * minutes_per_session
level1_minutes = 23 * 15 + 6 * 10 + 120
weeks_to_finish = level1_minutes / weekly_minutes
print(weeks_to_finish)
```

```python test "weekly_minutes = 125"
assert weekly_minutes == 125, f"weekly_minutes is {weekly_minutes}; expected 5 x 25 = 125."
```

```python test "level1_minutes = 525"
assert level1_minutes == 525, f"level1_minutes is {level1_minutes}; expected 23*15 + 6*10 + 120 = 525. Python does * before +, so no extra brackets are needed."
```

```python test "weeks_to_finish = 4.2"
assert approx(weeks_to_finish, 4.2), f"weeks_to_finish is {weeks_to_finish}; expected 525 / 125 = 4.2."
assert "4.2" in __stdout__, "Print weeks_to_finish so you can see the result."
```

### Hint 1
Each bullet is one line of the form `name = expression`.

### Hint 2
Python follows normal maths order: `*` and `/` before `+` and `-`. So `23 * 15 + 6 * 10 + 120` is already correct.

### Hint 3
```python
weekly_minutes = sessions_per_week * minutes_per_session
level1_minutes = 23 * 15 + 6 * 10 + 120
weeks_to_finish = ___ / ___
```

## Cards

### Card recall
concept: variables-intro
Q: What does `120 / 60` give in Python, and what type is it?
A: `2.0`, a float. `/` always returns a float, even when the division is exact.

## Next
Already know some Python? The placement test lets you skip modules you've already got.
