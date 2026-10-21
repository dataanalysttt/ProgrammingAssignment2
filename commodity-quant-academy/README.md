# Commodity Quant Academy

A private, local-only, gamified Python course that goes from first `print()` to CV-ready projects in commodity trading, derivatives and risk. All examples come from a physical base-metals desk: zinc, the LME, QP pricing, Incoterms, freight, FX and hedges.

- Runs on your laptop at `127.0.0.1`. No login, no cloud, no analytics, no tracking.
- Python runs **in the browser** (Pyodide), so there's nothing to install for lessons.
- Optional **iPhone access** over your home Wi-Fi, protected by a secret key.

## Start

You need Python 3.9+ (only to serve the files).

| | Mac / Linux | Windows |
|---|---|---|
| Laptop only | `./start.sh` | double-click `start.bat` |
| Laptop + iPhone | `./start-phone.sh` | double-click `start-phone.bat` |

Then open <http://127.0.0.1:8000/>.

The scripts run `serve.py`, a standard-library server equivalent to `python -m http.server 8000 --bind 127.0.0.1` with laptop↔iPhone progress sync added. Plain `python -m http.server 8000 --bind 127.0.0.1` also works; only the sync buttons disappear.

> Don't open `index.html` by double-clicking it. Browsers block the module loading and data fetches the app needs from `file://` pages.

## Using it on your iPhone

1. On the laptop run `start-phone.sh` / `start-phone.bat`. It prints two private links, for example:
   ```
   http://my-laptop.local:8000/?key=Xy3k...   (stable: survives IP changes)
   http://192.168.1.23:8000/?key=Xy3k...
   ```
2. With the iPhone on the **same Wi-Fi**, open one link in Safari. The key is saved as a cookie, so you only enter it once.
3. Share → **Add to Home Screen**. It now opens full-screen like an app.
4. Keep the laptop running `start-phone` while you study on the phone.

**Who can get in:** `127.0.0.1` (your laptop), plus devices on a private LAN address that present the key. Anyone else gets "Locked". Rotate the key with `python serve.py --phone --new-key`. On Windows, allow Python through the firewall for **Private** networks only. Traffic is plain HTTP inside your home network; don't use phone mode on public or office Wi-Fi.

**iPhone details handled for you**
- A symbol key bar (Tab, brackets, colon, quotes) sits above the editor on touch screens.
- Curly "smart quotes" from the iOS keyboard are converted to straight quotes before your code runs.
- Settings → Editor → *Plain text* gives a simpler editor if CodeMirror feels fiddly on the phone.
- Inputs use 16 px text so Safari doesn't zoom on focus. Layouts respect the notch and home-indicator safe areas.

**Progress on two devices.** Browser storage is per device *and* per address, so phone and laptop keep separate progress. Use Settings → **Save my progress to laptop** on one device and **Merge in laptop copy** on the other (merge never double-counts XP). Always use the same link on the phone: if the address changes, the phone starts with empty storage. The `.local` link avoids that.

## Backups

Settings → **Export progress** downloads a JSON file. **Import (replace)** restores it; **Import (merge)** combines two devices. You'll get a reminder every 7 days. Laptop-sync copies are also kept as history in `progress-sync/`.

## Offline Pyodide (optional)

By default Pyodide 0.27.7 loads from the jsDelivr CDN and is then cached by the browser. To run fully offline:

1. Download `pyodide-0.27.7.tar.bz2` from <https://github.com/pyodide/pyodide/releases/tag/0.27.7>.
2. Extract its `pyodide/` folder to `vendor/pyodide/`, so that `vendor/pyodide/pyodide.js` exists.

The app checks for `vendor/pyodide/pyodide.js` first and only falls back to the CDN when it's missing. The full release includes numpy, pandas, scipy and matplotlib. (`npm pack pyodide@0.27.7` gives only the core, enough for Levels 0–1.) CodeMirror is already bundled in `vendor/codemirror.bundle.js`, so the editor works offline.

## Data

`data/` holds **synthetic** datasets: LME-style cash/3M prices with contango and backwardation regimes, forward curves, a physical trade book (41 fictional counterparties, 10–12 kt/month), freight, USD/INR and EUR/USD, option chains and an index series. No licensed exchange data is included. Regenerate with:

```
pip install numpy pandas
python data/generate_data.py            # or --seed 7 for a different world
```

Column dictionary: [`data/README.md`](data/README.md).

## Checks

- `python -m pytest reference -q` checks every financial formula (QP averaging, invoicing, carry, Black-76 and Greeks, VaR/CVaR, hedge ratio) against textbook values. The same tests run in the app: Settings → *Run formula reference tests*.
- Settings → *Check all lesson content* runs every model solution against its hidden tests in Pyodide, and checks that every starter fails at least one test.
- `python tools/check_content.py` does the same in CPython (needs Node for parsing).

## Folder map

```
index.html, css/, js/          app shell, engine and views (no build step)
js/harness.py                  grading harness shared by Pyodide and CPython
content/                       curriculum as data: manifest.json, level-N/level.json, lesson .md files
content/_templates/            copy these to write new lessons
data/                          synthetic datasets + generate_data.py
reference/                     formula answer key + reference tests
tools/                         content validation
vendor/                        CodeMirror bundle (+ optional offline Pyodide)
serve.py, start*.sh/.bat       local server and launchers
CONTENT_GUIDE.md               lesson schema and authoring rules
DESIGN_NOTES.md                why each learning/gamification mechanic exists
PHASES.md                      build status and the prompt for the next phase
```

Keyboard: `Ctrl/⌘+Enter` run, `Ctrl/⌘+Shift+Enter` submit, `g h/r/m/s` navigate, `5` five-minute mode, `t` theme, `?` help.
