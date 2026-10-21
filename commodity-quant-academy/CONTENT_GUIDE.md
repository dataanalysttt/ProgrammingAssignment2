# Content guide

Lessons are **data**: one Markdown file per lesson in `content/level-N/`, listed in that level's `level.json`. The engine never needs to change to add or edit a lesson.

## 1. Add a lesson in three steps

1. Copy `content/_templates/lesson.md` to e.g. `content/level-2/m1/l1-files.md` and fill it in.
2. In `content/level-2/level.json`, give the lesson entry a `file` (path relative to the level folder). An entry without `file` shows as "planned".
   ```json
   { "id": "l2-m1-l1", "file": "m1/l1-files.md", "title": "Reading and writing text files" }
   ```
   The `id` in `level.json` must match the `id` in the file's front matter.
3. Validate: Settings → **Check all lesson content** (in the app), or `python tools/check_content.py l2-m1`.

When a whole level is written, set `"status": "ready"` in its `level.json`.

## 2. Lesson object (what the parser produces)

```jsonc
{
  "id": "l1-m1-l1",                 // l{level}-m{module}-l{lesson}; bosses: l1-m1-boss, l1-boss; l1-placement; l1-project
  "type": "lesson",                 // lesson | boss | placement | project
  "title": "…", "minutes": 15, "xp": 50,
  "concepts": ["variables"],        // first concept tags this lesson's review cards (weak-concept stats use it)
  "objectives": ["…"],
  "status": "ready",                // or "planned"
  "timeLimit": 600, "passMark": 0.8, // bosses only (seconds; level bosses gate the next level)
  "datasets": ["trade_book.csv"],   // copied into Pyodide at data/<name>; any "data/x.csv" in code is also detected
  "learn": "markdown", "desk": "markdown", "next": "one-line teaser",
  "exercises": [{
    "id": "l1-m1-l1.ex1", "module": "l1-m1",   // module: placement items only
    "prompt": "markdown", "setup": "hidden python run before the learner's code",
    "starter": "python", "solution": "python",
    "tests": [{ "name": "shown to learner", "code": "hidden python with asserts" }],
    "hints": ["nudge", "concept", "partial code"]
  }],
  "cards": [{ "id": "l1-m1-l1#c1", "kind": "recall", "concept": "…", "q": "…", "a": "…" },
            { "id": "l1-m1-l1#c2", "kind": "code", "concept": "…", "q": "…", "starter": "…", "solution": "…", "tests": [] }],
  "project": { "brief": "…", "acceptance": "…", "interview": "…", "cvBullet": "…" }   // projects only
}
```

A `.json` file with this shape works as well as Markdown. The Markdown format is easier to edit because code isn't escaped.

## 3. Markdown format

````markdown
---
id: l1-m1-l1
title: "Variables: naming the numbers on an invoice"     # quote titles that contain a colon
minutes: 12
concepts: [variables]
objectives:
- Create variables with clear names
---

## Learn
Markdown: **bold**, `code`, tables, lists, > quotes.
```python example
print("runnable: gets Run / Copy-to-editor buttons")
```

## Desk
Why this matters on a desk (required for lessons).

## Exercise
Prompt in Markdown.
```python setup
incoterm = "CIF"          # hidden; optional
```
```python starter
# what the learner sees
```
```python solution
# model answer: must pass every test
```
```python test "Name shown to the learner"
assert x == 1, f"Specific feedback: x is {x}; expected 1 because …"
```
### Hint 1
Nudge.
### Hint 2
Concept.
### Hint 3
Partial code.

## Cards
### Card recall
concept: variables
Q: Question (multi-line OK)
A: Answer
### Card code
concept: variables
Q: Write-the-code prompt
```python starter
```
```python solution
```
```python test "name"
assert …, "message"
```

## Next
One-line teaser of the next lesson's problem.
````

Other section names: `## Scenario` (bosses, same as Learn), `## Brief`, `## Acceptance`, `## Interview`, `## CV bullet` (projects). Multiple `## Exercise` sections are allowed. For placement items write `## Exercise module=l1-m3`; boss tasks can use `## Exercise title="Parse"`.

## 4. Writing tests

Tests run in a **copy** of the learner's namespace after their code. Available helpers:

| Helper | Use |
|---|---|
| `approx(a, b, tol=0.01)` | float comparison |
| `__stdout__` | everything the learner printed |
| `rerun(**inputs)` | re-run the learner's code with different input variables (set after `setup`) and get its namespace. Use it to test decision logic on many inputs before functions are taught. |
| `import formulas as ref` | the reference implementations in `reference/formulas.py` |

Rules (the checker enforces the first three):
- **Every `assert` has a message** that says what was wrong and what was expected, with the numbers: `f"value is {value:,}; expected 2,000 t x 3,055 = 6,110,000."`
- The model solution passes every test, and the starter fails at least one.
- Lessons have exactly three hints: nudge → concept → partial code. Bosses and placement items have none.
- Compute expected values with Python, not by hand. The checker caught several hand-computed mistakes while Level 1 was written.
- Tests that depend on `data/` should compute the expected value from the data (see `level-1/project.md`), so they still pass if the data is regenerated with another seed.
- Prefer write-the-code exercises from a near-blank editor. Use multiple choice only for quick concept checks.

## 5. Style

- Examples from the desk: zinc and base metals, LME, QP, Incoterms, freight, FX, counterparties, invoices, hedges. No generic "apples" data.
- Concise, direct, no filler or fake encouragement.
- Each lesson takes 10–20 minutes. Each module has 3–6 lessons plus a boss; each level has 4–8 modules, a level boss (80% to pass) and a CV project.
- Financial maths must match `reference/formulas.py`. Add a function and a known-value test there for any new formula.
