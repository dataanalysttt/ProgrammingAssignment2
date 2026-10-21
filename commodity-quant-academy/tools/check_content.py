"""
check_content.py: validates every lesson with real CPython (needs Node for parsing, plus
numpy/pandas for later levels). The app has the same check under Settings -> Checks.

    python tools/check_content.py            # all lessons
    python tools/check_content.py l1-m3      # only ids starting with l1-m3

For each exercise and code card: the model solution must pass every test, the starter must
fail at least one, and every test should carry an assert message (specific feedback).
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

APP = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(APP / "js"))
sys.path.insert(0, str(APP / "reference"))
import harness  # noqa: E402

os.chdir(APP)  # so "data/x.csv" resolves like it does in Pyodide
prefix = sys.argv[1] if len(sys.argv) > 1 else ""
dump = json.loads(subprocess.run(["node", str(APP / "tools/dump_content.mjs")], capture_output=True, text=True, check=True).stdout)

problems, checked = [], 0


def check(label, item):
    global checked
    checked += 1
    tests = item.get("tests") or []
    if not item.get("solution") or not tests:
        problems.append(f"{label}: missing solution or tests")
        return
    good = harness.run(item["solution"], item.get("setup", ""), tests)
    bad = [t for t in good["tests"] if not t["passed"]]
    if good["error"] or bad:
        problems.append(f"{label}: SOLUTION FAILS {good['error'] or ''} {[t['name'] + ': ' + t['message'] for t in bad]}")
    start = harness.run(item.get("starter", ""), item.get("setup", ""), tests)
    if all(t["passed"] for t in start["tests"]):
        problems.append(f"{label}: starter already passes every test")
    for t in tests:
        for line in t["code"].splitlines():
            if line.strip().startswith("assert ") and not re.search(r",\s*[fr]?[\"']", line):
                problems.append(f"{label} / {t['name']}: assert without a failure message: {line.strip()}")


for row in dump["lessons"]:
    if not row["entryId"].startswith(prefix):
        continue
    if row.get("missing"):
        problems.append(f"{row['file']}: listed in level.json but the file does not exist")
        continue
    les = row["lesson"]
    if les["id"] != row["entryId"]:
        problems.append(f"{row['file']}: id {les['id']!r} != level.json {row['entryId']!r}")
    if les["type"] == "lesson" and not les["desk"]:
        problems.append(f"{row['file']}: no 'Why this matters on a desk' section")
    if les["type"] == "lesson" and les["exercises"] and any(len(ex["hints"]) < 3 for ex in les["exercises"]):
        problems.append(f"{row['file']}: lesson exercise with fewer than 3 hints")
    for ex in les["exercises"]:
        check(ex["id"], ex)
    for c in les["cards"]:
        if c["kind"] == "code":
            check(c["id"], c)
        elif not c["q"] or not c["a"]:
            problems.append(f"{c['id']}: recall card missing Q or A")
if not prefix:
    for group in ("events", "micro"):
        for ev in dump["events"][group]:
            if ev.get("kind", "challenge") != "bonus":
                check(f"{group}:{ev['id']}", ev)

print(f"checked {checked} exercises/cards")
for p in problems:
    print("  ✗", p)
sys.exit(1 if problems else 0)
