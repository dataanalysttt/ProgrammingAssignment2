// Prints every lesson in content/ as parsed JSON, using the same parser as the app.
// Used by tools/check_content.py. Usage: node tools/dump_content.mjs
import { readFileSync, existsSync } from "node:fs";
import { parseLesson } from "../js/mdparse.js";

const root = new URL("../content/", import.meta.url);
const manifest = JSON.parse(readFileSync(new URL("manifest.json", root)));
const out = [];
for (const l of manifest.levels) {
  const lv = JSON.parse(readFileSync(new URL(l.file, root)));
  const dir = l.file.replace(/[^/]+$/, "");
  const entries = [lv.placement, ...(lv.modules || []).flatMap((m) => [...m.lessons, m.boss]), lv.levelBoss, lv.project].filter(Boolean);
  const seen = new Set();
  for (const e of entries) {
    if (!e.file || seen.has(e.id)) continue;
    seen.add(e.id);
    if (!existsSync(new URL(dir + e.file, root))) { out.push({ entryId: e.id, file: dir + e.file, missing: true }); continue; }
    const lesson = parseLesson(readFileSync(new URL(dir + e.file, root), "utf8"), e.file);
    out.push({ entryId: e.id, file: dir + e.file, lesson });
  }
}
const events = JSON.parse(readFileSync(new URL("events.json", root)));
process.stdout.write(JSON.stringify({ lessons: out, events }));
