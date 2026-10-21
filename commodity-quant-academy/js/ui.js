// ui.js: small DOM helpers shared by all views.
import { esc } from "./mdparse.js";
export { esc };

export const $ = (sel, root = document) => root.querySelector(sel);
export const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

export function html(strings, ...vals) {
  // tagged template: values are escaped unless wrapped with raw()
  return strings.reduce((out, s, i) => {
    const v = vals[i - 1];
    const str = v && v.__raw ? v.s : Array.isArray(v) ? v.map((x) => (x && x.__raw ? x.s : esc(x))).join("") : esc(v ?? "");
    return out + str + s;
  });
}
export const raw = (s) => ({ __raw: true, s: String(s ?? "") });

export function toast(text, kind = "info", ms = 2600) {
  const box = $("#toasts");
  const el = document.createElement("div");
  el.className = `toast ${kind}`;
  el.textContent = text;
  box.appendChild(el);
  setTimeout(() => el.classList.add("out"), ms);
  setTimeout(() => el.remove(), ms + 400);
}

export function modal(contentHTML, { onClose, wide = false } = {}) {
  const root = $("#modal");
  root.innerHTML = `<div class="modal-backdrop" data-close></div><div class="modal-card ${wide ? "wide" : ""}" role="dialog" aria-modal="true">
    <button class="icon-btn modal-x" data-close aria-label="Close">✕</button>${contentHTML}</div>`;
  root.hidden = false;
  const close = () => { root.hidden = true; root.innerHTML = ""; document.removeEventListener("keydown", onKey); onClose?.(); };
  const onKey = (e) => e.key === "Escape" && close();
  document.addEventListener("keydown", onKey);
  root.querySelectorAll("[data-close]").forEach((b) => b.addEventListener("click", close));
  return { root: root.querySelector(".modal-card"), close };
}

// Several celebrations can fire at once (level mastered + badge + promotion): show them in turn.
const celebrations = [];
export function celebrate(title, text) {
  celebrations.push({ title, text });
  if (celebrations.length === 1 && $("#modal").hidden) showNextCelebration();
}
function showNextCelebration() {
  const c = celebrations[0];
  if (!c) return;
  modal(`<div class="celebrate"><div class="celebrate-badge">★</div><h2>${esc(c.title)}</h2><p>${esc(c.text)}</p>
    <button class="btn primary" data-close>Continue</button></div>`, { onClose: () => { celebrations.shift(); setTimeout(showNextCelebration, 150); } });
}

export function confirmDialog(text, okLabel = "OK") {
  return new Promise((resolve) => {
    let answered = false;
    const m = modal(`<p>${esc(text)}</p><div class="row end"><button class="btn ghost" data-no>Cancel</button><button class="btn primary" data-yes>${esc(okLabel)}</button></div>`,
      { onClose: () => !answered && resolve(false) });
    m.root.querySelector("[data-yes]").onclick = () => { answered = true; m.close(); resolve(true); };
    m.root.querySelector("[data-no]").onclick = () => { answered = true; m.close(); resolve(false); };
  });
}

// Render a run/grade result into an output panel.
export function renderOutput(el, res, { showTests = true } = {}) {
  const parts = [];
  if (res.stdout) parts.push(`<div class="out-label">Output</div><pre class="stdout">${esc(res.stdout)}</pre>`);
  if (res.stderr) parts.push(`<div class="out-label">Warnings</div><pre class="stderr">${esc(res.stderr)}</pre>`);
  if (res.error) parts.push(`<div class="out-label err">Error</div><pre class="stderr">${esc(res.error)}</pre>`);
  for (const f of res.figures || []) parts.push(`<img class="figure" alt="plot output" src="data:image/png;base64,${f}">`);
  if (showTests && res.tests?.length) {
    const passed = res.tests.filter((t) => t.passed).length;
    parts.push(`<div class="out-label">Tests: ${passed}/${res.tests.length} passed</div><ul class="tests">` +
      res.tests.map((t) => `<li class="${t.passed ? "pass" : "fail"}"><span class="mark">${t.passed ? "✓" : "✗"}</span><span><strong>${esc(t.name)}</strong>${t.message ? `<br><span class="why">${esc(t.message)}</span>` : ""}</span></li>`).join("") + "</ul>");
  }
  if (!parts.length) parts.push(`<pre class="stdout muted">(no output: use print() to see values)</pre>`);
  el.innerHTML = parts.join("");
  el.hidden = false;
}

export function fmtMinutes(m) {
  m = Math.round(m);
  return m < 60 ? `${m} min` : `${Math.floor(m / 60)} h ${m % 60} min`;
}

export async function copyText(text) {
  try { await navigator.clipboard.writeText(text); return true; }
  catch {
    // http:// on a LAN address is not a secure context, so the Clipboard API is missing on iPhone
    const ta = document.createElement("textarea");
    ta.value = text; document.body.appendChild(ta); ta.select();
    const ok = document.execCommand("copy"); ta.remove(); return ok;
  }
}
