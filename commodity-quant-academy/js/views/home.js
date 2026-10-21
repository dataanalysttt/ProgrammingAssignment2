// home.js: the home screen, in the priority order from the brief:
// review queue, continue, streak/rank, 5-minute mode, skill map, heatmap + weekly stats.
import { get, save, today } from "../store.js";
import { streakInfo, intentionStatus, daysSinceBackup, canRestToday, takeRestDay, maybeMarketEvent, award, XP } from "../gamify.js";
import { dueCards } from "../srs.js";
import { nextStep, lookup, isDone } from "../content.js";
import { esc, toast } from "../ui.js";
import { rankBar, streakBlock, skillMap, heatmap, weekStats } from "./widgets.js";
import { openEvent } from "./review.js";
import { refreshHeader } from "../main.js";

function banners() {
  const s = get();
  const out = [];
  const st = streakInfo();
  const d = today();
  const dismissed = (k) => s.flags[`dismiss-${k}`] === d;
  const banner = (k, cls, body) => !dismissed(k) && out.push(`<div class="banner ${cls}" data-banner="${k}">${body}<button class="icon-btn" data-dismiss="${k}" aria-label="Dismiss">✕</button></div>`);

  if (st.yesterdayHedged) banner("hedge", "info", `<div><strong>A hedge token covered yesterday.</strong> Your ${st.current}-day streak is intact.</div>`);
  else if (st.missedYesterday && !st.todayDone) banner("recover", "warm", `<div><strong>Yesterday was off. Today is the one that counts.</strong> The rule is never miss twice. One 5-minute session keeps the pattern going.
    <div class="row"><a class="btn primary small" href="#/quick">Start 5-minute session</a></div></div>`);
  const intent = intentionStatus();
  if (intent?.overdue && !st.todayDone && !(st.missedYesterday && !st.yesterdayHedged)) banner("intent", "warm", `<div><strong>Your planned ${esc(s.profile.studyTime)} session hasn't happened yet.</strong> A 5-minute session counts.
    <div class="row"><a class="btn primary small" href="#/quick">5-minute mode</a></div></div>`);
  if (new Date().getDay() === 0 && !s.weekly.some((w) => w.weekOf === d)) banner("weekly", "info", `<div><strong>Sunday review.</strong> 10 minutes: what stuck, what didn't, and your weakest concepts.
    <div class="row"><a class="btn small" href="#/weekly">Start weekly review</a></div></div>`);
  if (daysSinceBackup() >= 7) banner("backup", "info", `<div><strong>Back up your progress.</strong> ${s.lastBackupAt ? `Last backup ${daysSinceBackup()} days ago.` : "No backup yet."} Browser storage can be wiped.
    <div class="row"><a class="btn small" href="#/settings/backup">Export progress</a></div></div>`);
  if ((s.minutesLog[d] || 0) >= 90) banner("cap", "info", `<div><strong>90+ minutes today.</strong> Leave something for tomorrow. Stopping while it's fresh helps it stick.</div>`);
  return out.join("");
}

export async function renderHome(el) {
  const s = get();
  const due = dueCards().length;
  const st = streakInfo();
  const step = nextStep();
  const resume = s.resume && lookup(s.resume.lessonId) && !isDone(s.resume.lessonId) ? lookup(s.resume.lessonId) : null;
  const target = resume ? { ...resume, entry: resume.entry } : step;
  const teaser = s.lastTeaser?.text;

  el.innerHTML = `
  ${banners()}
  <section class="card hero review-card">
    <div><div class="eyebrow">Today's review queue</div>
      <div class="big-num">${due}<span> card${due === 1 ? "" : "s"} due</span></div>
      <div class="muted small">${due ? "Mixed topics. You write the answer, then check." : Object.keys(s.cards).length ? "Nothing due. New cards appear as you finish lessons." : "Finish your first lesson to start your review deck."}</div></div>
    <a class="btn primary lg ${due ? "" : "disabled"}" href="${due ? "#/review" : "#/home"}" ${due ? "" : 'aria-disabled="true"'}>Start review</a>
  </section>

  <section class="card continue-card">
    <div class="eyebrow">${resume ? "Resume where you left off" : "Up next"}</div>
    ${target ? `<h2>${esc(target.entry.title)}</h2>
      <div class="muted small">Level ${target.level.n} · ${esc(target.level.title)}${target.module ? ` · ${esc(target.module.title)}` : ""}</div>
      ${teaser ? `<p class="teaser">“${esc(teaser)}”</p>` : ""}
      <a class="btn primary" href="#/lesson/${target.entry.id}">${resume ? "Resume" : "Continue"}</a>`
      : `<p>Everything currently written is complete. New levels arrive with the next content phase.</p>`}
  </section>

  <section class="status-row">
    <div class="card">${streakBlock()}
      ${canRestToday() && !st.todayDone ? `<button class="btn ghost small" data-act="rest">Take today as a rest day</button>` : ""}</div>
    <div class="card">${rankBar()}</div>
  </section>

  <section class="card quick-card">
    <div><strong>Bad day? 5-minute mode.</strong><div class="muted small">One spaced review + one micro-exercise. It counts for your streak.</div></div>
    <a class="btn lg" href="#/quick">5-minute mode</a>
  </section>

  ${s.profile.studyTime ? `<p class="intention">Plan: <strong>${esc(s.profile.studyTime)}</strong>, after <strong>${esc(s.profile.habit || "…")}</strong>. ${s.profile.why ? `Why: ${esc(s.profile.why)}` : ""} <a href="#/settings/plan" class="small">edit</a></p>` : ""}

  <section class="card"><div class="row between"><h3>Skill map</h3><a class="small" href="#/map">Full map →</a></div>${skillMap({ compact: true })}</section>

  <section class="card"><div class="row between"><h3>Activity</h3><a class="small" href="#/stats">Stats →</a></div>${heatmap(26)}${weekStats()}</section>
  `;

  el.addEventListener("click", (e) => {
    const dis = e.target.closest("[data-dismiss]");
    if (dis) { s.flags[`dismiss-${dis.dataset.dismiss}`] = today(); save(); dis.parentElement.remove(); }
    if (e.target.closest('[data-act="rest"]')) {
      if (takeRestDay()) { toast("Rest day logged. Your streak is safe.", "info"); refreshHeader(); window.dispatchEvent(new HashChangeEvent("hashchange")); }
    }
  });

  const ev = await maybeMarketEvent("open");
  if (ev) openEvent(ev, award, XP);
}
