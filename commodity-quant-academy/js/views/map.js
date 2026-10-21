// map.js: the full skill map and a per-level page (modules, lessons, bosses, project).
import { get } from "../store.js";
import { getLevels, getLevel, levelState, levelProgress, isDone, bossBest } from "../content.js";
import { esc } from "../ui.js";
import { skillMap } from "./widgets.js";

export function renderMap(el) {
  el.innerHTML = `<h1>Skill map</h1>
    <p class="muted">Nine levels. Each one unlocks when you score 80%+ on the previous level's boss battle.</p>
    ${skillMap()}
    <div class="legend small muted"><span class="node-chip mastered">★ mastered</span><span class="node-chip unlocked">▶ open</span><span class="node-chip planned">… content coming</span><span class="node-chip locked">🔒 locked</span></div>
    <div class="level-list">${getLevels().map((lv) => {
      const p = levelProgress(lv);
      return `<a class="card level-row ${levelState(lv)}" href="#/level/${lv.id}"><div class="eyebrow">Level ${lv.n} · ${levelState(lv)}</div>
        <h3>${esc(lv.title)}</h3><p class="small">${esc(lv.summary || "")}</p>
        ${p.total ? `<div class="bar thin"><div style="width:${p.pct * 100}%"></div></div><div class="muted small">${p.done}/${p.total} lessons</div>` : ""}
        ${lv.project ? `<div class="small"><strong>CV project:</strong> ${esc(lv.project.title)}</div>` : ""}</a>`;
    }).join("")}</div>`;
}

const lessonRow = (l, kind) => {
  const s = get();
  const st = s.lessons[l.id]?.status;
  let badge = "";
  if (kind === "boss" || kind === "levelBoss") { const b = bossBest(l.id); badge = b === null ? "" : `<span class="pill ${b >= 0.8 ? "ok" : ""}">${Math.round(b * 100)}%</span>`; }
  else if (kind === "project") badge = s.projects[l.id] ? `<span class="pill ok">shipped</span>` : "";
  else if (st === "tested-out") badge = `<span class="pill">tested out</span>`;
  else if (isDone(l.id)) badge = `<span class="pill ok">✓</span>`;
  const icon = { boss: "⚔", levelBoss: "♛", project: "◼", placement: "◎", lesson: "•" }[kind];
  return `<li class="${l.file ? "" : "planned"}"><a href="#/lesson/${l.id}"><span class="ic">${icon}</span><span class="t">${esc(l.title)}</span>${l.file ? badge : `<span class="pill muted">planned</span>`}</a>
    ${!l.file && l.objectives ? `<div class="obj small muted">${l.objectives.map(esc).join(" · ")}</div>` : ""}</li>`;
};

export function renderLevel(el, id) {
  const lv = getLevel(id);
  if (!lv) { el.innerHTML = `<div class="card">Unknown level.</div>`; return; }
  const st = levelState(lv);
  el.innerHTML = `<nav class="crumbs small"><a href="#/map">Map</a> › Level ${lv.n}</nav>
    <h1>Level ${lv.n}: ${esc(lv.title)}</h1>
    <p>${esc(lv.summary || "")}</p>
    ${st === "locked" ? `<div class="banner info"><div>Locked. Score 80%+ on the Level ${lv.n - 1} boss battle to open it. You can still read the outline${lv.placement ? " and take the placement test" : ""}.</div></div>` : ""}
    ${lv.status === "planned" ? `<div class="banner info"><div>Lessons below are outlined with objectives; full content arrives in phase ${lv.phase}.</div></div>` : ""}
    ${lv.placement ? `<section class="card"><ul class="lesson-list">${lessonRow(lv.placement, "placement")}</ul><p class="small muted">Already know some of this? Pass a module's placement items to test out of it.</p></section>` : ""}
    ${(lv.modules || []).map((m, i) => `<section class="card module"><div class="eyebrow">Module ${i + 1}</div><h3>${esc(m.title)}</h3>
      ${m.summary ? `<p class="small muted">${esc(m.summary)}</p>` : ""}
      <ul class="lesson-list">${m.lessons.map((l) => lessonRow(l, "lesson")).join("")}${m.boss ? lessonRow(m.boss, "boss") : ""}</ul></section>`).join("")}
    ${lv.levelBoss ? `<section class="card"><ul class="lesson-list">${lessonRow(lv.levelBoss, "levelBoss")}</ul><p class="small muted">80% or more unlocks the next level.</p></section>` : ""}
    ${lv.project ? `<section class="card"><div class="eyebrow">CV project</div><ul class="lesson-list">${lessonRow(lv.project, "project")}</ul>${lv.project.pitch ? `<p class="small">${esc(lv.project.pitch)}</p>` : ""}</section>` : ""}`;
}
