# Design notes

The goal is studying consistently for months, not excitement for two weeks. Every mechanic below either makes showing up easier, makes the learning stick, or keeps you honest about what you know. Nothing uses guilt, loss-aversion copy or streak-shaming.

| # | Mechanic | Where | Why |
|---|---|---|---|
| 1 | **XP and trading-floor ranks** (Ops Analyst → Junior Trader → Trader → Senior Trader → Head of Desk → CRO) | `gamify.js` `RANKS`, `rankInfo` | A rank names an identity you're moving toward, which motivates longer than a raw number. The bar starts with a 10% head start (endowed progress) and fills along `p^1.6`, so it accelerates near the next rank (goal gradient). The true XP and XP-to-next are always printed next to it, so the curve never misleads. |
| 2 | **Streaks with hedge tokens**, max 2 banked | `streakInfo` | Plain streaks punish one bad day so hard that people quit ("what-the-hell effect"). One token per 7-day run covers a miss automatically. The streak is *recomputed from history* every time, so imports and merges can't corrupt it. |
| 2b | **Never miss twice** | home banner | After a miss the copy is "Yesterday was off. Today is the one that counts" with a 5-minute button. Missing one day barely affects habit formation; missing two starts a new (non-)habit. |
| 3 | **5-minute mode** | `#/quick` | Lowers the bar on bad days. One review plus one micro-exercise counts for the streak. The habit is the unit, not the session length. |
| 4 | **SM-2 spaced repetition**, recall and code cards | `srs.js` | Spacing beats massed practice for long-term retention. Cards are retrieval, not recognition: you type the answer before revealing it, or write the code from a starter and run hidden tests. Code cards are graded by the tests; recall cards are self-graded after comparing with the model answer. |
| 5 | **Interleaving** | `srs.interleave` | The queue round-robins across levels, then concepts. Mixing topics feels harder but improves your ability to pick the right tool, which matters on a desk where problems don't arrive labelled by chapter. |
| 6 | **Boss battles** | `lesson.js renderBoss` | Desk scenarios ("4:55pm, the counterparty disputes the final invoice") with a clock and no hints. Mild time pressure is retrieval practice under realistic conditions. XP is paid only on *improvement* over your best, plus a time bonus on a clean sweep, so grinding retries pays nothing. |
| 7 | **Variable rewards: market events** | `maybeMarketEvent`, `content/events.json` | Unpredictable bonuses sustain engagement better than fixed ones. Guard-rails: at most one a day, ~5–18% chance at milestones, never during a boss, always dismissible, never blocking. |
| 8 | **Identity badges** | `ACHIEVEMENTS`, trophy cabinet | Badges describe who you're becoming ("Thinks in Greeks", "Risk Owner", "Knows What It Knows") rather than counting clicks. Several reward process (recovering after a miss, calibration, weekly reflection), not just output. |
| 9 | **Zeigarnik hooks** | `next` teaser, resume card | Every lesson ends with a one-line unsolved problem from the next lesson, and the home screen opens on "Resume where you left off". Unfinished tasks stay on your mind and make starting the next session easier. |
| 10 | **Implementation intention** | setup, home, `intentionStatus` | "I'll study at [time] after [habit]" gives a large follow-through effect compared with plain intentions. Shown daily. If nothing has happened by time + 2h, an in-app (never push) prompt offers 5-minute mode. |
| 11 | **Visible progress** | skill map, heatmap, weekly stats | A map with locked, open and mastered levels shows the whole path. The heatmap shows consistency. **Projects shipped** is the first, highlighted stat because it's the outcome that matters for your career. |
| 12 | **Sunday review ritual** | `#/weekly` | Ten minutes of reflection: what stuck, what didn't, and your weakest concepts, computed from review accuracy, lapses and ease. Saving pulls those concepts' cards into today's queue. |
| 13 | **Desirable difficulty** | all exercises | You write code from a blank or near-blank editor. Hints are progressive and cost XP (5/10/15) so you try first. The model solution appears only after you pass, or after 3 failed submissions with all hints used (then the lesson pays 10 XP). |
| 14 | **Anti-burnout** | activity timer, rest day | After 90 active minutes a day: "Leave something for tomorrow." One rest day per ISO week keeps the streak and is shown separately on the heatmap. |
| 15 | **Confidence vs accuracy** | `exercise.js`, Stats | Before your first submission on each exercise you rate your confidence (50–100%). Stats plots the calibration curve, the Brier score and the over/under-confidence gap. Calibration is a trading skill: sizing a position is a confidence call. |
| — | **Mastery gating and placement** | `content.js` | Level N+1 opens only at 80%+ on level N's boss. Placement tests let you test out of a module, but tested-out lessons still put their cards into review (first review in 3 days), so gaps resurface instead of being skipped. |

## Engineering choices

- **No build step.** ES modules plus one pre-bundled CodeMirror file. You can read and edit every file directly.
- **Python in a Web Worker.** An infinite loop can't freeze the page; a 20-second limit terminates and restarts the worker. The clock starts only after package loading.
- **One grading harness** (`js/harness.py`) runs in Pyodide and in CPython, so `tools/check_content.py` validates exactly what the browser grades.
- **State is one JSON object.** XP is the sum of a per-day log, and the streak is derived from active days. That makes merging two devices a per-day `max`, with no double counting.
- **Storage safety.** Every `localStorage` call is wrapped. If storage is blocked you see a warning banner and the app runs in memory. Another tab's save is adopted in place, so a stale tab never overwrites newer progress. Import keeps a pre-import copy.
- **Private by construction.** No analytics, no external requests except the Pyodide/CodeMirror CDNs (and none at all with the vendored copies). Phone access requires a key and a private-LAN address.
