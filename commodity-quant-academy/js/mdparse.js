// mdparse.js: turns a lesson Markdown file into the lesson object documented in
// CONTENT_GUIDE.md, and renders Markdown to safe HTML. No DOM access, so Node can
// import this file too (tools/dump_content.mjs uses it to validate content).

// ---------------------------------------------------------------- front matter
function parseScalar(v) {
  v = v.trim();
  if (v === "") return "";
  if (/^-?\d+(\.\d+)?$/.test(v)) return Number(v);
  if (v === "true" || v === "false") return v === "true";
  if (v.startsWith("[") && v.endsWith("]")) {
    return v.slice(1, -1).split(",").map((s) => s.trim()).filter(Boolean).map(unquote);
  }
  return unquote(v);
}
const unquote = (s) => (/^(["']).*\1$/.test(s) ? s.slice(1, -1) : s);

function parseFrontMatter(lines) {
  const meta = {};
  let key = null;
  for (const line of lines) {
    const item = line.match(/^\s*-\s+(.*)$/);
    if (item && key) {
      if (!Array.isArray(meta[key])) meta[key] = [];
      meta[key].push(unquote(item[1].trim()));
      continue;
    }
    const kv = line.match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (kv) {
      key = kv[1];
      meta[key] = kv[2].trim() === "" ? [] : parseScalar(kv[2]);
    }
  }
  return meta;
}

// ---------------------------------------------------------------- blocks
// Split the body into sections on "## " headings, ignoring headings inside code fences.
function splitSections(lines, level) {
  const marker = "#".repeat(level) + " ";
  const sections = [];
  let cur = { head: null, lines: [] };
  let inFence = false;
  for (const line of lines) {
    if (/^\s*```/.test(line)) inFence = !inFence;
    if (!inFence && line.startsWith(marker)) {
      sections.push(cur);
      cur = { head: line.slice(marker.length).trim(), lines: [] };
    } else cur.lines.push(line);
  }
  sections.push(cur);
  return sections;
}

// Pull fenced blocks that carry a role ("python starter", 'python test "name"', ...) out of
// a section. Returns { text, blocks: [{role, name, code}] }; fences without a role stay in text.
const ROLES = ["starter", "solution", "test", "setup", "example"];
function extractFences(lines, keepExamples = true) {
  const out = [];
  const blocks = [];
  let i = 0;
  while (i < lines.length) {
    const open = lines[i].match(/^\s*```\s*(\w+)?\s*(\w+)?\s*(?:"([^"]*)")?\s*$/);
    if (open) {
      const body = [];
      let j = i + 1;
      while (j < lines.length && !/^\s*```\s*$/.test(lines[j])) body.push(lines[j++]);
      const role = open[2] && ROLES.includes(open[2]) ? open[2] : null;
      if (role && !(role === "example" && keepExamples)) {
        blocks.push({ role, name: open[3] || "", code: body.join("\n") });
      } else {
        out.push(...lines.slice(i, j + 1));
      }
      i = j + 1;
      continue;
    }
    out.push(lines[i++]);
  }
  return { text: out.join("\n").trim(), blocks };
}

function parseAttrs(s) {
  const attrs = {};
  for (const m of (s || "").matchAll(/(\w+)=("[^"]*"|\S+)/g)) attrs[m[1]] = unquote(m[2]);
  return attrs;
}

function parseExercise(head, lines, idx, lessonId) {
  const attrs = parseAttrs(head.replace(/^Exercise:?/i, ""));
  const subs = splitSections(lines, 3);
  const main = extractFences(subs[0].lines);
  const ex = {
    id: attrs.id ? `${lessonId}.${attrs.id}` : `${lessonId}.ex${idx + 1}`,
    module: attrs.module || null,
    title: attrs.title || "",
    prompt: main.text,
    setup: "", starter: "", solution: "", tests: [], hints: [],
  };
  for (const b of main.blocks) {
    if (b.role === "test") ex.tests.push({ name: b.name || `Test ${ex.tests.length + 1}`, code: b.code });
    else ex[b.role] = b.code;
  }
  for (const s of subs.slice(1)) {
    if (/^Hint/i.test(s.head)) ex.hints.push(s.lines.join("\n").trim());
  }
  return ex;
}

function parseCards(lines, lessonId, defaultConcept) {
  const cards = [];
  for (const s of splitSections(lines, 3).slice(1)) {
    const m = s.head.match(/^Card\s+(recall|code)\s*(.*)$/i);
    if (!m) continue;
    const kind = m[1].toLowerCase();
    const { text, blocks } = extractFences(s.lines, false);
    const card = { id: `${lessonId}#c${cards.length + 1}`, kind, concept: defaultConcept, q: "", a: "" };
    const attrs = parseAttrs(m[2]);
    if (attrs.id) card.id = `${lessonId}#${attrs.id}`;
    // "concept:", "Q:", "A:" may span several lines each
    let field = null;
    const buf = { q: [], a: [] };
    for (const line of text.split("\n")) {
      const f = line.match(/^(concept|Q|A):\s?(.*)$/);
      if (f) {
        if (f[1] === "concept") { card.concept = f[2].trim(); field = null; continue; }
        field = f[1].toLowerCase();
        buf[field].push(f[2]);
      } else if (field) buf[field].push(line);
    }
    card.q = buf.q.join("\n").trim();
    card.a = buf.a.join("\n").trim();
    if (kind === "code") {
      card.starter = ""; card.solution = ""; card.setup = ""; card.tests = [];
      for (const b of blocks) {
        if (b.role === "test") card.tests.push({ name: b.name || `Test ${card.tests.length + 1}`, code: b.code });
        else if (b.role in card) card[b.role] = b.code;
      }
    }
    cards.push(card);
  }
  return cards;
}

export function parseLesson(source, fileHint = "") {
  if (fileHint.endsWith(".json")) return normaliseLesson(JSON.parse(source));
  const lines = source.replace(/\r\n?/g, "\n").split("\n");
  let meta = {};
  let body = lines;
  if (lines[0].trim() === "---") {
    const end = lines.indexOf("---", 1);
    meta = parseFrontMatter(lines.slice(1, end));
    body = lines.slice(end + 1);
  }
  const lesson = {
    id: meta.id, type: meta.type || "lesson", title: meta.title || "(untitled)",
    minutes: meta.minutes || 15, xp: meta.xp ?? 50,
    concepts: [].concat(meta.concepts || []), objectives: [].concat(meta.objectives || []),
    status: meta.status || "ready", timeLimit: meta.timeLimit || null,
    passMark: meta.passMark ?? 0.8, datasets: [].concat(meta.datasets || []),
    learn: "", desk: "", next: "", exercises: [], cards: [], project: null,
  };
  const project = {};
  for (const s of splitSections(body, 2).slice(1)) {
    const h = s.head;
    if (/^Exercise/i.test(h)) lesson.exercises.push(parseExercise(h, s.lines, lesson.exercises.length, lesson.id));
    else if (/^Cards?$/i.test(h)) lesson.cards = parseCards(s.lines, lesson.id, lesson.concepts[0] || lesson.id);
    else if (/^Learn|^Scenario|^Briefing/i.test(h)) lesson.learn = s.lines.join("\n").trim();
    else if (/^Desk/i.test(h)) lesson.desk = s.lines.join("\n").trim();
    else if (/^Next/i.test(h)) lesson.next = s.lines.join("\n").trim();
    else if (/^Brief/i.test(h)) project.brief = s.lines.join("\n").trim();
    else if (/^Acceptance/i.test(h)) project.acceptance = s.lines.join("\n").trim();
    else if (/^Interview/i.test(h)) project.interview = s.lines.join("\n").trim();
    else if (/^CV/i.test(h)) project.cvBullet = s.lines.join("\n").trim();
  }
  if (Object.keys(project).length) lesson.project = project;
  return lesson;
}

function normaliseLesson(o) {
  return { type: "lesson", minutes: 15, xp: 50, concepts: [], objectives: [], status: "ready",
    timeLimit: null, passMark: 0.8, datasets: [], learn: "", desk: "", next: "",
    exercises: [], cards: [], project: null, ...o };
}

// ---------------------------------------------------------------- markdown -> HTML
export function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

function inline(s) {
  // code spans first so their contents are not formatted
  const codes = [];
  s = s.replace(/`([^`]+)`/g, (_, c) => `\u0000${codes.push(c) - 1}\u0000`);
  s = esc(s)
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/(^|[^*])\*([^*\s][^*]*)\*/g, "$1<em>$2</em>")
    .replace(/\[([^\]]+)\]\(([^)\s]+)\)/g, (_, t, u) =>
      /^(https?:|#|\.\/|\/)/.test(u) ? `<a href="${u}" target="${u.startsWith("#") ? "_self" : "_blank"}" rel="noopener">${t}</a>` : t);
  return s.replace(/\u0000(\d+)\u0000/g, (_, i) => `<code>${esc(codes[i])}</code>`);
}

export function renderMarkdown(md) {
  const lines = String(md || "").replace(/\r\n?/g, "\n").split("\n");
  const html = [];
  let i = 0;
  let exampleN = 0;
  while (i < lines.length) {
    const line = lines[i];
    const fence = line.match(/^\s*```\s*(\w+)?\s*(\w+)?/);
    if (fence) {
      const body = [];
      i++;
      while (i < lines.length && !/^\s*```\s*$/.test(lines[i])) body.push(lines[i++]);
      i++;
      const code = body.join("\n");
      if (fence[2] === "example") {
        html.push(`<div class="example" data-example="${exampleN++}"><pre><code class="lang-python">${esc(code)}</code></pre>` +
          `<div class="example-bar"><button class="btn small" data-act="run-example">Run example</button>` +
          `<button class="btn small ghost" data-act="copy-example">Copy to editor</button></div><div class="example-out"></div></div>`);
      } else html.push(`<pre><code>${esc(code)}</code></pre>`);
      continue;
    }
    if (/^\s*$/.test(line)) { i++; continue; }
    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) { const n = Math.min(h[1].length + 2, 6); html.push(`<h${n}>${inline(h[2])}</h${n}>`); i++; continue; }
    if (/^\s*(---|\*\*\*)\s*$/.test(line)) { html.push("<hr>"); i++; continue; }
    if (/^\s*\|/.test(line)) {
      const rows = [];
      while (i < lines.length && /^\s*\|/.test(lines[i])) rows.push(lines[i++]);
      const cells = (r) => r.trim().replace(/^\||\|$/g, "").split("|").map((c) => c.trim());
      const head = cells(rows[0]);
      const bodyRows = rows.slice(/^\s*\|[\s:|-]+\|\s*$/.test(rows[1] || "") ? 2 : 1);
      html.push(`<div class="table-wrap"><table><thead><tr>${head.map((c) => `<th>${inline(c)}</th>`).join("")}</tr></thead><tbody>` +
        bodyRows.map((r) => `<tr>${cells(r).map((c) => `<td>${inline(c)}</td>`).join("")}</tr>`).join("") + "</tbody></table></div>");
      continue;
    }
    if (/^\s*>/.test(line)) {
      const q = [];
      while (i < lines.length && /^\s*>/.test(lines[i])) q.push(lines[i++].replace(/^\s*>\s?/, ""));
      html.push(`<blockquote>${renderMarkdown(q.join("\n"))}</blockquote>`);
      continue;
    }
    const li = line.match(/^\s*([-*]|\d+\.)\s+(.*)$/);
    if (li) {
      const ordered = /\d/.test(li[1]);
      const items = [];
      while (i < lines.length) {
        const m = lines[i].match(/^\s*([-*]|\d+\.)\s+(.*)$/);
        if (m) { items.push(m[2]); i++; }
        else if (/^\s{2,}\S/.test(lines[i]) && items.length) { items[items.length - 1] += " " + lines[i].trim(); i++; }
        else break;
      }
      const tag = ordered ? "ol" : "ul";
      html.push(`<${tag}>${items.map((t) => `<li>${inline(t)}</li>`).join("")}</${tag}>`);
      continue;
    }
    const para = [];
    while (i < lines.length && !/^\s*$/.test(lines[i]) && !/^(#{1,4}\s|\s*```|\s*\||\s*>|\s*([-*]|\d+\.)\s)/.test(lines[i])) para.push(lines[i++]);
    html.push(`<p>${inline(para.join(" "))}</p>`);
  }
  return html.join("\n");
}

// Pull the code of the n-th example block (used by "Copy to editor" / "Run example").
export function exampleCode(md, n) {
  const re = /```\s*python\s+example[^\n]*\n([\s\S]*?)\n\s*```/g;
  let m, k = 0;
  while ((m = re.exec(md))) { if (k++ === n) return m[1]; }
  return "";
}
