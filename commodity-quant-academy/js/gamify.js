// gamify.js: XP, ranks, streaks with hedge tokens, achievements, market events and the
// activity timer. Rationale for each mechanic: DESIGN_NOTES.md.

import { get, save, today, addDays, daysBetween, totalXP } from "./store.js";
import { masteredCount } from "./srs.js";

// ---------------------------------------------------------------- XP and ranks
export const RANKS = [
  { name: "Ops Analyst", xp: 0 },
  { name: "Junior Trader", xp: 600 },
  { name: "Trader", xp: 2000 },
  { name: "Senior Trader", xp: 4500 },
  { name: "Head of Desk", xp: 8500 },
  { name: "CRO", xp: 14000 },
];

export const XP = { lesson: 50, hint: [5, 10, 15], review: 5, quick: 20, boss: 150, levelBoss: 300, project: 500, event: 30, weekly: 40, placementItem: 15 };

// Goal-gradient display: a 10% head start, then the bar accelerates toward the next rank.
// The true numbers are always shown next to the bar.
export const gradient = (p) => (p >= 1 ? 1 : 0.1 + 0.9 * Math.pow(Math.max(0, p), 1.6));

export function rankInfo(xp = totalXP()) {
  let i = RANKS.findLastIndex((r) => xp >= r.xp);
  const rank = RANKS[i], next = RANKS[i + 1] || null;
  const p = next ? (xp - rank.xp) / (next.xp - rank.xp) : 1;
  return { rank, next, xp, p, display: gradient(p), toNext: next ? next.xp - xp : 0, index: i };
}

const hooks = { toast: () => {}, celebrate: () => {} };
export function setHooks(h) { Object.assign(hooks, h); }

export function award(amount, reason, { countsAsActive = true } = {}) {
  const s = get();
  const before = rankInfo();
  const d = today();
  if (amount < 0) amount = -Math.min(-amount, totalXP()); // never below zero overall
  s.xpLog[d] = (s.xpLog[d] || 0) + amount;
  if (countsAsActive && amount > 0) markActive();
  save();
  if (amount) hooks.toast(`${amount > 0 ? "+" : ""}${amount} XP · ${reason}`, amount > 0 ? "xp" : "cost");
  const after = rankInfo();
  if (after.index > before.index) hooks.celebrate(`Promoted to ${after.rank.name}`, `You now have ${after.xp.toLocaleString()} XP.`);
  checkAchievements();
}

export function markActive() {
  const s = get();
  if (!s.activeDays[today()]) {
    s.activeDays[today()] = true;
    save();
    checkAchievements();
  }
}

// ---------------------------------------------------------------- streaks
// Recomputed from history every time (pure function), so merging devices or importing a
// backup can never leave the streak in a broken state.
export function streakInfo(s = get(), now = today()) {
  const days = Object.keys(s.activeDays).concat(Object.keys(s.restDays)).sort();
  const res = { current: 0, best: 0, hedges: 0, protectedDays: [], missedYesterday: false, recovered: 0, todayDone: !!s.activeDays[now] || !!s.restDays[now] };
  if (!days.length) return res;
  let streak = 0, hedges = 0, prevMiss = false;
  for (let d = days[0]; d <= now; d = addDays(d, 1)) {
    if (s.activeDays[d] || s.restDays[d]) {
      if (prevMiss && s.activeDays[d]) res.recovered++;
      prevMiss = false;
      if (s.activeDays[d]) {
        streak++;
        if (streak % 7 === 0) hedges = Math.min(2, hedges + 1);
      }
    } else if (d === now) {
      // today is not over yet: nothing lost
    } else if (hedges > 0) {
      hedges--;
      res.protectedDays.push(d);
    } else {
      streak = 0;
      prevMiss = true;
    }
    res.best = Math.max(res.best, streak);
  }
  const y = addDays(now, -1);
  res.current = streak;
  res.hedges = hedges;
  res.missedYesterday = !s.activeDays[y] && !s.restDays[y] && days[0] <= y;
  res.yesterdayHedged = res.protectedDays.includes(y);
  return res;
}

const isoWeek = (day) => { // Monday of the week containing day
  const [y, m, d] = day.split("-").map(Number);
  const dow = (new Date(y, m - 1, d).getDay() + 6) % 7;
  return addDays(day, -dow);
};

export function canRestToday() {
  const s = get();
  const monday = isoWeek(today());
  const usedThisWeek = Object.keys(s.restDays).some((d) => d >= monday && d <= addDays(monday, 6));
  return !usedThisWeek && !s.activeDays[today()];
}
export function takeRestDay() {
  if (!canRestToday()) return false;
  get().restDays[today()] = true;
  save();
  return true;
}

// ---------------------------------------------------------------- activity timer + daily cap
let lastInput = Date.now();
export function startActivityTimer(onCap) {
  const bump = () => (lastInput = Date.now());
  ["keydown", "pointerdown", "scroll", "touchstart"].forEach((ev) => window.addEventListener(ev, bump, { passive: true }));
  setInterval(() => {
    if (document.visibilityState !== "visible" || Date.now() - lastInput > 120000) return;
    const s = get();
    const d = today();
    s.minutesLog[d] = Math.round(((s.minutesLog[d] || 0) + 0.5) * 10) / 10;
    save();
    if (s.minutesLog[d] >= 90 && s.flags.capShown !== d) { s.flags.capShown = d; onCap?.(); }
  }, 30000);
}

// ---------------------------------------------------------------- market events
let eventsCache = null;
export async function loadEvents() {
  if (!eventsCache) {
    try { eventsCache = await (await fetch(new URL("../content/events.json", import.meta.url))).json(); }
    catch { eventsCache = { events: [], micro: [] }; }
  }
  return eventsCache;
}

// Called after milestones. Rare and unpredictable (variable ratio), max one per day,
// never inside a boss battle, always dismissible.
export async function maybeMarketEvent(trigger) {
  const s = get();
  if (s.events.lastDay === today()) return null;
  const p = trigger === "lesson" ? 0.18 : trigger === "review" ? 0.1 : 0.05;
  if (Math.random() > p) return null;
  const { events } = await loadEvents();
  const level = maxUnlockedLevel();
  const pool = events.filter((e) => (e.minLevel ?? 0) <= level);
  if (!pool.length) return null;
  const ev = pool[Math.floor(Math.random() * pool.length)];
  s.events.lastDay = today();
  s.events.history.push({ id: ev.id, at: new Date().toISOString() });
  save();
  return ev;
}

function maxUnlockedLevel() {
  const s = get();
  const mastered = Object.keys(s.levels).map((k) => Number(k.split("-")[1]));
  return mastered.length ? Math.max(...mastered) + 1 : 1;
}

// ---------------------------------------------------------------- achievements
const doneCount = (s, pred = () => true) => Object.entries(s.lessons).filter(([id, l]) => l.status === "done" && pred(id)).length;
const shipped = (s) => Object.keys(s.projects).length;
const reviews = (s) => Object.values(s.cards).reduce((a, c) => a + c.history.length, 0);
const levelMastered = (s, n) => !!s.levels[`level-${n}`]?.masteredAt;

export function calibrationSummary(s = get()) {
  const pts = s.calibration;
  if (!pts.length) return { n: 0, brier: null, bins: [] };
  const brier = pts.reduce((a, p) => a + (p.conf - (p.correct ? 1 : 0)) ** 2, 0) / pts.length;
  const bins = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0].map((c) => {
    const inBin = pts.filter((p) => Math.abs(p.conf - c) < 0.05);
    return { conf: c, n: inBin.length, acc: inBin.length ? inBin.filter((p) => p.correct).length / inBin.length : null };
  });
  const meanConf = pts.reduce((a, p) => a + p.conf, 0) / pts.length;
  const acc = pts.filter((p) => p.correct).length / pts.length;
  return { n: pts.length, brier, bins, meanConf, acc, gap: meanConf - acc };
}

export const ACHIEVEMENTS = [
  { id: "first-run", name: "Hello, Desk", desc: "Ran your first line of Python.", test: (s) => doneCount(s) >= 1 },
  { id: "shows-up-7", name: "Shows Up", desc: "Kept a 7-day streak.", test: () => streakInfo().best >= 7 },
  { id: "shows-up-30", name: "Part of the Furniture", desc: "Kept a 30-day streak.", test: () => streakInfo().best >= 30 },
  { id: "never-twice", name: "Never Misses Twice", desc: "Came back the day after a miss.", test: () => streakInfo().recovered >= 1 },
  { id: "retrieval-100", name: "Retrieval Habit", desc: "Completed 100 spaced reviews.", test: (s) => reviews(s) >= 100 },
  { id: "mastered-25", name: "Long-Term Memory", desc: "25 cards at a 21-day+ interval.", test: () => masteredCount() >= 25 },
  { id: "boss-clean", name: "Cool Under Pressure", desc: "Scored 100% on a timed boss battle.", test: (s) => Object.values(s.bosses).some((b) => b.best >= 1) },
  { id: "no-hints-10", name: "Works It Out", desc: "Passed 10 lessons without a hint.", test: (s) => Object.values(s.lessons).filter((l) => l.status === "done" && !l.hintsUsed).length >= 10 },
  { id: "calibrated", name: "Knows What It Knows", desc: "30+ confidence calls with a calibration gap under 10 points.", test: (s) => { const c = calibrationSummary(s); return c.n >= 30 && Math.abs(c.gap) < 0.1; } },
  { id: "reflects", name: "Runs a Post-Mortem", desc: "Completed 4 weekly reviews.", test: (s) => s.weekly.length >= 4 },
  { id: "invoice-clerk", name: "Invoice Engineer", desc: "Mastered Level 1: Python Foundations.", test: (s) => levelMastered(s, 1) },
  { id: "data-wrangler", name: "Owns the Trade Book", desc: "Mastered Level 2: Data Handling.", test: (s) => levelMastered(s, 2) },
  { id: "curve-reader", name: "Curve Reader", desc: "Mastered Level 3: Market Data.", test: (s) => levelMastered(s, 3) },
  { id: "netback", name: "Thinks in Netbacks", desc: "Mastered Level 4: Physical Economics.", test: (s) => levelMastered(s, 4) },
  { id: "greeks", name: "Thinks in Greeks", desc: "Mastered Level 5: Derivatives.", test: (s) => levelMastered(s, 5) },
  { id: "risk-owner", name: "Risk Owner", desc: "Mastered Level 6: Risk Management.", test: (s) => levelMastered(s, 6) },
  { id: "systematic", name: "Systematic, Not Lucky", desc: "Mastered Level 7: Systematic Trading.", test: (s) => levelMastered(s, 7) },
  { id: "ship-1", name: "Shipped It", desc: "Shipped your first CV project.", test: (s) => shipped(s) >= 1 },
  { id: "ship-5", name: "Shipped 5 Projects", desc: "Five CV projects shipped.", test: (s) => shipped(s) >= 5 },
  { id: "capstone", name: "Built the Platform", desc: "Shipped the Level 8 capstone.", test: (s) => !!s.projects["l8-project"] },
];

export function checkAchievements() {
  const s = get();
  for (const a of ACHIEVEMENTS) {
    if (s.achievements[a.id]) continue;
    let ok = false;
    try { ok = a.test(s); } catch { ok = false; }
    if (ok) {
      s.achievements[a.id] = new Date().toISOString();
      save();
      hooks.celebrate(`Badge: ${a.name}`, a.desc);
    }
  }
}

// ---------------------------------------------------------------- implementation intention
export function intentionStatus(now = new Date()) {
  const { studyTime } = get().profile;
  if (!studyTime) return null;
  const [h, m] = studyTime.split(":").map(Number);
  const due = new Date(now); due.setHours(h, m, 0, 0);
  const overdue = now - due > 2 * 3600 * 1000 && !get().activeDays[today(now)];
  return { due, overdue };
}

export function weekSummary(offsetWeeks = 0) {
  const s = get();
  const end = addDays(today(), -7 * offsetWeeks);
  const start = addDays(end, -6);
  let minutes = 0, xp = 0, days = 0;
  for (let d = start; d <= end; d = addDays(d, 1)) {
    minutes += s.minutesLog[d] || 0;
    xp += s.xpLog[d] || 0;
    if (s.activeDays[d]) days++;
  }
  const reviewsDone = Object.values(s.cards).reduce((a, c) => a + c.history.filter((h) => h.d >= start && h.d <= end).length, 0);
  return { start, end, minutes: Math.round(minutes), xp, days, reviewsDone };
}

export const daysSinceBackup = () => {
  const s = get();
  const from = s.lastBackupAt ? s.lastBackupAt.slice(0, 10) : s.createdAt.slice(0, 10);
  return daysBetween(from, today());
};
