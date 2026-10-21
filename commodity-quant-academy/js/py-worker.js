// py-worker.js: runs Python in a Web Worker so a slow or infinite loop never freezes the page.
// The main thread (pyrunner.js) can terminate this worker and start a fresh one at any time.

const PYODIDE_VERSION = "0.27.7";
const CDN = `https://cdn.jsdelivr.net/pyodide/v${PYODIDE_VERSION}/full/`;
const LOCAL = new URL("../vendor/pyodide/", self.location).href; // optional offline copy
const APP_ROOT = new URL("../", self.location).href;

let pyodide = null;
const written = new Set(); // data files already copied into Pyodide's virtual filesystem

async function exists(url) {
  try { return (await fetch(url, { method: "HEAD" })).ok; } catch { return false; }
}

async function boot() {
  const indexURL = (await exists(LOCAL + "pyodide.js")) ? LOCAL : CDN;
  importScripts(indexURL + "pyodide.js");
  pyodide = await self.loadPyodide({ indexURL });
  pyodide.setStdin({ error: true }); // input() raises instead of hanging
  const harness = await (await fetch(APP_ROOT + "js/harness.py")).text();
  pyodide.FS.mkdirTree("/home/pyodide/data");
  pyodide.FS.writeFile("/home/pyodide/cqa_harness.py", harness);
  pyodide.runPython(`
import os, sys
os.environ["MPLBACKEND"] = "AGG"
os.chdir("/home/pyodide")
sys.path.insert(0, "/home/pyodide")
import cqa_harness`);
  return indexURL === LOCAL ? "local" : "cdn";
}

// Copy any data/<file>.csv mentioned in the code (or listed by the lesson) into the FS.
async function stageData(text, datasets) {
  const names = new Set(datasets || []);
  for (const m of text.matchAll(/data\/([\w.-]+\.(?:csv|json|xlsx))/g)) names.add(m[1]);
  for (const name of names) {
    if (written.has(name)) continue;
    const res = await fetch(APP_ROOT + "data/" + name);
    if (!res.ok) throw new Error(`Dataset data/${name} not found. Run: python data/generate_data.py`);
    pyodide.FS.writeFile("/home/pyodide/data/" + name, new Uint8Array(await res.arrayBuffer()));
    written.add(name);
  }
  if (/\bformulas\b/.test(text) && !written.has("formulas.py")) {
    pyodide.FS.writeFile("/home/pyodide/formulas.py", await (await fetch(APP_ROOT + "reference/formulas.py")).text());
    written.add("formulas.py");
  }
}

let ready = null;
self.onmessage = async (e) => {
  const { id, type } = e.data;
  try {
    if (!ready) ready = boot();
    const source = await ready;
    if (type === "init") return self.postMessage({ id, type: "ready", source });

    const { code, setup = "", tests = [], datasets = [] } = e.data;
    const all = [code, setup, ...tests.map((t) => t.code)].join("\n");
    self.postMessage({ id, type: "status", text: "Loading packages…" });
    await pyodide.loadPackagesFromImports(all);
    await stageData(all, datasets);
    self.postMessage({ id, type: "running" }); // the main thread starts its timeout here
    const fn = pyodide.globals.get("cqa_harness").run;
    const py = fn(code, setup, pyodide.toPy(tests));
    const result = py.toJs({ dict_converter: Object.fromEntries });
    py.destroy();
    self.postMessage({ id, type: "result", result });
  } catch (err) {
    self.postMessage({ id, type: "fatal", error: String(err && err.message || err) });
  }
};
