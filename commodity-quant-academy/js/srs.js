// srs.js: SM-2 spaced repetition (Wozniak, 1987) plus interleaving and weak-concept analysis.
//
// Card state: { id, lessonId, level, concept, kind, ef, interval, reps, lapses, due, history: [{d, q}] }
// Quality q is 0-5. q < 3 counts as a lapse: the card restarts at a 1-day interval.

import { get, save, today, addDays } from "./store.js";

export function addCards(lesson, levelId, { firstInterval = 1 } = {}) {
  const s = get();
  for (const c of lesson.cards || []) {
    if (s.cards[c.id]) continue;
    s.cards[c.id] = { id: c.id, lessonId: lesson.id, level: levelId, concept: c.concept, kind: c.kind,
      ef: 2.5, interval: 0, reps: 0, lapses: 0, due: addDays(today(), firstInterval), history: [] };
  }
  save();
}

export function sm2(card, q) {
  const c = { ...card };
  if (q < 3) {
    c.reps = 0;
    c.interval = 1;
    c.lapses += 1;
  } else {
    c.reps += 1;
    c.interval = c.reps === 1 ? 1 : c.reps === 2 ? 6 : Math.round(c.interval * c.ef);
  }
  c.ef = Math.max(1.3, c.ef + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)));
  c.due = addDays(today(), c.interval);
  c.history = [...c.history, { d: today(), q }];
  return c;
}

export function review(cardId, q) {
  const s = get();
  s.cards[cardId] = sm2(s.cards[cardId], q);
  save();
  return s.cards[cardId];
}

export function dueCards(day = today()) {
  return Object.values(get().cards).filter((c) => c.due <= day);
}

// Interleave: round-robin across levels, then concepts, so one session mixes topics
// instead of drilling the latest lesson in a block.
export function interleave(cards) {
  const byLevel = new Map();
  for (const c of [...cards].sort((a, b) => a.due.localeCompare(b.due) || Math.random() - 0.5)) {
    const k = c.level;
    if (!byLevel.has(k)) byLevel.set(k, []);
    byLevel.get(k).push(c);
  }
  // inside each level, alternate concepts
  for (const [k, list] of byLevel) byLevel.set(k, roundRobin(groupBy(list, (c) => c.concept)));
  return roundRobin([...byLevel.values()]);
}
function groupBy(list, f) {
  const m = new Map();
  for (const x of list) { const k = f(x); if (!m.has(k)) m.set(k, []); m.get(k).push(x); }
  return [...m.values()];
}
function roundRobin(groups) {
  const out = [];
  const g = groups.map((x) => [...x]);
  while (g.some((x) => x.length)) for (const x of g) if (x.length) out.push(x.shift());
  return out;
}

export function reviewQueue(limit = 25) {
  return interleave(dueCards()).slice(0, limit);
}

// Concepts ranked from weakest: recent accuracy, lapses and ease factor.
export function conceptStats() {
  const stats = new Map();
  for (const c of Object.values(get().cards)) {
    const st = stats.get(c.concept) || { concept: c.concept, reviews: 0, correct: 0, lapses: 0, ef: 0, n: 0 };
    const recent = c.history.slice(-5);
    st.reviews += recent.length;
    st.correct += recent.filter((h) => h.q >= 3).length;
    st.lapses += c.lapses;
    st.ef += c.ef;
    st.n += 1;
    stats.set(c.concept, st);
  }
  return [...stats.values()].map((st) => {
    const acc = st.reviews ? st.correct / st.reviews : null;
    const ef = st.ef / st.n;
    // weakness: lower accuracy, more lapses per card and lower ease all push a concept up the list
    const weakness = (acc === null ? 0.3 : 1 - acc) * 3 + (st.lapses / st.n) + (2.5 - ef);
    return { ...st, accuracy: acc, ef, weakness };
  }).sort((a, b) => b.weakness - a.weakness);
}

export function weakConcepts(n = 3) {
  return conceptStats().filter((c) => c.reviews > 0 && c.weakness > 0.4).slice(0, n);
}

// Pull every card of the given concepts forward to today.
export function pushConcepts(concepts) {
  const s = get();
  const set = new Set(concepts);
  for (const c of Object.values(s.cards)) if (set.has(c.concept) && c.due > today()) c.due = today();
  save();
}

// A card is "mastered" once its interval reaches 21 days.
export const masteredCount = () => Object.values(get().cards).filter((c) => c.interval >= 21).length;
