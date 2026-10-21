// editor.js: CodeMirror 6 editor with a plain <textarea> fallback.
// Load order: vendor/codemirror.bundle.js (offline copy) -> esm.sh CDN -> textarea.
// Every editor gets Ctrl/Cmd+Enter = Run and Ctrl/Cmd+Shift+Enter = Submit.

import { get } from "./store.js";

let cmPromise = null;
function loadCM() {
  if (!cmPromise) {
    cmPromise = import("../vendor/codemirror.bundle.js").catch(async () => {
      const [cm, view, state, lang, cmds, py, dark] = await Promise.all([
        import("https://esm.sh/codemirror@6.0.1"),
        import("https://esm.sh/@codemirror/view@6.34.1"),
        import("https://esm.sh/@codemirror/state@6.4.1"),
        import("https://esm.sh/@codemirror/language@6.10.3"),
        import("https://esm.sh/@codemirror/commands@6.7.1"),
        import("https://esm.sh/@codemirror/lang-python@6.1.6"),
        import("https://esm.sh/@codemirror/theme-one-dark@6.1.2"),
      ]);
      return { ...cm, ...view, ...state, ...lang, ...cmds, ...py, ...dark };
    }).catch(() => null);
  }
  return cmPromise;
}

const isDark = () => document.documentElement.dataset.themeResolved === "dark";
const themeListeners = new Set();
export function notifyThemeChange() { themeListeners.forEach((f) => f()); }

const KEYS = ["Tab", "(", ")", "[", "]", "{", "}", ":", "=", '"', "'", ",", ".", "_", "#", "+", "-", "*", "/", "<", ">"];

export async function createEditor(parent, { doc = "", onRun, onSubmit, onChange, minLines = 8 } = {}) {
  parent.classList.add("editor-host");
  const wrap = document.createElement("div");
  wrap.className = "editor";
  wrap.style.setProperty("--min-lines", minLines);
  parent.appendChild(wrap);

  const touch = matchMedia("(pointer: coarse)").matches;
  const keyBarPref = get().settings.keyBar;
  const showKeyBar = keyBarPref === "on" || (keyBarPref === "auto" && touch);
  const usePlain = get().settings.plainEditor;
  const cm = usePlain ? null : await loadCM();

  let api;
  if (cm) {
    const themeComp = new cm.Compartment();
    const runKeys = cm.Prec.highest(cm.keymap.of([
      { key: "Mod-Enter", run: () => (onRun?.(), true) },
      { key: "Mod-Shift-Enter", run: () => (onSubmit?.(), true) },
    ]));
    const view = new cm.EditorView({
      parent: wrap,
      state: cm.EditorState.create({
        doc,
        extensions: [
          runKeys, cm.basicSetup, cm.python(), cm.indentUnit.of("    "), cm.keymap.of([cm.indentWithTab]),
          themeComp.of(isDark() ? cm.oneDark : []),
          cm.EditorView.contentAttributes.of({ autocorrect: "off", autocapitalize: "off", spellcheck: "false", "aria-label": "Python code editor" }),
          cm.EditorView.updateListener.of((u) => u.docChanged && onChange?.(u.state.doc.toString())),
        ],
      }),
    });
    const onTheme = () => view.dispatch({ effects: themeComp.reconfigure(isDark() ? cm.oneDark : []) });
    themeListeners.add(onTheme);
    api = {
      getValue: () => view.state.doc.toString(),
      setValue: (v) => view.dispatch({ changes: { from: 0, to: view.state.doc.length, insert: v } }),
      insert: (t) => { view.dispatch(view.state.replaceSelection(t)); view.focus(); },
      focus: () => view.focus(),
      destroy: () => { themeListeners.delete(onTheme); view.destroy(); },
      kind: "codemirror",
    };
  } else {
    const ta = document.createElement("textarea");
    ta.className = "plain-editor";
    ta.value = doc;
    ta.rows = Math.max(minLines, doc.split("\n").length + 1);
    Object.assign(ta, { spellcheck: false, autocapitalize: "off", autocomplete: "off" });
    ta.setAttribute("autocorrect", "off");
    ta.setAttribute("aria-label", "Python code editor");
    ta.addEventListener("keydown", (e) => {
      if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) { e.preventDefault(); e.shiftKey ? onSubmit?.() : onRun?.(); }
      else if (e.key === "Tab") { e.preventDefault(); ta.setRangeText("    ", ta.selectionStart, ta.selectionEnd, "end"); }
      else if (e.key === "Enter") { // keep indentation of the current line, add 4 after a colon
        const before = ta.value.slice(0, ta.selectionStart);
        const line = before.slice(before.lastIndexOf("\n") + 1);
        const indent = line.match(/^\s*/)[0] + (/:\s*$/.test(line) ? "    " : "");
        e.preventDefault();
        ta.setRangeText("\n" + indent, ta.selectionStart, ta.selectionEnd, "end");
      }
    });
    ta.addEventListener("input", () => onChange?.(ta.value));
    wrap.appendChild(ta);
    api = {
      getValue: () => ta.value,
      setValue: (v) => { ta.value = v; },
      insert: (t) => { ta.setRangeText(t, ta.selectionStart, ta.selectionEnd, "end"); ta.focus(); onChange?.(ta.value); },
      focus: () => ta.focus(),
      destroy: () => {},
      kind: "plain",
    };
  }

  if (showKeyBar) {
    // iPhone keyboards hide brackets, colons and Tab behind extra taps; this row puts them one tap away.
    const bar = document.createElement("div");
    bar.className = "key-bar";
    bar.innerHTML = KEYS.map((k) => `<button type="button" tabindex="-1" data-k="${k === '"' ? "&quot;" : k}">${k === "Tab" ? "⇥" : k}</button>`).join("");
    bar.addEventListener("pointerdown", (e) => e.preventDefault()); // keep the keyboard open
    bar.addEventListener("click", (e) => {
      const k = e.target.closest("button")?.dataset.k;
      if (k) api.insert(k === "Tab" ? "    " : k);
    });
    wrap.appendChild(bar);
  }
  return api;
}
