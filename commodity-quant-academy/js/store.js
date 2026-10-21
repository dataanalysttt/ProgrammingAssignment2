// store.js: all progress lives in one JSON object in localStorage under KEY.
// Every read/write is wrapped in try/catch: private mode or blocked storage falls back
// to memory (with a visible warning) instead of crashing.

const KEY = "cqa-progress-v1";
const VERSION = 1;

export function today(d = new Date()) {
  const p = (n) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}
export function addDays(day, n) {
  const [y, m, d] = day.split("-").map(Number);
  return today(new Date(y, m - 1, d + n));
}
export function daysBetween(a, b) { // b - a in whole days
  const t = (s) => { const [y, m, d] = s.split("-").map(Number); return Date.UTC(y, m - 1, d); };
  return Math.round((t(b) - t(a)) / 86400000);
}
export const uid = () => Date.now().toString(36) + Math.random().toString(36).slice(2, 8);

export function freshState() {
  return {
    version: VERSION,
    createdAt: new Date().toISOString(),
    profile: { why: "", studyTime: "", habit: "", setupDone: false },
    settings: { theme: "auto", plainEditor: false, preloadPython: false, keyBar: "auto" },
    xpLog: {},          // day -> net XP earned that day (hint costs are negative)
    minutesLog: {},     // day -> active minutes
    activeDays: {},     // day -> true when a qualifying session happened
    restDays: {},       // day -> true (planned rest, max 1 per ISO week)
    lessons: {},        // lessonId -> { status, completedAt, xpEarned, hintsUsed, attempts }
    bosses: {},         // lessonId -> { best, attempts: [{ score, seconds, at }] }
    projects: {},       // lessonId -> { shippedAt }
    levels: {},         // levelId -> { masteredAt }
    cards: {},          // cardId -> SM-2 state (see srs.js)
    calibration: [],    // [{ at, id, conf, correct }]
    achievements: {},   // id -> ISO date earned
    events: { lastDay: null, history: [] },
    weekly: [],         // [{ weekOf, stuck, didnt, plan, weak }]
    resume: null,       // { lessonId, at }
    lastTeaser: null,   // { lessonId, text }
    drafts: {},         // exerciseId -> code
    flags: {},          // one-off UI flags (dismissed banners per day, etc.)
    lastBackupAt: null,
  };
}

let state = null;
export let storageOk = true;

export function load() {
  try {
    const raw = localStorage.getItem(KEY);
    state = raw ? migrate(JSON.parse(raw)) : freshState();
  } catch (e) {
    console.warn("localStorage unavailable, using memory only", e);
    storageOk = false;
    state = freshState();
  }
  return state;
}

function migrate(s) {
  // Fill any fields added after this save was written, keep everything else.
  const base = freshState();
  for (const k of Object.keys(base)) if (s[k] === undefined) s[k] = base[k];
  s.profile = { ...base.profile, ...s.profile };
  s.settings = { ...base.settings, ...s.settings };
  s.version = VERSION;
  return s;
}

export const get = () => state;

let saveTimer = null;
export function save(now = false) {
  clearTimeout(saveTimer);
  const write = () => {
    try { localStorage.setItem(KEY, JSON.stringify(state)); storageOk = true; }
    catch (e) { storageOk = false; console.warn("save failed", e); }
  };
  if (now) write(); else saveTimer = setTimeout(write, 250);
}
window.addEventListener?.("pagehide", () => save(true));

// Another tab saved: adopt its state so this tab never writes stale progress back over it.
const externalListeners = new Set();
export const onExternalChange = (fn) => externalListeners.add(fn);
window.addEventListener?.("storage", (e) => {
  if (e.key !== KEY || !e.newValue) return;
  try { adopt(migrate(JSON.parse(e.newValue))); externalListeners.forEach((fn) => fn()); }
  catch { /* ignore a malformed write */ }
});

export function totalXP(s = state) {
  return Math.max(0, Object.values(s.xpLog).reduce((a, b) => a + b, 0));
}

// ---------------------------------------------------------------- export / import
export function exportJSON() {
  state.lastBackupAt = new Date().toISOString();
  save(true);
  return JSON.stringify({ app: "commodity-quant-academy", exportedAt: state.lastBackupAt, state }, null, 1);
}

export function parseImport(text) {
  const obj = JSON.parse(text);
  const s = obj && obj.app === "commodity-quant-academy" ? obj.state : obj;
  if (!s || typeof s !== "object" || !s.xpLog || !s.lessons) throw new Error("This file is not a Commodity Quant Academy progress export.");
  return migrate(s);
}

// Swap in new contents but keep the same object, so views holding a reference stay valid.
function adopt(next) {
  for (const k of Object.keys(state)) delete state[k];
  Object.assign(state, next);
}

export function replaceState(s) {
  try { localStorage.setItem(KEY + "-before-import", JSON.stringify(state)); } catch { /* best effort */ }
  adopt(s);
  save(true);
}

// Merge another device's progress into this one (laptop <-> iPhone).
// Per-day logs take the max for each day, so nothing is double counted; if you studied on
// both devices on the same day the smaller of the two is dropped.
export function mergeStates(a, b) {
  const m = structuredClone(a);
  const maxMerge = (x, y) => { const o = { ...x }; for (const [k, v] of Object.entries(y || {})) o[k] = Math.max(o[k] ?? -Infinity, v); return o; };
  m.xpLog = maxMerge(a.xpLog, b.xpLog);
  m.minutesLog = maxMerge(a.minutesLog, b.minutesLog);
  m.activeDays = { ...b.activeDays, ...a.activeDays };
  m.restDays = { ...b.restDays, ...a.restDays };
  for (const [id, l] of Object.entries(b.lessons || {})) {
    const mine = m.lessons[id];
    if (!mine || (l.status === "done" && mine.status !== "done")) m.lessons[id] = l;
  }
  for (const [id, bo] of Object.entries(b.bosses || {})) {
    const mine = m.bosses[id] || { best: 0, attempts: [] };
    const seen = new Set(mine.attempts.map((x) => x.at));
    m.bosses[id] = { best: Math.max(mine.best, bo.best), attempts: [...mine.attempts, ...bo.attempts.filter((x) => !seen.has(x.at))] };
  }
  m.projects = { ...b.projects, ...a.projects };
  m.levels = { ...b.levels, ...a.levels };
  for (const [id, c] of Object.entries(b.cards || {})) {
    const mine = m.cards[id];
    const last = (x) => (x.history.length ? x.history[x.history.length - 1].d : "");
    if (!mine || last(c) > last(mine)) m.cards[id] = c;
  }
  const calKey = (x) => x.at + x.id;
  const cal = new Set(m.calibration.map(calKey));
  m.calibration.push(...(b.calibration || []).filter((x) => !cal.has(calKey(x))));
  for (const [id, at] of Object.entries(b.achievements || {})) if (!m.achievements[id] || at < m.achievements[id]) m.achievements[id] = at;
  const weeks = new Map(m.weekly.map((w) => [w.weekOf, w]));
  for (const w of b.weekly || []) if (!weeks.has(w.weekOf)) m.weekly.push(w);
  if (b.resume && (!m.resume || b.resume.at > m.resume.at)) m.resume = b.resume;
  m.drafts = { ...b.drafts, ...a.drafts };
  return m;
}

export function download(filename, text, type = "application/json") {
  const blob = new Blob([text], { type });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 1000);
}
