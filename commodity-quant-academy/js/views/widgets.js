// widgets.js: pieces shared by several views (rank bar, heatmap, mini skill map, week stats).
import { get, today, addDays, totalXP } from "../store.js";
import { rankInfo, streakInfo, weekSummary, RANKS } from "../gamify.js";
import { getLevels, levelState, levelProgress } from "../content.js";
import { dueCards, masteredCount } from "../srs.js";
import { esc, fmtMinutes } from "../ui.js";

export function rankBar() {
  const r = rankInfo();
  const label = r.next ? `${r.toNext.toLocaleString()} XP to ${r.next.name}` : "Top rank reached";
  return `<div class="rank">
    <div class="rank-badge" title="Rank ${r.index + 1} of ${RANKS.length}"><span>${r.index + 1}</span></div>
    <div class="rank-body">
      <div class="rank-name">${esc(r.rank.name)} <span class="muted small">${r.xp.toLocaleString()} XP</span></div>
      <div class="bar" role="progressbar" aria-valuemin="0" aria-valuemax="100" aria-valuenow="${Math.round(r.p * 100)}"><div style="width:${(r.display * 100).toFixed(1)}%"></div></div>
      <div class="muted small">${esc(label)}</div>
    </div></div>`;
}

export function streakBlock() {
  const st = streakInfo();
  const tokens = [0, 1].map((i) => `<span class="token ${i < st.hedges ? "on" : ""}" title="Hedge token">◆</span>`).join("");
  return `<div class="streak">
    <div class="streak-num">${st.current}<span>day${st.current === 1 ? "" : "s"}</span></div>
    <div class="small"><div>${st.todayDone ? "Today counted ✓" : "Not yet today"}</div>
    <div title="One hedge token per 7-day run, max 2. A token covers a missed day automatically.">Hedges ${tokens}</div>
    <div class="muted">Best ${st.best}</div></div></div>`;
}

export function heatmap(weeks = 26) {
  const s = get();
  const end = today();
  const [y, m, d] = end.split("-").map(Number);
  const dow = (new Date(y, m - 1, d).getDay() + 6) % 7; // Monday = 0
  const start = addDays(end, -(weeks - 1) * 7 - dow);
  const cells = [];
  for (let day = start; day <= end; day = addDays(day, 1)) {
    const xp = s.xpLog[day] || 0;
    const lvl = s.restDays[day] ? "rest" : xp <= 0 ? (s.activeDays[day] ? 1 : 0) : xp < 40 ? 1 : xp < 100 ? 2 : xp < 200 ? 3 : 4;
    cells.push(`<i class="hm l${lvl}" title="${day}: ${xp} XP${s.restDays[day] ? " (rest day)" : ""}"></i>`);
  }
  return `<div class="heatmap" style="--weeks:${weeks}">${cells.join("")}</div>
    <div class="heat-legend muted small">Less <i class="hm l0"></i><i class="hm l1"></i><i class="hm l2"></i><i class="hm l3"></i><i class="hm l4"></i> More · <i class="hm rest"></i> rest</div>`;
}

export function weekStats() {
  const w = weekSummary(0), prev = weekSummary(1);
  const delta = (a, b) => (b ? `<span class="muted small">${a >= b ? "▲" : "▼"} vs ${b} last wk</span>` : "");
  const shipped = Object.keys(get().projects).length;
  return `<div class="stat-grid">
    <div class="stat big"><div class="stat-v">${shipped}</div><div class="stat-k">Projects shipped</div></div>
    <div class="stat"><div class="stat-v">${fmtMinutes(w.minutes)}</div><div class="stat-k">This week ${delta(w.minutes, prev.minutes)}</div></div>
    <div class="stat"><div class="stat-v">${w.xp}</div><div class="stat-k">XP this week ${delta(w.xp, prev.xp)}</div></div>
    <div class="stat"><div class="stat-v">${masteredCount()}</div><div class="stat-k">Concepts mastered</div></div>
    <div class="stat"><div class="stat-v">${dueCards().length}</div><div class="stat-k">Reviews due</div></div>
    <div class="stat"><div class="stat-v">${w.days}/7</div><div class="stat-k">Active days</div></div>
  </div>`;
}

export function skillMap({ compact = false } = {}) {
  const nodes = getLevels().map((lv) => {
    const st = levelState(lv);
    const p = levelProgress(lv);
    const icon = { mastered: "★", unlocked: "▶", planned: "…", locked: "🔒" }[st];
    return `<a class="node ${st}" href="#/level/${lv.id}" title="${esc(lv.title)}: ${st}">
      <span class="node-n">${lv.n}</span>
      <span class="node-t">${esc(compact ? lv.short || lv.title : lv.title)}</span>
      <span class="node-s">${icon} ${st === "unlocked" && p.total ? `${p.done}/${p.total}` : st === "planned" ? `Phase ${lv.phase}` : ""}</span>
    </a>`;
  });
  return `<div class="skill-map ${compact ? "compact" : ""}">${nodes.join('<span class="edge"></span>')}</div>`;
}

export { totalXP };
