// lesson.js: renders every content type: lesson, boss / level boss (timed), placement, project.
import { get, save, download } from "../store.js";
import { award, markActive, XP, maybeMarketEvent, checkAchievements } from "../gamify.js";
import { addCards } from "../srs.js";
import { lookup, loadLesson, isUnlocked, isDone, following, getLevels } from "../content.js";
import { renderMarkdown, exampleCode } from "../mdparse.js";
import { run } from "../pyrunner.js";
import { esc, renderOutput, toast, celebrate, copyText } from "../ui.js";
import { mountExercise } from "./exercise.js";
import { openEvent } from "./review.js";
import { refreshHeader, setCleanup } from "../main.js";

export async function renderLesson(el, id) {
  const info = lookup(id);
  if (!info) { el.innerHTML = `<div class="card"><h2>Lesson not found</h2><p class="muted">${esc(id)}</p><a class="btn" href="#/map">Skill map</a></div>`; return; }
  const lesson = await loadLesson(id);
  const lv = info.level;
  const crumbs = `<nav class="crumbs small"><a href="#/map">Map</a> › <a href="#/level/${lv.id}">L${lv.n} ${esc(lv.title)}</a>${info.module ? ` › ${esc(info.module.title)}` : ""}</nav>`;

  if (!lesson || lesson.status === "planned") {
    const objectives = lesson?.objectives?.length ? lesson.objectives : info.entry.objectives || [];
    el.innerHTML = `${crumbs}<div class="card"><div class="eyebrow">Planned · Phase ${lv.phase}</div><h1>${esc(info.entry.title)}</h1>
      ${objectives.length ? `<h3>Learning objectives</h3><ul>${objectives.map((o) => `<li>${esc(o)}</li>`).join("")}</ul>` : ""}
      <p class="muted">This lesson is outlined but not written yet. It arrives in content phase ${lv.phase}.</p></div>`;
    return;
  }
  // placement tests stay open so you can test out before unlocking the level
  if (!isUnlocked(lv) && lesson.type !== "placement") {
    const prev = getLevels().find((l) => l.n === lv.n - 1);
    el.innerHTML = `${crumbs}<div class="card locked-card"><div class="eyebrow">Locked</div><h1>${esc(lesson.title)}</h1>
      <p>Level ${lv.n} unlocks when you score 80%+ on the Level ${prev?.n} boss battle${prev?.levelBoss ? `: <a href="#/lesson/${prev.levelBoss.id}">${esc(prev.levelBoss.title)}</a>` : ""}.</p>
      ${lesson.objectives.length ? `<h3>You'll learn to</h3><ul>${lesson.objectives.map((o) => `<li>${esc(o)}</li>`).join("")}</ul>` : ""}</div>`;
    return;
  }

  const s = get();
  if (["lesson", "project"].includes(lesson.type)) { s.resume = { lessonId: id, at: new Date().toISOString() }; save(); }

  const header = `${crumbs}<header class="lesson-head">
      <div class="eyebrow">${{ lesson: "Lesson", boss: "Boss battle", levelBoss: "Level boss battle", placement: "Placement test", project: "CV project" }[info.kind] || "Lesson"} · ${lesson.minutes} min${lesson.timeLimit ? ` · ${Math.round(lesson.timeLimit / 60)} min clock` : ""}</div>
      <h1>${esc(lesson.title)}</h1>
      ${lesson.objectives.length ? `<ul class="objectives">${lesson.objectives.map((o) => `<li>${esc(o)}</li>`).join("")}</ul>` : ""}
    </header>`;

  if (lesson.type === "boss" || info.kind === "boss" || info.kind === "levelBoss") return renderBoss(el, header, lesson, info);
  if (lesson.type === "placement") return renderPlacement(el, header, lesson, info);
  if (lesson.type === "project") return renderProject(el, header, lesson, info);
  return renderStandard(el, header, lesson, info);
}

// ---------------------------------------------------------------- shared bits
function learnHTML(lesson) {
  return `${lesson.learn ? `<section class="card learn">${renderMarkdown(lesson.learn)}</section>` : ""}
    ${lesson.desk ? `<aside class="card desk"><div class="eyebrow">Why this matters on a desk</div>${renderMarkdown(lesson.desk)}</aside>` : ""}`;
}

function wireExamples(el, lesson, getEditor) {
  el.addEventListener("click", async (e) => {
    const b = e.target.closest("[data-act='run-example'],[data-act='copy-example']");
    if (!b) return;
    const box = b.closest(".example");
    const code = exampleCode(lesson.learn, Number(box.dataset.example));
    if (b.dataset.act === "copy-example") {
      const ed = getEditor();
      if (ed) { ed.setValue(code); ed.focus(); toast("Example copied into the exercise editor.", "info"); }
      return;
    }
    b.disabled = true; b.textContent = "Running…";
    const res = await run(code, { datasets: lesson.datasets });
    b.disabled = false; b.textContent = "Run example";
    renderOutput(box.querySelector(".example-out"), res, { showTests: false });
  });
}

function nextButton(id) {
  const nx = following(id);
  return nx ? `<a class="btn primary" href="#/lesson/${nx.id}">Next: ${esc(nx.title)}</a>` : `<a class="btn primary" href="#/home">Home</a>`;
}

// ---------------------------------------------------------------- standard lesson
async function renderStandard(el, header, lesson, info) {
  const s = get();
  const already = isDone(lesson.id);
  el.innerHTML = `${header}${learnHTML(lesson)}<section class="exercises"></section><section class="complete" hidden></section>`;
  const host = el.querySelector(".exercises");
  const mounted = [];
  let revealedAny = false;

  const finish = async () => {
    const box = el.querySelector(".complete");
    box.hidden = false;
    if (!isDone(lesson.id)) {
      const lst = s.lessons[lesson.id];
      const xp = revealedAny ? 10 : lesson.xp ?? XP.lesson;
      Object.assign(lst, { status: "done", completedAt: new Date().toISOString(), xpEarned: xp });
      s.lastTeaser = lesson.next ? { lessonId: lesson.id, text: lesson.next } : null;
      const nx = following(lesson.id);
      s.resume = nx ? { lessonId: nx.id, at: new Date().toISOString() } : null;
      save();
      addCards(lesson, info.level.id);
      award(xp, revealedAny ? "lesson (solution shown)" : "lesson complete");
      refreshHeader();
    }
    box.innerHTML = `<div class="card done-card"><div class="eyebrow">Lesson complete</div>
      <p>${lesson.cards.length ? `${lesson.cards.length} review card${lesson.cards.length > 1 ? "s" : ""} added to your queue (first review tomorrow).` : ""}</p>
      ${lesson.next ? `<p class="teaser"><strong>Next problem:</strong> ${esc(lesson.next)}</p>` : ""}
      <div class="row">${nextButton(lesson.id)}<a class="btn ghost" href="#/home">Stop here</a></div></div>`;
    box.scrollIntoView({ behavior: "smooth", block: "center" });
    const ev = await maybeMarketEvent("lesson");
    if (ev) setTimeout(() => openEvent(ev, award, XP), 1200);
  };

  for (const [i, ex] of lesson.exercises.entries()) {
    const m = await mountExercise(host, ex, {
      lessonId: lesson.id, datasets: lesson.datasets, alreadyPassed: already,
      label: lesson.exercises.length > 1 ? `Exercise ${i + 1} of ${lesson.exercises.length}` : "Exercise",
      onPass: (_res, { revealed }) => {
        revealedAny ||= revealed;
        if (mounted.every((x) => x.passed())) finish();
      },
    });
    mounted.push(m);
  }
  if (!lesson.exercises.length) { // reading-only lesson
    host.innerHTML = `<button class="btn primary" data-act="mark">Mark as read</button>`;
    host.querySelector("button").onclick = () => { s.lessons[lesson.id] ||= {}; finish(); };
  }
  if (already) el.querySelector(".complete").hidden = true;
  wireExamples(el, lesson, () => mounted.find((m) => !m.passed())?.editor || mounted[0]?.editor);
}

// ---------------------------------------------------------------- boss battles (timed, no hints)
async function renderBoss(el, header, lesson, info) {
  const s = get();
  const rec = (s.bosses[lesson.id] ||= { best: 0, attempts: [] });
  const isLevel = info.kind === "levelBoss";
  const limit = lesson.timeLimit || 600;
  el.innerHTML = `${header}
    <section class="card scenario"><div class="eyebrow">Scenario</div>${renderMarkdown(lesson.learn)}</section>
    <section class="card boss-start">
      <p><strong>Rules:</strong> ${Math.round(limit / 60)}-minute clock · no hints · score = share of hidden tests passed${isLevel ? ` · <strong>${Math.round(lesson.passMark * 100)}% unlocks the next level</strong>` : ""} · bonus XP for time left on a clean sweep.</p>
      <p class="muted small">Best so far: ${rec.attempts.length ? `${Math.round(rec.best * 100)}% over ${rec.attempts.length} attempt(s)` : "no attempts yet"}.</p>
      <button class="btn primary lg" data-act="start">Start the clock</button>
    </section>
    <div class="boss-timer" hidden><span class="t"></span><span class="score small"></span><button class="btn small" data-act="finish">Finish &amp; score</button></div>
    <section class="exercises"></section><section class="complete" hidden></section>`;

  el.querySelector("[data-act='start']").addEventListener("click", async () => {
    el.querySelector(".boss-start").remove();
    const timerEl = el.querySelector(".boss-timer");
    timerEl.hidden = false;
    const t0 = Date.now();
    const best = lesson.exercises.map(() => ({ passed: 0, total: 0 }));
    const mounted = [];
    let done = false;
    const scoreNow = () => {
      const total = lesson.exercises.reduce((a, ex) => a + ex.tests.length, 0);
      return total ? best.reduce((a, b) => a + b.passed, 0) / total : 0;
    };
    const tick = () => {
      const left = Math.max(0, limit - (Date.now() - t0) / 1000);
      timerEl.querySelector(".t").textContent = `${Math.floor(left / 60)}:${String(Math.floor(left % 60)).padStart(2, "0")}`;
      timerEl.classList.toggle("urgent", left < 60);
      timerEl.querySelector(".score").textContent = `score ${Math.round(scoreNow() * 100)}%`;
      if (left <= 0) finish(true);
    };
    const iv = setInterval(tick, 500);
    setCleanup(() => clearInterval(iv));

    const finish = (timeUp = false) => {
      if (done) return;
      done = true;
      clearInterval(iv);
      mounted.forEach((m) => m.lock(timeUp ? "Time's up: submissions closed." : "Scored: submissions closed."));
      timerEl.hidden = true;
      const seconds = Math.round((Date.now() - t0) / 1000);
      const score = scoreNow();
      const prev = rec.best;
      rec.attempts.push({ score, seconds, at: new Date().toISOString() });
      rec.best = Math.max(prev, score);
      save();
      const base = isLevel ? XP.levelBoss : XP.boss;
      let xp = Math.round(base * Math.max(0, score - prev));
      if (score === 1 && prev < 1) xp += Math.round(base * 0.5 * Math.max(0, 1 - seconds / limit));
      if (xp > 0) award(xp, isLevel ? "level boss" : "boss battle"); else markActive();
      let mastered = false;
      if (isLevel && score >= lesson.passMark && !s.levels[info.level.id]?.masteredAt) {
        s.levels[info.level.id] = { masteredAt: new Date().toISOString() };
        save();
        mastered = true;
      }
      const box = el.querySelector(".complete");
      box.hidden = false;
      const pass = !isLevel || score >= lesson.passMark;
      box.innerHTML = `<div class="card done-card ${pass ? "" : "retry"}"><div class="eyebrow">${timeUp ? "Time's up" : "Scored"}</div>
        <div class="big-num">${Math.round(score * 100)}%<span> in ${Math.floor(seconds / 60)}m ${seconds % 60}s</span></div>
        <p>${isLevel ? (pass ? "Level boss cleared. The next level is open." : `You need ${Math.round(lesson.passMark * 100)}% to unlock the next level. Check the failed tests above: each message says what was wrong. Then retry.`) : score === 1 ? "Clean sweep." : "Review the failed tests above, then retry when ready."}</p>
        <div class="row"><button class="btn" data-act="retry">Retry</button>${nextButton(lesson.id)}</div></div>`;
      box.querySelector("[data-act='retry']").onclick = () => window.dispatchEvent(new HashChangeEvent("hashchange"));
      refreshHeader();
      if (mastered) {
        const nextLv = getLevels().find((l) => l.n === info.level.n + 1);
        celebrate(`Level ${info.level.n} mastered`, nextLv ? `Level ${nextLv.n}: ${nextLv.title} is unlocked.` : "Every level mastered.");
        checkAchievements();
      }
    };
    timerEl.querySelector("[data-act='finish']").onclick = () => finish(false);
    tick();

    const host = el.querySelector(".exercises");
    for (const [i, ex] of lesson.exercises.entries()) {
      mounted.push(await mountExercise(host, { ...ex, solution: "" }, {
        lessonId: lesson.id, hints: false, datasets: lesson.datasets,
        label: lesson.exercises.length > 1 ? `Task ${i + 1} of ${lesson.exercises.length}` : "Task",
        onResult: (res) => {
          if (res.passed >= best[i].passed) best[i] = { passed: res.passed, total: res.total };
          tick();
          if (best.every((b, k) => b.passed === lesson.exercises[k].tests.length)) finish(false);
        },
      }));
    }
  });
}

// ---------------------------------------------------------------- placement test
async function renderPlacement(el, header, lesson, info) {
  el.innerHTML = `${header}${learnHTML(lesson)}<section class="exercises"></section>
    <section class="card"><button class="btn primary lg" data-act="finish">Finish placement &amp; see results</button></section><section class="complete" hidden></section>`;
  const host = el.querySelector(".exercises");
  const passed = new Map();
  for (const [i, ex] of lesson.exercises.entries()) {
    await mountExercise(host, ex, {
      lessonId: lesson.id, hints: false, confidence: true,
      label: `Item ${i + 1} of ${lesson.exercises.length}${ex.module ? ` · ${moduleTitle(ex.module)}` : ""}`,
      onResult: (res) => passed.set(ex.id, res.total > 0 && res.passed === res.total),
    });
  }
  el.querySelector("[data-act='finish']").addEventListener("click", async () => {
    const s = get();
    const byModule = new Map();
    for (const ex of lesson.exercises) {
      if (!ex.module) continue;
      const r = byModule.get(ex.module) || { ok: 0, n: 0 };
      r.n++; if (passed.get(ex.id)) r.ok++;
      byModule.set(ex.module, r);
    }
    const out = [];
    let xp = 0;
    for (const [modId, r] of byModule) {
      const mod = findModule(modId);
      const testedOut = r.ok === r.n;
      if (testedOut && mod) {
        for (const l of mod.module.lessons) {
          if (isDone(l.id) || !l.file) continue;
          const les = await loadLesson(l.id);
          s.lessons[l.id] = { status: "tested-out", completedAt: new Date().toISOString(), xpEarned: 0 };
          addCards(les, mod.level.id, { firstInterval: 3 }); // still reviewed, so knowledge is verified over time
        }
      }
      xp += r.ok * XP.placementItem;
      out.push(`<li class="${testedOut ? "pass" : "fail"}"><span class="mark">${testedOut ? "✓" : "→"}</span><span><strong>${esc(mod ? mod.module.title : modId)}</strong>: ${r.ok}/${r.n}. ${testedOut ? "Tested out. Lessons marked complete and their cards go into review." : "Study this module."}</span></li>`);
    }
    s.lessons[lesson.id] = { ...(s.lessons[lesson.id] || {}), status: "done", completedAt: new Date().toISOString() };
    save();
    if (xp) award(xp, "placement");
    const box = el.querySelector(".complete");
    box.hidden = false;
    box.innerHTML = `<div class="card done-card"><div class="eyebrow">Placement results</div><ul class="tests">${out.join("")}</ul>
      <p class="muted small">Tested-out modules still need the level boss battle (80%) to unlock the next level.</p>
      <div class="row"><a class="btn primary" href="#/home">Home</a><a class="btn ghost" href="#/level/${byModule.size ? findModule([...byModule.keys()][0])?.level.id : info.level.id}">See level</a></div></div>`;
    box.scrollIntoView({ behavior: "smooth" });
    refreshHeader();
  });
}

function findModule(modId) {
  for (const level of getLevels()) for (const module of level.modules || []) if (module.id === modId) return { level, module };
  return null;
}
const moduleTitle = (id) => findModule(id)?.module.title || id;

// ---------------------------------------------------------------- CV project
async function renderProject(el, header, lesson, info) {
  const s = get();
  const p = lesson.project || {};
  const shipped = s.projects[lesson.id];
  el.innerHTML = `${header}
    <section class="card memo"><div class="eyebrow">Project brief · from the desk head</div>${renderMarkdown(p.brief)}</section>
    <section class="card"><div class="eyebrow">Acceptance criteria</div>${renderMarkdown(p.acceptance)}</section>
    ${learnHTML(lesson)}
    <section class="exercises"></section>
    <section class="card ship"><div class="row between"><div><strong>${shipped ? "Shipped ✓" : "Ship it"}</strong>
      <div class="muted small">${shipped ? `Shipped ${shipped.shippedAt.slice(0, 10)}.` : "All acceptance tests must pass. Then put it in your GitHub repo."}</div></div>
      <div class="row"><button class="btn ghost" data-act="dl">Download .py</button><button class="btn primary" data-act="ship" disabled>Mark as shipped</button></div></div></section>
    <section class="card interview"><div class="eyebrow">How to explain this in an interview</div>${renderMarkdown(p.interview)}</section>
    <section class="card cv"><div class="eyebrow">CV bullet</div><blockquote class="cv-bullet">${renderMarkdown(p.cvBullet)}</blockquote>
      <button class="btn small" data-act="copy">Copy bullet</button></section>`;
  const host = el.querySelector(".exercises");
  let allPass = !!shipped;
  const mounted = [];
  for (const ex of lesson.exercises) {
    mounted.push(await mountExercise(host, ex, {
      lessonId: lesson.id, datasets: lesson.datasets, alreadyPassed: !!shipped, label: "Build it",
      onPass: () => { allPass = mounted.every((m) => m.passed()); el.querySelector("[data-act='ship']").disabled = !allPass || !!shipped; },
    }));
  }
  el.querySelector("[data-act='ship']").addEventListener("click", () => {
    if (!allPass || s.projects[lesson.id]) return;
    s.projects[lesson.id] = { shippedAt: new Date().toISOString() };
    s.lessons[lesson.id] = { ...(s.lessons[lesson.id] || {}), status: "done", completedAt: new Date().toISOString() };
    save();
    award(XP.project, "project shipped");
    celebrate("Project shipped", `${lesson.title}. Push it to GitHub with a README and add the CV bullet.`);
    window.dispatchEvent(new HashChangeEvent("hashchange"));
  });
  el.querySelector("[data-act='dl']").addEventListener("click", () => {
    const code = mounted[0]?.editor.getValue() || "";
    download(`${lesson.id.replace(/-project$/, "")}_${lesson.title.toLowerCase().replace(/[^a-z0-9]+/g, "_").replace(/^_|_$/g, "")}.py`, code, "text/x-python");
  });
  el.querySelector("[data-act='copy']").addEventListener("click", async () => {
    toast((await copyText(p.cvBullet.replace(/\*\*/g, ""))) ? "CV bullet copied." : "Copy failed: select the text manually.", "info");
  });
  wireExamples(el, lesson, () => mounted[0]?.editor);
}
