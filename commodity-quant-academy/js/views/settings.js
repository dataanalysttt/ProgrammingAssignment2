// settings.js: first-run setup (why + implementation intention) and the settings page:
// plan, appearance, backup/import/merge, laptop sync, phone access, content checks, reset.
import * as store from "../store.js";
import { get, save, today } from "../store.js";
import { esc, toast, confirmDialog, $ } from "../ui.js";
import { applyTheme, refreshHeader } from "../main.js";
import { allEntries, loadLesson } from "../content.js";
import { grade, run, restart } from "../pyrunner.js";

const HABITS = ["morning chai", "the evening commute home", "dinner", "the LME close", "gym", "putting my child to bed"];

function planFields(p) {
  return `<label>Why are you doing this? (one line you'll see every day)
      <input name="why" maxlength="140" value="${esc(p.why)}" placeholder="Move from operations to a trading or risk seat within 18 months"></label>
    <div class="grid2">
      <label>I'll study at<input name="studyTime" type="time" value="${esc(p.studyTime || "07:00")}" required></label>
      <label>right after<input name="habit" list="habits" value="${esc(p.habit)}" placeholder="morning chai" required>
        <datalist id="habits">${HABITS.map((h) => `<option value="${esc(h)}">`).join("")}</datalist></label>
    </div>`;
}

export function renderSetup(el) {
  const p = get().profile;
  el.innerHTML = `<section class="card setup">
    <div class="eyebrow">Commodity Quant Academy · setup</div>
    <h1>Before the first lesson</h1>
    <p>Two minutes. People who name a time and an existing habit to attach study to are much more likely to follow through than people who just intend to.</p>
    <form>${planFields(p)}
      <p class="intention-preview muted"></p>
      <button class="btn primary lg">Commit and start Level 0</button></form>
    <p class="small muted">Everything stays in this browser. Nothing is sent anywhere. Already have a backup? <a href="#/settings/backup">Import it</a>.</p></section>`;
  const form = el.querySelector("form");
  const preview = () => {
    const f = new FormData(form);
    el.querySelector(".intention-preview").textContent = `“I'll study at ${f.get("studyTime") || "…"} after ${f.get("habit") || "…"}.”`;
  };
  form.addEventListener("input", preview);
  preview();
  form.addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(form);
    Object.assign(get().profile, { why: f.get("why").trim(), studyTime: f.get("studyTime"), habit: f.get("habit").trim(), setupDone: true });
    save(true);
    location.hash = "#/lesson/l0-m1-l1";
  });
}

export async function renderSettings(el, section) {
  const s = get();
  el.innerHTML = `<nav class="sub-nav"><a class="btn small" href="#/stats">Stats</a><a class="btn small" href="#/trophies">Trophies</a><a class="btn small" href="#/weekly">Weekly review</a><a class="btn small" href="#/map">Skill map</a></nav>
  <h1>Settings</h1>
  <section class="card" id="plan"><h3>Study plan</h3><form class="plan-form">${planFields(s.profile)}<button class="btn">Save plan</button></form></section>

  <section class="card"><h3>Appearance &amp; editor</h3>
    <div class="grid2">
      <label>Theme<select name="theme">${["auto", "dark", "light"].map((t) => `<option ${s.settings.theme === t ? "selected" : ""}>${t}</option>`).join("")}</select></label>
      <label>Editor<select name="plainEditor"><option value="false" ${!s.settings.plainEditor ? "selected" : ""}>CodeMirror (syntax highlighting)</option><option value="true" ${s.settings.plainEditor ? "selected" : ""}>Plain text (simplest on iPhone)</option></select></label>
      <label>Symbol key bar<select name="keyBar">${["auto", "on", "off"].map((t) => `<option ${s.settings.keyBar === t ? "selected" : ""}>${t}</option>`).join("")}</select></label>
      <label>Load Python at startup<select name="preloadPython"><option value="false">No (saves mobile data)</option><option value="true" ${s.settings.preloadPython ? "selected" : ""}>Yes (faster first run)</option></select></label>
    </div></section>

  <section class="card" id="backup"><h3>Backup &amp; restore</h3>
    <p class="small">Last backup: <strong>${s.lastBackupAt ? s.lastBackupAt.slice(0, 16).replace("T", " ") : "never"}</strong>. Laptop and iPhone keep separate progress, so use <em>Merge</em> to combine them.</p>
    <div class="row wrap"><button class="btn primary" data-act="export">Export progress (.json)</button>
      <button class="btn" data-act="share" hidden>Share / save to Files</button>
      <label class="btn">Import (replace)<input type="file" accept=".json,application/json" data-act="import" hidden></label>
      <label class="btn">Import (merge)<input type="file" accept=".json,application/json" data-act="merge" hidden></label></div>
    <div class="sync" hidden><h4>Laptop sync</h4><p class="small">This app is being served by <code>serve.py</code>, so it can keep a copy of your progress on the laptop (<code>progress-sync/</code>). Use it to move progress between iPhone and laptop.</p>
      <div class="row wrap"><button class="btn" data-act="push">Save my progress to laptop</button><button class="btn" data-act="pull">Merge in laptop copy</button></div><p class="small muted sync-info"></p></div>
  </section>

  <section class="card" id="phone"><h3>Use it on your iPhone</h3>
    <ol class="small">
      <li>On the laptop, run <code>start-phone.sh</code> (Mac/Linux) or <code>start-phone.bat</code> (Windows). It prints a private link with a secret key.</li>
      <li>iPhone on the same Wi-Fi: open that link in Safari. The key is stored as a cookie, so you only need it once.</li>
      <li>Share → <strong>Add to Home Screen</strong> for a full-screen app.</li>
      <li>Phone progress is separate from laptop progress. Use <em>Save to laptop</em> / <em>Merge in laptop copy</em> above.</li>
    </ol>
    <p class="small muted">You are on: <code>${esc(location.origin)}</code></p></section>

  <section class="card"><h3>Checks</h3>
    <div class="row wrap"><button class="btn" data-act="check">Check all lesson content</button><button class="btn" data-act="formulas">Run formula reference tests</button><button class="btn ghost" data-act="restart-py">Restart Python</button></div>
    <pre class="check-out" hidden></pre></section>

  <section class="card danger"><h3>Reset</h3><p class="small">Deletes all progress in this browser. Export first.</p><button class="btn ghost" data-act="reset">Reset all progress…</button></section>`;

  if (section) setTimeout(() => $(`#${section}`)?.scrollIntoView({ block: "start" }), 50);

  el.querySelector(".plan-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const f = new FormData(e.target);
    Object.assign(s.profile, { why: f.get("why").trim(), studyTime: f.get("studyTime"), habit: f.get("habit").trim(), setupDone: true });
    save(); toast("Plan saved.", "info");
  });
  el.querySelectorAll("select").forEach((sel) => sel.addEventListener("change", () => {
    const v = sel.value === "true" ? true : sel.value === "false" ? false : sel.value;
    s.settings[sel.name] = v;
    save(true);
    if (sel.name === "theme") applyTheme();
    toast("Saved.", "info");
  }));

  const fileName = () => `cqa-progress-${today()}.json`;
  el.querySelector("[data-act='export']").onclick = () => { store.download(fileName(), store.exportJSON()); toast("Exported. Keep it somewhere safe (Drive, email to yourself).", "info", 4000); };
  const shareBtn = el.querySelector("[data-act='share']");
  if (navigator.canShare?.({ files: [new File(["{}"], "x.json", { type: "application/json" })] })) {
    shareBtn.hidden = false;
    shareBtn.onclick = async () => {
      try { await navigator.share({ files: [new File([store.exportJSON()], fileName(), { type: "application/json" })], title: "CQA progress" }); }
      catch { /* user cancelled */ }
    };
  }
  const readFile = (input) => new Promise((res, rej) => { const r = new FileReader(); r.onload = () => res(r.result); r.onerror = rej; r.readAsText(input.files[0]); });
  el.querySelector("[data-act='import']").onchange = async (e) => {
    try {
      const incoming = store.parseImport(await readFile(e.target));
      if (!(await confirmDialog("Replace ALL progress in this browser with the file? (A copy of the current state is kept in storage as a safety net.)", "Replace"))) return;
      store.replaceState(incoming); applyTheme(); refreshHeader(); toast("Progress imported.", "info"); location.hash = "#/home";
    } catch (err) { toast(err.message, "cost", 5000); }
  };
  el.querySelector("[data-act='merge']").onchange = async (e) => {
    try {
      const incoming = store.parseImport(await readFile(e.target));
      store.replaceState(store.mergeStates(get(), incoming)); refreshHeader(); toast("Merged.", "info"); location.hash = "#/home";
    } catch (err) { toast(err.message, "cost", 5000); }
  };

  // laptop sync, available only when served by serve.py
  fetch("api/ping").then((r) => (r.ok ? r.json() : null)).then((j) => {
    if (!j?.ok) return;
    const box = el.querySelector(".sync"); box.hidden = false;
    const info = box.querySelector(".sync-info");
    info.textContent = j.latest ? `Laptop copy: saved ${j.latest.replace("T", " ").slice(0, 16)} from ${j.device || "a device"}.` : "No laptop copy yet.";
    box.querySelector("[data-act='push']").onclick = async () => {
      const r = await fetch("api/sync", { method: "POST", headers: { "Content-Type": "application/json", "X-Device": /iPhone|iPad/.test(navigator.userAgent) ? "iPhone" : "laptop" }, body: store.exportJSON() });
      toast(r.ok ? "Saved to laptop." : "Sync failed.", r.ok ? "info" : "cost");
    };
    box.querySelector("[data-act='pull']").onclick = async () => {
      const r = await fetch("api/sync", { cache: "no-store" });
      if (!r.ok) return toast("No laptop copy yet.", "cost");
      store.replaceState(store.mergeStates(get(), store.parseImport(await r.text()))); refreshHeader(); toast("Merged laptop copy into this device.", "info");
    };
  }).catch(() => {});

  const out = el.querySelector(".check-out");
  const log = (line) => { out.hidden = false; out.textContent += line + "\n"; out.scrollTop = out.scrollHeight; };
  el.querySelector("[data-act='check']").onclick = async () => {
    out.textContent = "";
    log("Checking every exercise: the model solution must pass all tests and the starter must fail at least one.");
    let bad = 0, n = 0;
    for (const { entry } of allEntries()) {
      if (!entry.file) continue;
      let lesson;
      try { lesson = await loadLesson(entry.id); } catch (e) { log(`✗ ${entry.id}: ${e.message}`); bad++; continue; }
      if (lesson.id !== entry.id) { log(`✗ ${entry.file}: id "${lesson.id}" does not match level.json "${entry.id}"`); bad++; }
      const items = [...lesson.exercises, ...lesson.cards.filter((c) => c.kind === "code")];
      for (const ex of items) {
        n++;
        if (!ex.solution || !ex.tests?.length) { log(`✗ ${ex.id}: missing solution or tests`); bad++; continue; }
        const good = await grade(ex.solution, ex, { datasets: lesson.datasets });
        const start = await grade(ex.starter || "", ex, { datasets: lesson.datasets });
        if (good.passed !== good.total) { bad++; log(`✗ ${ex.id}: solution fails ${good.tests.filter((t) => !t.passed).map((t) => t.name + " → " + t.message).join("; ")}${good.error ? " | " + good.error : ""}`); }
        else if (start.passed === start.total) { bad++; log(`✗ ${ex.id}: starter already passes every test`); }
      }
    }
    log(`\nDone: ${n} exercises/cards checked, ${bad} problem(s).`);
  };
  el.querySelector("[data-act='formulas']").onclick = async () => {
    out.textContent = "";
    log("Running reference/test_formulas.py in Pyodide…");
    const code = await (await fetch("reference/test_formulas.py")).text();
    const res = await run(code.replace(/^sys\.path\.insert.*$/m, ""), { timeoutMs: 60000 });
    log(res.stdout || "");
    if (res.error) log(res.error);
  };
  el.querySelector("[data-act='restart-py']").onclick = () => { restart(); toast("Python restarted.", "info"); };
  el.querySelector("[data-act='reset']").onclick = async () => {
    const typed = prompt("Type RESET to delete all progress in this browser.");
    if (typed !== "RESET") return;
    store.replaceState(store.freshState());
    location.hash = "#/setup";
    location.reload();
  };
}
