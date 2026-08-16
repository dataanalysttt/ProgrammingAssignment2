# Life Tracker

A native iOS app for one person: you. Everything lives in SwiftData on your
phone — no backend, no accounts, no analytics, no crash reporters. The only
network calls are the ones you explicitly trigger (HealthKit and EventKit are
on-device frameworks, not network calls at all; Zerodha is the one real
network integration, and it's off until you turn it on and connect it
yourself in Settings).

This app is not signed for the App Store and isn't meant to be. You build it
with your own free Apple ID and run it straight to your own iPhone.

## Requirements

- A Mac with a recent Xcode (Xcode 26+, since the app targets iOS 26 for the
  on-device Assistant module — see below).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — this repo ships a
  `project.yml` spec instead of a committed `.xcodeproj`, because a
  hand-written project file can't be verified without Xcode, while a
  regenerated one always opens cleanly. Install once with:
  ```
  brew install xcodegen
  ```
- An iPhone on iOS 26 or later, and a free (or paid) Apple ID signed into
  Xcode. For the Assistant module specifically, the phone also needs to
  support Apple Intelligence (iPhone 15 Pro/Pro Max or newer) with it turned
  on in Settings — every other module works regardless.

## First-time setup

1. From the `LifeTracker/` folder (this folder), generate the Xcode project:
   ```
   xcodegen generate
   ```
   This creates `LifeTracker.xcodeproj`. Re-run this command any time you add
   or remove a file — Xcode's file list is generated from what's on disk.
2. Open `LifeTracker.xcodeproj`.
3. Select the `LifeTracker` target → **Signing & Capabilities**.
4. Under **Team**, pick your own Apple ID (add it first via Xcode → Settings
   → Accounts if it's not listed). Xcode will offer to fix the bundle
   identifier automatically if `com.dushyantsingh.lifetracker` is taken —
   let it, or change it yourself in `project.yml`'s
   `PRODUCT_BUNDLE_IDENTIFIER` and re-run `xcodegen generate`.
5. Plug in your iPhone (or select it wirelessly), choose it as the run
   destination, and hit **Run**.
6. On the phone, the first launch will fail to open with an "Untrusted
   Developer" alert. Go to **Settings → General → VPN & Device Management**,
   tap your Apple ID under Developer App, and tap **Trust**.

### About free Apple ID signing

With a free Apple ID (no $99/year Developer Program), apps you install this
way stop launching after **7 days** and need to be reinstalled from Xcode —
your data is untouched, only the app binary expires. Plug your phone in and
hit Run again once a week. If you'd rather not think about it, a $99/year
Apple Developer account extends that to a year per install.

## Granting permissions

The app only asks for access when you actually open the relevant screen or
toggle:

- **Health & Fitness** — the first time Today or Insights tries to show
  health data, or when you tap "Allow Health Access" in Settings →
  Integrations. Grant whatever categories you're comfortable with; anything
  you deny just shows as empty rather than crashing.
- **Calendar** — same pattern, triggered from Today's calendar section or
  Settings → Integrations.
- **Face ID** — only asked at the moment you enable App Lock in Settings.

### Whoop data

Life Tracker doesn't talk to Whoop directly. Turn on **Apple Health sync**
in the Whoop app once (Whoop app → Settings → Apple Health), and whatever it
writes — recovery-adjacent heart rate, HRV, sleep — shows up here through the
same HealthKit read used for everything else.

## Connecting Zerodha (optional, off by default)

The Investments module is disabled until you turn it on in Settings →
Modules. To connect it:

1. Go to [developer.kite.trade](https://developer.kite.trade) and create a
   new app of type **Connect**.
2. Set the app's **Redirect URL** to exactly:
   ```
   lifetracker://kite-callback
   ```
3. Copy the app's **API key** and **API secret**.
4. In Life Tracker, go to Settings → Integrations, paste both under
   Credentials, and tap **Save Credentials** (they're written straight to
   the iOS Keychain, accessible only on this device, never in this repo or
   iCloud).
5. Tap **Connect to Zerodha** — this opens Zerodha's real login page in a
   system browser sheet (your password never touches this app), and returns
   you to Life Tracker once you approve.
6. Open the Investments module and tap **Refresh** to pull your current
   holdings and funds and save a snapshot.

**Note on pricing:** this was built against Kite Connect's read-only
holdings/funds endpoints, which is what the brief calls the "Personal" tier.
Zerodha's API pricing has changed more than once over the years — confirm on
developer.kite.trade what your app currently costs before relying on it,
since Zerodha (not this app) sets and changes that. Historical/market-data
endpoints are intentionally never called here; that's why "value over time"
is only ever your own captured snapshots (`InvestmentSnapshot`), not a real
historical chart.

If you ever want to add a second broker, implement `BrokerAdapter`
(`Core/Integrations/Zerodha/BrokerAdapter.swift`) with a new type — nothing
in `Modules/Investments` needs to know or care which adapter it's using.

## The Assistant module

A chat tab that answers questions about your own data — "how's my sleep been
this week," "what are my active goals" — using Apple's on-device Foundation
Models framework (part of Apple Intelligence). It runs the model entirely on
your phone; no network request is ever made, same as everything else in this
app.

Each time you open the tab (or tap the refresh button), `AssistantContextBuilder`
(`Core/Assistant/AssistantContextBuilder.swift`) builds a plain-text summary
of your recent trackers, goals, food, investments, and Whoop-sourced health
metrics, and that summary — nothing else — is handed to the model as its only
source of truth, with instructions not to answer from outside knowledge. It
won't see anything you logged after the conversation started until you tap
refresh.

If Apple Intelligence isn't available or enabled on your phone, the tab
explains why instead of crashing — check **Settings → Apple Intelligence &
Siri** on the device itself if it says it's off.

## How the module system works

Every optional feature — Goals, Insights, Custom Trackers, Calendar, Health,
Food, Investments, Assistant — is a **module**: a `ModuleID` case, a `ModuleDescriptor`
in the registry, and a folder under `Modules/`. Settings → Modules toggles
them on and off via `ModuleSettingsStore`; every screen that shows
module-specific content checks
`ModuleSettingsStore.shared.isEnabled(.someModule)` before showing it.

This is intentionally a plain Swift registry rather than a dynamic
plugin-loading system — for an app only you will ever build, a registry you
can read top-to-bottom in `Core/Modules/ModuleRegistry.swift` is much easier
to safely modify at 11pm than a "real" plugin architecture would be, while
still giving every module exactly one well-defined place to declare itself.

### Adding a new module yourself

1. Add a case to `Core/Modules/ModuleID.swift`.
2. Add a `ModuleDescriptor` for it in `Core/Modules/ModuleRegistry.swift`
   (name, icon, summary, default on/off).
3. Create `Modules/<YourModule>/` with its SwiftUI views. Reuse
   `Core/DesignSystem` (`Card`, `SectionHeader`, `EmptyStateView`,
   `ProgressBar`) so it looks like it belongs.
4. If it needs its own SwiftData model, add a `@Model` class under
   `Core/Data/Models`, register it in `ModelContainerFactory.schema`, and
   (if you want it included in backups) add a DTO to `ExportPayload` and an
   upsert case in `DataExportImportService`.
5. Wire it in wherever it should appear — Today, Insights, or its own entry
   from `ModuleTogglesView`'s `destination(for:)` — behind an
   `isEnabled(.yourModule)` check.

### Adding a new Custom Tracker *type* (not just a new tracker)

Custom Trackers (mood, habits, anything you define from the UI) already
support number / yes-no / scale / duration / text without touching code —
that's what Settings → Modules → Custom Trackers → **New Tracker** is for.
If you want an entirely new *kind* of value (say, a location or a photo),
add a case to `TrackerValueType` in `Core/Data/Support/Enums.swift`, then add
its input control to `TrackerQuickEntryRow.swift` and its editor field to
`CustomTrackerEditView.swift`. `TrackerEntry` already has room for a few
value shapes; add a new optional property there if none fit.

## Project structure

```
LifeTracker/
  project.yml              XcodeGen spec — the source of truth for the Xcode project
  LifeTracker/
    App/                    Entry point, tab bar, Face ID/passcode lock
    Core/
      Assistant/              On-device context builder + Foundation Models session wrapper
      Data/                 SwiftData models, schema, export/import
      DesignSystem/          Shared visual building blocks
      Modules/               Module registry + on/off settings
      Integrations/          HealthKit, EventKit, Zerodha — one folder each
      Utilities/              Small, dependency-free helpers (dates, streaks)
    Modules/                One folder per feature module's SwiftUI screens
    Resources/               Assets.xcassets
  LifeTrackerTests/          Unit tests (streaks, goal progress, export/import)
```

## Your data

Everything is SwiftData, stored in the app's local container on your phone
only (`ModelContainerFactory.swift` — no CloudKit, no remote configuration).
Settings → Export & Import writes a full JSON backup (re-importable, merges
by id so importing twice is safe) or a flat CSV (for opening in
Numbers/Excel — one-way, since goals/investments don't map cleanly back from
a spreadsheet). Use the JSON export as your actual backup before ever
deleting the app or resetting your phone.

## Running the tests

In Xcode: `Cmd+U`, or from the command line:
```
xcodebuild test -project LifeTracker.xcodeproj -scheme LifeTracker -destination 'platform=iOS Simulator,name=iPhone 15'
```
Covers streak math, goal progress calculation (including the manual-progress
and tracker-linked cases), and the export → import round trip.

## Known rough edges to expect on first run

- **Foundation Models is a very new API.** The Assistant module was written
  against Apple's iOS 26 framework without access to a Mac to compile-check
  it, so it's the single most likely spot to throw a build error on first
  run — if it does, the fix is almost always a small signature mismatch in
  `AssistantService.swift`, not a design problem.
- **HealthKit/Calendar data isn't cached** — every screen queries live, on
  purpose, so this app never holds a stale copy of your health record. This
  means Insights can take a beat to load on a slow connection to Health;
  there's no network involved, just on-device query time.
- **Investments has no historical chart from Zerodha** — see the pricing
  note above; "value over time" is only as good as how often you tap
  Refresh.
