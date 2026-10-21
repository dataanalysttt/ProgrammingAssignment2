// pyrunner.js: main-thread wrapper around py-worker.js.
// run() resolves with { stdout, stderr, error, tests, figures, ms }. It never rejects for
// learner mistakes; infrastructure failures come back as { error } too.

let worker = null;
let seq = 0;
const pending = new Map();
const listeners = new Set();
export let pyState = "idle"; // idle | loading | ready | busy

function setState(s, text = "") {
  pyState = s;
  listeners.forEach((fn) => fn(s, text));
}
export function onPyState(fn) { listeners.add(fn); return () => listeners.delete(fn); }

function spawn() {
  worker = new Worker(new URL("./py-worker.js", import.meta.url));
  worker.onmessage = (e) => {
    const p = pending.get(e.data.id);
    if (!p) return;
    const { type } = e.data;
    if (type === "status") setState("busy", e.data.text);
    else if (type === "running") p.onRunning?.();
    else {
      pending.delete(e.data.id);
      clearTimeout(p.timer);
      setState("ready");
      if (type === "ready") p.resolve({ source: e.data.source });
      else if (type === "result") p.resolve({ ...e.data.result, ms: Math.round(performance.now() - p.t0) });
      else p.resolve({ stdout: "", stderr: "", tests: [], figures: [], error: "Python could not start: " + e.data.error +
        "\nIf you are offline, see README → 'Offline Pyodide'." });
    }
  };
  worker.onerror = (e) => { console.error(e); };
}

function send(msg, timeoutMs) {
  if (!worker) spawn();
  const id = ++seq;
  return new Promise((resolve) => {
    const entry = { resolve, t0: performance.now(), timer: null };
    // the clock starts only once packages are loaded and user code begins
    entry.onRunning = () => {
      entry.t0 = performance.now();
      if (timeoutMs) entry.timer = setTimeout(() => {
        restart();
        resolve({ stdout: "", stderr: "", tests: (msg.tests || []).map((t) => ({ name: t.name, passed: false, message: "Not run (time limit)." })),
          figures: [], error: `Stopped after ${timeoutMs / 1000} s. Check for a loop that never ends (e.g. a while condition that never becomes False).` });
      }, timeoutMs);
    };
    pending.set(id, entry);
    worker.postMessage({ id, ...msg });
  });
}

export function restart() {
  if (worker) worker.terminate();
  worker = null;
  pending.clear();
  setState("idle");
}

export async function initPython() {
  if (pyState === "ready") return;
  setState("loading", "Starting Python (first load downloads ~10 MB, then it is cached)…");
  return send({ type: "init" });
}

// iPhone/Mac "smart punctuation" turns quotes into curly quotes, which Python rejects.
export function normaliseCode(code) {
  return String(code).replace(/[“”„]/g, '"').replace(/[‘’‚]/g, "'")
    .replace(/ /g, " ").replace(/\t/g, "    ");
}

export async function run(code, { setup = "", tests = [], datasets = [], timeoutMs = 20000 } = {}) {
  if (pyState !== "ready") await initPython();
  setState("busy", "Running…");
  return send({ type: "run", code: normaliseCode(code), setup, tests, datasets }, timeoutMs);
}

// Convenience used by the grader: run and summarise.
export async function grade(code, exercise, opts = {}) {
  const res = await run(code, { setup: exercise.setup || "", tests: exercise.tests || [], datasets: opts.datasets, timeoutMs: opts.timeoutMs });
  const passed = res.tests.filter((t) => t.passed).length;
  return { ...res, passed, total: res.tests.length, score: res.tests.length ? passed / res.tests.length : 0 };
}
