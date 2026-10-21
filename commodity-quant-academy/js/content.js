// content.js: loads content/manifest.json, each level.json and lesson files on demand,
// and answers curriculum questions (what is unlocked, what comes next).

import { parseLesson } from "./mdparse.js";
import { get } from "./store.js";

const ROOT = new URL("../content/", import.meta.url).href;
let levels = [];
const lessonCache = new Map();
const index = new Map(); // lessonId -> { level, module, entry, kind }

export async function loadCurriculum() {
  const manifest = await (await fetch(ROOT + "manifest.json", { cache: "no-cache" })).json();
  levels = await Promise.all(manifest.levels.map(async (l) => {
    const lv = await (await fetch(ROOT + l.file, { cache: "no-cache" })).json();
    lv.dir = l.file.replace(/[^/]+$/, "");
    return lv;
  }));
  levels.sort((a, b) => a.n - b.n);
  index.clear();
  for (const lv of levels) {
    const reg = (entry, kind, module = null) => entry && index.set(entry.id, { level: lv, module, entry, kind });
    reg(lv.placement, "placement");
    for (const m of lv.modules || []) {
      for (const l of m.lessons) reg(l, "lesson", m);
      reg(m.boss, "boss", m);
    }
    reg(lv.levelBoss, "levelBoss");
    reg(lv.project, "project");
  }
  return levels;
}

export const getLevels = () => levels;
export const getLevel = (id) => levels.find((l) => l.id === id);
export const lookup = (lessonId) => index.get(lessonId);

export async function loadLesson(lessonId) {
  if (lessonCache.has(lessonId)) return lessonCache.get(lessonId);
  const info = index.get(lessonId);
  if (!info) throw new Error(`Unknown lesson ${lessonId}`);
  if (!info.entry.file) return null; // planned, not written yet
  const res = await fetch(ROOT + info.level.dir + info.entry.file, { cache: "no-cache" });
  if (!res.ok) throw new Error(`Could not load ${info.entry.file} (${res.status})`);
  const lesson = parseLesson(await res.text(), info.entry.file);
  lesson.id = lesson.id || lessonId;
  lessonCache.set(lessonId, lesson);
  return lesson;
}

// ---------------------------------------------------------------- progress queries
export const isDone = (id) => ["done", "tested-out"].includes(get().lessons[id]?.status);
export const bossBest = (id) => get().bosses[id]?.best ?? null;
export const isMastered = (lv) => !!get().levels[lv.id]?.masteredAt;

export function isUnlocked(lv) {
  if (lv.n === 0) return true;
  const prev = levels.find((l) => l.n === lv.n - 1);
  return !!prev && isMastered(prev);
}

export function levelState(lv) {
  if (isMastered(lv)) return "mastered";
  if (!isUnlocked(lv)) return "locked";
  return lv.status === "planned" ? "planned" : "unlocked";
}

export function levelProgress(lv) {
  const ids = (lv.modules || []).flatMap((m) => m.lessons.map((l) => l.id));
  const done = ids.filter(isDone).length;
  return { done, total: ids.length, pct: ids.length ? done / ids.length : 0 };
}

// The single next thing to do, in curriculum order.
export function nextStep() {
  for (const lv of levels) {
    if (!isUnlocked(lv) || lv.status === "planned") continue;
    if (isMastered(lv)) continue;
    for (const m of lv.modules || []) {
      const l = m.lessons.find((x) => x.file && !isDone(x.id));
      if (l) return { level: lv, module: m, entry: l, kind: "lesson" };
      if (m.boss?.file && bossBest(m.boss.id) === null) return { level: lv, module: m, entry: m.boss, kind: "boss" };
    }
    if (lv.levelBoss?.file) return { level: lv, entry: lv.levelBoss, kind: "levelBoss" };
  }
  for (const lv of levels) if (isMastered(lv) && lv.project?.file && !get().projects[lv.project.id]) return { level: lv, entry: lv.project, kind: "project" };
  return null;
}

// The lesson that follows lessonId in curriculum order (for "Next lesson" buttons).
export function following(lessonId) {
  const order = [];
  for (const lv of levels) {
    if (lv.placement) order.push(lv.placement);
    for (const m of lv.modules || []) { order.push(...m.lessons); if (m.boss) order.push(m.boss); }
    if (lv.levelBoss) order.push(lv.levelBoss);
    if (lv.project) order.push(lv.project);
  }
  const i = order.findIndex((e) => e.id === lessonId);
  return order.slice(i + 1).find((e) => e.file && e.id !== lessonId) || null;
}

export function allEntries() {
  return [...index.values()];
}
