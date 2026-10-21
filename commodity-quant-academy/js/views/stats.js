// stats.js: stats page (heatmap, weekly summary, calibration), trophy cabinet, Sunday review.
import { get, save, today } from "../store.js";
import { ACHIEVEMENTS, calibrationSummary, award, XP, streakInfo } from "../gamify.js";
import { conceptStats, weakConcepts, pushConcepts, dueCards } from "../srs.js";
import { esc, toast } from "../ui.js";
import { heatmap, weekStats, rankBar, streakBlock } from "./widgets.js";
import { refreshHeader } from "../main.js";

function calibrationChart() {
  const c = calibrationSummary();
  if (c.n < 3) return `<p class="muted">Rate your confidence before exercises. After a few, this chart shows whether your confidence matches your accuracy.</p>`;
  const W = 300, H = 200, pad = 30;
  const x = (v) => pad + ((v - 0.45) / 0.6) * (W - pad - 10);
  const y = (v) => H - pad - v * (H - pad - 10);
  const pts = c.bins.filter((b) => b.n);
  const dots = pts.map((b) => `<circle cx="${x(b.conf)}" cy="${y(b.acc)}" r="${4 + Math.min(8, b.n)}" class="dot"><title>${Math.round(b.conf * 100)}% confident: ${Math.round(b.acc * 100)}% correct (${b.n})</title></circle>`).join("");
  const verdict = c.gap > 0.1 ? "You tend to be over-confident: slow down and test edge cases before submitting."
    : c.gap < -0.1 ? "You tend to be under-confident: your first instinct is better than you rate it."
    : "Well calibrated: your confidence matches your hit rate.";
  return `<svg viewBox="0 0 ${W} ${H}" class="calib" role="img" aria-label="Calibration chart">
      <line x1="${x(0.5)}" y1="${y(0.5)}" x2="${x(1)}" y2="${y(1)}" class="diag"/>
      <line x1="${pad}" y1="${H - pad}" x2="${W - 10}" y2="${H - pad}" class="axis"/><line x1="${pad}" y1="10" x2="${pad}" y2="${H - pad}" class="axis"/>
      ${[0.5, 0.75, 1].map((v) => `<text x="${x(v)}" y="${H - 12}" class="lbl" text-anchor="middle">${v * 100}%</text><text x="${pad - 4}" y="${y(v) + 4}" class="lbl" text-anchor="end">${v * 100}</text>`).join("")}
      <text x="${W / 2}" y="${H}" class="lbl" text-anchor="middle">confidence</text>
      ${dots}</svg>
    <p class="small">${c.n} calls · mean confidence ${Math.round(c.meanConf * 100)}% · actual first-try pass rate ${Math.round(c.acc * 100)}% · Brier score ${c.brier.toFixed(3)} (lower is better; always saying 50% scores 0.25).</p>
    <p><strong>${verdict}</strong></p>`;
}

export function renderStats(el) {
  const s = get();
  const st = streakInfo();
  const concepts = conceptStats();
  el.innerHTML = `<h1>Stats</h1>
    <section class="status-row"><div class="card">${streakBlock()}</div><div class="card">${rankBar()}</div></section>
    <section class="card"><h3>This week</h3>${weekStats()}</section>
    <section class="card"><h3>Activity (last 52 weeks)</h3>${heatmap(52)}<p class="small muted">${Object.keys(s.activeDays).length} active days · ${Object.keys(s.restDays).length} rest days · ${st.protectedDays.length} day(s) covered by hedge tokens</p></section>
    <section class="card"><h3>Confidence vs accuracy</h3>${calibrationChart()}</section>
    <section class="card"><h3>Concepts</h3>${concepts.length ? `<div class="table-wrap"><table><thead><tr><th>Concept</th><th>Cards</th><th>Recent accuracy</th><th>Lapses</th><th>Ease</th></tr></thead><tbody>
      ${concepts.map((c) => `<tr><td>${esc(c.concept)}</td><td>${c.n}</td><td>${c.accuracy === null ? "–" : Math.round(c.accuracy * 100) + "%"}</td><td>${c.lapses}</td><td>${c.ef.toFixed(2)}</td></tr>`).join("")}</tbody></table></div>` : `<p class="muted">No concepts yet.</p>`}</section>`;
}

export function renderTrophies(el) {
  const s = get();
  const got = ACHIEVEMENTS.filter((a) => s.achievements[a.id]).length;
  el.innerHTML = `<h1>Trophy cabinet</h1><p class="muted">${got}/${ACHIEVEMENTS.length} earned. Badges describe who you're becoming, not how much you clicked.</p>
    <div class="trophies">${ACHIEVEMENTS.map((a) => {
      const at = s.achievements[a.id];
      return `<div class="trophy ${at ? "on" : ""}"><div class="medal">${at ? "★" : "☆"}</div><div><strong>${esc(a.name)}</strong><div class="small">${esc(a.desc)}</div>
        ${at ? `<div class="small muted">Earned ${at.slice(0, 10)}</div>` : ""}</div></div>`;
    }).join("")}</div>`;
}

export function renderWeekly(el) {
  const s = get();
  const weak = weakConcepts(3);
  const thisWeek = s.weekly.find((w) => w.weekOf === today());
  el.innerHTML = `<h1>Weekly review</h1><p class="muted">Ten minutes. Honest answers beat tidy ones.</p>
    <section class="card"><h3>Your week</h3>${weekStats()}</section>
    <section class="card"><h3>Weakest concepts (from your review results)</h3>
      ${weak.length ? `<ul>${weak.map((c) => `<li><strong>${esc(c.concept)}</strong>: ${c.accuracy === null ? "not reviewed yet" : `${Math.round(c.accuracy * 100)}% recent accuracy`}, ${c.lapses} lapse(s)</li>`).join("")}</ul>
      <p class="small muted">Saving this review moves these concepts' cards into today's queue.</p>` : `<p class="muted">Not enough review data yet. Keep reviewing.</p>`}</section>
    <form class="card weekly-form">
      <label>What stuck this week?<textarea name="stuck" rows="2" required>${esc(thisWeek?.stuck || "")}</textarea></label>
      <label>What didn't? Where did you hesitate?<textarea name="didnt" rows="2">${esc(thisWeek?.didnt || "")}</textarea></label>
      <label>Plan for next week (sessions, which lessons, which project step)<textarea name="plan" rows="2">${esc(thisWeek?.plan || "")}</textarea></label>
      <button class="btn primary">Save weekly review</button>
    </form>
    ${s.weekly.length ? `<section class="card"><h3>Past reviews</h3>${s.weekly.slice().reverse().map((w) => `<details><summary>${esc(w.weekOf)}</summary><p><strong>Stuck:</strong> ${esc(w.stuck)}</p><p><strong>Didn't:</strong> ${esc(w.didnt)}</p><p><strong>Plan:</strong> ${esc(w.plan)}</p>${w.weak?.length ? `<p class="small muted">Weak: ${w.weak.map(esc).join(", ")}</p>` : ""}</details>`).join("")}</section>` : ""}`;
  el.querySelector("form").addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(e.target);
    const entry = { weekOf: today(), stuck: f.get("stuck"), didnt: f.get("didnt"), plan: f.get("plan"), weak: weak.map((c) => c.concept) };
    const first = !thisWeek;
    s.weekly = s.weekly.filter((w) => w.weekOf !== entry.weekOf).concat(entry);
    save();
    if (weak.length) pushConcepts(entry.weak);
    if (first) award(XP.weekly, "weekly review");
    refreshHeader();
    toast(`Saved. ${dueCards().length} cards in today's queue.`, "info");
    location.hash = "#/home";
  });
}
