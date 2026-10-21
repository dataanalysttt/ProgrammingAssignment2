// exercise.js: one auto-graded exercise: prompt, confidence call, editor, Run/Submit,
// progressive hints with XP cost, and specific test feedback.
import { get, save } from "../store.js";
import { award, XP } from "../gamify.js";
import { createEditor } from "../editor.js";
import { run, grade } from "../pyrunner.js";
import { renderMarkdown } from "../mdparse.js";
import { esc, renderOutput, toast } from "../ui.js";

const CONF = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

/**
 * opts: { lessonId, hints=true, confidence=true, timed=false, datasets, alreadyPassed,
 *         onResult(res), onPass(res, {revealed}), label }
 * returns { editor, el, lock(), passed() }
 */
export async function mountExercise(host, ex, opts = {}) {
  const s = get();
  const { lessonId = "x", hints = true, confidence = true } = opts;
  const lstate = (s.lessons[lessonId] ||= { status: "started", attempts: 0, hintsUsed: 0, hints: {} });
  lstate.hints ||= {};
  let hintsShown = lstate.hints[ex.id] || 0;
  let conf = null;
  let fails = 0;
  let passed = !!opts.alreadyPassed;
  let locked = false;
  const askConfidence = confidence && !passed && !s.calibration.some((c) => c.id === ex.id);

  const el = document.createElement("div");
  el.className = "exercise";
  el.innerHTML = `
    ${opts.label ? `<div class="eyebrow">${esc(opts.label)}</div>` : ""}
    <div class="prompt">${renderMarkdown(ex.prompt)}</div>
    ${askConfidence ? `<div class="confidence"><span class="small">Before you start: how sure are you that your <em>first</em> submission will pass every test?</span>
      <div class="seg">${CONF.map((c) => `<button type="button" data-conf="${c}">${Math.round(c * 100)}%</button>`).join("")}</div></div>` : ""}
    <div class="ed"></div>
    <div class="ex-bar">
      <button class="btn" data-act="run" title="Ctrl/Cmd+Enter">Run</button>
      <button class="btn primary" data-act="submit" title="Ctrl/Cmd+Shift+Enter">Submit</button>
      ${hints && ex.hints.length ? `<button class="btn ghost" data-act="hint">Hint <span class="hint-count"></span></button>` : ""}
      <button class="btn ghost" data-act="reset" title="Restore the starter code">Reset</button>
      <span class="run-state muted small" aria-live="polite"></span>
    </div>
    <div class="hints"></div>
    <div class="output" hidden></div>
    <div class="after"></div>`;
  host.appendChild(el);

  const draftKey = ex.id;
  const editor = await createEditor(el.querySelector(".ed"), {
    doc: s.drafts[draftKey] ?? ex.starter ?? "",
    onRun: () => doRun(),
    onSubmit: () => doSubmit(),
    onChange: (v) => { s.drafts[draftKey] = v; save(); },
    minLines: Math.min(18, Math.max(6, (ex.starter || "").split("\n").length + 2)),
  });

  const out = el.querySelector(".output");
  const stateEl = el.querySelector(".run-state");
  const hintsEl = el.querySelector(".hints");
  const btn = (a) => el.querySelector(`[data-act="${a}"]`);

  function renderHints() {
    hintsEl.innerHTML = ex.hints.slice(0, hintsShown).map((h, i) => `<div class="hint"><div class="eyebrow">Hint ${i + 1} of ${ex.hints.length}${i === 0 ? " · nudge" : i === 1 ? " · concept" : " · partial code"}</div>${renderMarkdown(h)}</div>`).join("");
    const hb = btn("hint");
    if (hb) {
      const nextCost = XP.hint[hintsShown] ?? XP.hint[XP.hint.length - 1];
      hb.querySelector(".hint-count").textContent = hintsShown < ex.hints.length ? `(${hintsShown + 1}/${ex.hints.length}, −${nextCost} XP)` : "(all shown)";
      hb.disabled = hintsShown >= ex.hints.length;
    }
  }
  renderHints();

  el.querySelectorAll("[data-conf]").forEach((b) => b.addEventListener("click", () => {
    conf = Number(b.dataset.conf);
    el.querySelectorAll("[data-conf]").forEach((x) => x.classList.toggle("on", x === b));
  }));

  const busy = (on, text = "") => {
    ["run", "submit"].forEach((a) => btn(a) && (btn(a).disabled = on || locked));
    stateEl.textContent = text;
  };

  async function doRun() {
    if (locked) return;
    busy(true, "Running…");
    const res = await run(editor.getValue(), { setup: ex.setup, datasets: opts.datasets });
    busy(false, res.ms != null ? `${res.ms} ms` : "");
    renderOutput(out, res, { showTests: false });
  }

  async function doSubmit() {
    if (locked) return;
    if (askConfidence && conf === null && !s.calibration.some((c) => c.id === ex.id)) {
      toast("Pick a confidence level first: it's how you build calibration.", "info");
      el.querySelector(".confidence")?.classList.add("pulse");
      return;
    }
    busy(true, "Grading…");
    const res = await grade(editor.getValue(), ex, { datasets: opts.datasets });
    busy(false, `${res.passed}/${res.total} tests`);
    renderOutput(out, res);
    lstate.attempts = (lstate.attempts || 0) + 1;
    if (askConfidence && !s.calibration.some((c) => c.id === ex.id)) {
      s.calibration.push({ at: new Date().toISOString(), id: ex.id, conf, correct: res.passed === res.total });
      el.querySelector(".confidence")?.remove();
    }
    save();
    opts.onResult?.(res);
    if (res.total && res.passed === res.total) {
      const first = !passed;
      passed = true;
      if (first) opts.onPass?.(res, { revealed: false });
      showSolutionLink(false);
    } else {
      fails++;
      if (hints && fails >= 3 && hintsShown >= ex.hints.length && ex.solution) showSolutionLink(true);
    }
  }

  function showSolutionLink(giveUp) {
    if (!ex.solution) return;
    const after = el.querySelector(".after");
    if (after.querySelector(".solution")) return;
    after.innerHTML = `<details class="solution"><summary>${giveUp ? "Stuck? Show the model solution (lesson completes with reduced XP)" : "Compare with the model solution"}</summary><pre><code>${esc(ex.solution)}</code></pre></details>`;
    if (giveUp) after.querySelector("details").addEventListener("toggle", (e) => {
      if (e.target.open && !passed) { passed = true; opts.onPass?.(null, { revealed: true }); }
    }, { once: true });
  }

  btn("run")?.addEventListener("click", doRun);
  btn("submit")?.addEventListener("click", doSubmit);
  btn("reset")?.addEventListener("click", () => { editor.setValue(ex.starter || ""); delete s.drafts[draftKey]; save(); });
  btn("hint")?.addEventListener("click", () => {
    if (hintsShown >= ex.hints.length) return;
    award(-(XP.hint[hintsShown] ?? 15), `hint ${hintsShown + 1}`, { countsAsActive: false });
    hintsShown++;
    lstate.hints[ex.id] = hintsShown;
    lstate.hintsUsed = (lstate.hintsUsed || 0) + 1;
    save();
    renderHints();
  });

  return {
    el, editor,
    passed: () => passed,
    lock: (reason = "Submissions closed.") => { locked = true; busy(false, reason); },
  };
}
