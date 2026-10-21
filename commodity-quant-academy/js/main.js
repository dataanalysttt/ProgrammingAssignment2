// main.js: boot, router, header, theme and keyboard shortcuts.
import * as store from "./store.js";
import { loadCurriculum } from "./content.js";
import { setHooks, startActivityTimer, rankInfo, streakInfo, checkAchievements } from "./gamify.js";
import { toast, celebrate, modal, $ } from "./ui.js";
import { notifyThemeChange } from "./editor.js";
import { initPython, onPyState } from "./pyrunner.js";
import { renderHome } from "./views/home.js";
import { renderLesson } from "./views/lesson.js";
import { renderReview, renderQuick } from "./views/review.js";
import { renderMap, renderLevel } from "./views/map.js";
import { renderStats, renderTrophies, renderWeekly } from "./views/stats.js";
import { renderSettings, renderSetup } from "./views/settings.js";

const routes = {
  home: renderHome, map: renderMap, level: renderLevel, lesson: renderLesson,
  review: renderReview, quick: renderQuick, stats: renderStats, trophies: renderTrophies,
  weekly: renderWeekly, settings: renderSettings, setup: renderSetup,
};

let cleanup = null;
export function setCleanup(fn) { cleanup = fn; }

async function route() {
  const [name, ...args] = (location.hash.replace(/^#\/?/, "") || "home").split("/");
  const view = routes[name] || renderHome;
  if (!store.get().profile.setupDone && name !== "setup" && name !== "settings") { location.hash = "#/setup"; return; }
  try { cleanup?.(); } catch { /* view already gone */ }
  cleanup = null;
  // a fresh element per render, so listeners from the previous view are dropped with it
  const main = document.createElement("div");
  main.className = `view view-${name}`;
  $("#view").replaceChildren(main);
  document.querySelectorAll("[data-nav]").forEach((a) => a.classList.toggle("active", a.dataset.nav === name));
  window.scrollTo(0, 0);
  try { await view(main, ...args.map(decodeURIComponent)); }
  catch (e) { console.error(e); main.innerHTML = `<div class="card"><h2>Something broke</h2><pre class="stderr">${String(e.message || e)}</pre><a class="btn" href="#/home">Home</a></div>`; }
  refreshHeader();
}

export function refreshHeader() {
  const r = rankInfo();
  const st = streakInfo();
  $("#hdr-rank").textContent = r.rank.name;
  $("#hdr-xp").textContent = `${r.xp.toLocaleString()} XP`;
  $("#hdr-streak").textContent = `${st.current}d`;
  $("#hdr-streak").parentElement.title = `Streak ${st.current} days · ${st.hedges} hedge token(s)`;
}

// ---------------------------------------------------------------- theme
export function applyTheme() {
  const pref = store.get().settings.theme;
  const dark = pref === "dark" || (pref === "auto" && matchMedia("(prefers-color-scheme: dark)").matches);
  document.documentElement.dataset.theme = pref;
  document.documentElement.dataset.themeResolved = dark ? "dark" : "light";
  document.querySelector('meta[name="theme-color"]')?.setAttribute("content", dark ? "#0f1419" : "#f6f4ef");
  notifyThemeChange();
}

function shortcuts() {
  let g = false;
  document.addEventListener("keydown", (e) => {
    const typing = e.target.closest?.("input, textarea, [contenteditable=true], .cm-editor");
    if (typing || e.ctrlKey || e.metaKey || e.altKey) return;
    if (e.key === "?") {
      modal(`<h2>Keyboard shortcuts</h2><table class="kbd-table"><tbody>
        <tr><td><kbd>Ctrl</kbd>/<kbd>⌘</kbd> + <kbd>Enter</kbd></td><td>Run code</td></tr>
        <tr><td><kbd>Ctrl</kbd>/<kbd>⌘</kbd> + <kbd>Shift</kbd> + <kbd>Enter</kbd></td><td>Submit for grading</td></tr>
        <tr><td><kbd>g</kbd> then <kbd>h</kbd> / <kbd>r</kbd> / <kbd>m</kbd> / <kbd>s</kbd></td><td>Home / Review / Map / Stats</td></tr>
        <tr><td><kbd>5</kbd></td><td>5-minute mode</td></tr><tr><td><kbd>t</kbd></td><td>Toggle theme</td></tr>
        <tr><td><kbd>?</kbd></td><td>This help</td></tr></tbody></table>`);
      return;
    }
    if (g) {
      g = false;
      const to = { h: "home", r: "review", m: "map", s: "stats" }[e.key];
      if (to) location.hash = `#/${to}`;
      return;
    }
    if (e.key === "g") { g = true; setTimeout(() => (g = false), 1200); }
    else if (e.key === "5") location.hash = "#/quick";
    else if (e.key === "t") toggleTheme();
  });
}

function toggleTheme() {
  const s = store.get();
  s.settings.theme = document.documentElement.dataset.themeResolved === "dark" ? "light" : "dark";
  store.save();
  applyTheme();
}

async function boot() {
  store.load();
  applyTheme();
  matchMedia("(prefers-color-scheme: dark)").addEventListener?.("change", applyTheme);
  if (!store.storageOk) document.getElementById("storage-warning").hidden = false;
  setHooks({ toast, celebrate: (t, d) => { celebrate(t, d); refreshHeader(); } });
  store.onExternalChange(() => { refreshHeader(); toast("Progress updated from another tab.", "info"); });
  $("#theme-toggle").addEventListener("click", toggleTheme);
  shortcuts();
  const pyDot = $("#py-status");
  onPyState((s, text) => { pyDot.dataset.state = s; pyDot.title = text || `Python: ${s}`; });
  startActivityTimer(() => toast("90 minutes today. Leave something for tomorrow: stopping now helps it stick.", "info", 7000));
  try { await loadCurriculum(); }
  catch (e) {
    $("#view").innerHTML = `<div class="card"><h2>Content failed to load</h2><p>Open the app through the local server (start.sh / start.bat), not by double-clicking index.html.</p><pre class="stderr">${e}</pre></div>`;
    return;
  }
  checkAchievements();
  window.addEventListener("hashchange", route);
  await route();
  if (store.get().settings.preloadPython) setTimeout(() => initPython(), 1500);
}

boot();
