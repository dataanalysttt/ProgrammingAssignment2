# Build phases

| Phase | Scope | Status |
|---|---|---|
| 1 | Engine (Pyodide runner, editor, grader), XP/streaks/SRS, export/import/merge, skill map, home, data generator, iPhone access, **Level 0 + Level 1 written**, Levels 2–8 outlined with objectives | **done** |
| 2 | Level 2 (Data Handling) + Level 3 (Market Data & Visualisation): lessons, bosses, placement tests, both CV projects | next |
| 3 | Level 4 (Physical Economics) + Level 5 (Derivatives, incl. NSE index options) | |
| 4 | Level 6 (Risk) + Level 7 (Systematic Trading) | |
| 5 | Level 8, integrated capstone, polish | |

## Phase 1 test checklist (click through)

1. `./start.sh` (or `start.bat`) opens <http://127.0.0.1:8000/> on the setup screen. Fill in your why, time and habit.
2. Lesson *How the academy works*: **Run example** shows output (the first run loads Python; the dot in the header turns green).
3. Pick a confidence, then Submit wrong code: failed tests explain exactly what's wrong. Take **Hint**: XP cost shown.
4. Submit correct code: "Lesson complete", a teaser for the next lesson, a toast of +XP.
5. **Home**: review queue (0 due until tomorrow), resume card with the teaser, streak "Today counted", rank bar, 5-minute button, skill map, heatmap.
6. **5-minute mode**: one card + one micro-exercise; passing it counts the day.
7. **Map → Level 0 → Orientation check**: Start the clock, solve, see the score; Level 1 unlocks with a celebration.
8. **Level 1 placement test** opens even while Level 1 is locked; finishing it shows which modules you tested out of.
9. **Stats**: calibration chart appears after 3+ confidence calls. **Trophies**: earned badges. **Weekly review**: save pushes weak concepts into today's queue.
10. **Settings → Export progress** downloads JSON; **Import (merge)** of that file changes nothing (idempotent).
11. **Settings → Check all lesson content**: "0 problem(s)". **Run formula reference tests**: "12/12 passed".
12. Theme toggle (`t`), `Ctrl+Enter` runs code, `?` shows shortcuts.
13. iPhone: run `start-phone`, open the printed link in Safari, Add to Home Screen, complete a lesson. Then **Save my progress to laptop** on the phone and **Merge in laptop copy** on the laptop.

## Prompt for Phase 2

Paste this into a new session in this repository:

```
Continue building Commodity Quant Academy (folder commodity-quant-academy/). Phase 1 is complete: read
README.md, CONTENT_GUIDE.md, DESIGN_NOTES.md and PHASES.md first, and follow CONTENT_GUIDE.md exactly
(Markdown lessons, every assert with a specific message, 3 progressive hints, desk box, recall + code
cards, a "Next" teaser, Python-computed expected values).

Phase 2: write Level 2 (Data Handling) and Level 3 (Market Data & Visualisation) in full, using the
module/lesson outline and objectives already in content/level-2/level.json and content/level-3/level.json
(you may refine titles). For each level:
- every lesson file (3-6 per module), one boss battle per module (desk scenario, timed), a placement test
  (2 items per module, `## Exercise module=...`), and a level boss with passMark 0.8;
- the CV project: Level 2 "Physical Trade Book Analyser" (open positions by month, metal, counterparty
  and Incoterm; QP exposure report) and Level 3 "Base Metals Market Dashboard" (curve shape, cash-3M and
  regional spreads, vol regime), each with brief, acceptance criteria, starter template, tests computed
  from data/ (robust to regenerating with another seed), interview card and CV bullet;
- use the datasets in data/ (pandas, numpy, sqlite3, matplotlib all work in Pyodide); add any new
  formula to reference/formulas.py with a known-value test in reference/test_formulas.py;
- set "status": "ready" in each level.json when done.
Validate with `python tools/check_content.py` (0 problems) and `python -m pytest reference -q`, then also
in the browser (Settings -> Check all lesson content). Note: pandas/matplotlib tests in the browser need
the full Pyodide (CDN or vendored full release). Commit to a feature branch and push. Finish with: file
tree, run instructions, a click-through test checklist, and the exact prompt for Phase 3.
```
