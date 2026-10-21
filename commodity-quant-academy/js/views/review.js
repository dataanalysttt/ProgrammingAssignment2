// review.js: spaced-repetition review session, 5-minute mode and market-event pop-ups.
import { get, save } from "../store.js";
import { award, markActive, XP, maybeMarketEvent, loadEvents } from "../gamify.js";
import { reviewQueue, review } from "../srs.js";
import { loadLesson, lookup, nextStep } from "../content.js";
import { renderMarkdown } from "../mdparse.js";
import { esc, modal, toast } from "../ui.js";
import { mountExercise } from "./exercise.js";
import { refreshHeader } from "../main.js";

async function cardContent(card) {
  if (!lookup(card.lessonId)) return null;
  const lesson = await loadLesson(card.lessonId).catch(() => null);
  return lesson?.cards.find((c) => c.id === card.id) || null;
}

const GRADES = [
  { q: 1, label: "Again", hint: "wrong or blank" },
  { q: 3, label: "Hard", hint: "right, with effort" },
  { q: 4, label: "Good", hint: "right" },
  { q: 5, label: "Easy", hint: "instant" },
];

// Show one card; resolves with the SM-2 quality the learner earned.
function showCard(host, card, content) {
  return new Promise(async (resolve) => {
    const levelN = card.level?.split("-")[1];
    host.innerHTML = `<div class="card review-item">
      <div class="eyebrow">L${esc(levelN)} · ${esc(card.concept)} · ${content.kind === "code" ? "write the code" : "recall"}</div>
      <div class="q">${renderMarkdown(content.q)}</div><div class="slot"></div><div class="grade" hidden></div></div>`;
    const slot = host.querySelector(".slot");
    const gradeEl = host.querySelector(".grade");
    const grades = (allowed) => {
      gradeEl.hidden = false;
      gradeEl.innerHTML = `<div class="small muted">How did that go?</div><div class="seg grades">${GRADES.filter((g) => allowed.includes(g.q))
        .map((g) => `<button class="btn ${g.q === 1 ? "ghost" : ""}" data-q="${g.q}">${g.label}<span>${g.hint}</span></button>`).join("")}</div>`;
      gradeEl.querySelectorAll("[data-q]").forEach((b) => (b.onclick = () => resolve(Number(b.dataset.q))));
    };
    if (content.kind === "code") {
      const ex = { id: `${card.id}@review`, prompt: "", starter: content.starter || "", solution: content.solution || "", tests: content.tests, setup: content.setup || "", hints: [] };
      delete get().drafts[ex.id]; // retrieval: start from the starter every time
      let gaveUp = false;
      await mountExercise(slot, ex, { lessonId: "review", hints: false, confidence: false,
        onPass: () => !gaveUp && grades([3, 4, 5]) });
      const give = document.createElement("button");
      give.className = "btn ghost small";
      give.textContent = "I can't recall: show the answer";
      give.onclick = () => {
        gaveUp = true;
        give.outerHTML = `<pre class="answer"><code>${esc(content.solution || content.a || "(no model answer)")}</code></pre>`;
        grades([1]);
      };
      slot.appendChild(give);
    } else {
      slot.innerHTML = `<textarea class="recall" rows="3" placeholder="Type your answer from memory before checking." autocapitalize="off" spellcheck="false"></textarea>
        <div class="row"><button class="btn primary" data-act="check">Check</button><button class="btn ghost" data-act="dunno">I don't know</button></div>`;
      const ta = slot.querySelector("textarea");
      ta.focus();
      const reveal = (blank) => {
        slot.innerHTML = `${blank ? "" : `<div class="yours"><div class="eyebrow">Your answer</div><pre>${esc(ta.value)}</pre></div>`}
          <div class="model"><div class="eyebrow">Model answer</div>${renderMarkdown(content.a)}</div>`;
        grades(blank ? [1] : [1, 3, 4, 5]);
      };
      slot.querySelector("[data-act='check']").onclick = () => (ta.value.trim() ? reveal(false) : toast("Write something first: retrieving it is the point.", "info"));
      slot.querySelector("[data-act='dunno']").onclick = () => reveal(true);
      ta.addEventListener("keydown", (e) => { if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) slot.querySelector("[data-act='check']")?.click(); });
    }
  });
}

export async function renderReview(el) {
  const queue = reviewQueue(25);
  if (!queue.length) {
    el.innerHTML = `<div class="card"><h1>Review queue</h1><p>Nothing is due right now. Cards come back on their SM-2 schedule.</p><a class="btn" href="#/home">Home</a></div>`;
    return;
  }
  el.innerHTML = `<div class="review-head"><h1>Review</h1><div class="progress small"><span class="n">1</span>/${queue.length} · interleaved across levels</div>
    <div class="bar thin"><div style="width:0"></div></div></div><div class="stage"></div>`;
  const stage = el.querySelector(".stage");
  let correct = 0, done = 0;
  for (const [i, card] of queue.entries()) {
    el.querySelector(".n").textContent = i + 1;
    el.querySelector(".bar div").style.width = `${(i / queue.length) * 100}%`;
    const content = await cardContent(card);
    if (!content) continue; // card's lesson was edited or removed
    const q = await showCard(stage, card, content);
    review(card.id, q);
    done++;
    if (q >= 3) correct++;
    award(XP.review, "review");
    refreshHeader();
    if (!document.body.contains(stage)) return; // navigated away mid-session
  }
  const step = nextStep();
  stage.innerHTML = `<div class="card done-card"><div class="eyebrow">Review done</div>
    <div class="big-num">${correct}/${done}<span> recalled</span></div>
    <p class="muted">Missed cards come back tomorrow; recalled ones move further out.</p>
    ${step ? `<p class="teaser"><strong>Up next:</strong> ${esc(step.entry.title)}</p>` : ""}
    <div class="row">${step ? `<a class="btn primary" href="#/lesson/${step.entry.id}">Continue learning</a>` : ""}<a class="btn ghost" href="#/home">Home</a></div></div>`;
  const ev = await maybeMarketEvent("review");
  if (ev) openEvent(ev, award, XP);
}

// ---------------------------------------------------------------- 5-minute mode
export async function renderQuick(el) {
  const s = get();
  el.innerHTML = `<div class="review-head"><h1>5-minute mode</h1><p class="muted small">One review, one micro-exercise. Showing up is the win.</p></div><div class="stage"></div>`;
  const stage = el.querySelector(".stage");
  const cards = Object.values(s.cards).sort((a, b) => a.due.localeCompare(b.due));
  const pick = cards.find((c) => c.kind === "recall") || cards[0];
  if (pick) {
    const content = await cardContent(pick);
    if (content) { const q = await showCard(stage, pick, content); review(pick.id, q); }
  }
  if (!document.body.contains(stage)) return;
  const { micro } = await loadEvents();
  const learned = new Set(Object.values(s.cards).map((c) => c.concept));
  const pool = micro.filter((m) => !m.concept || learned.has(m.concept) || (m.minLevel ?? 0) === 0);
  const mx = pool[Math.floor(Math.random() * pool.length)] || micro[0];
  stage.innerHTML = `<div class="card"><div class="eyebrow">Micro-exercise · ${esc(mx.title)}</div><div class="mx"></div></div><div class="end"></div>`;
  const ex = { id: `micro.${mx.id}`, prompt: mx.prompt, starter: mx.starter || "", solution: mx.solution || "", tests: mx.tests, setup: mx.setup || "", hints: mx.hints || [] };
  delete s.drafts[ex.id];
  await mountExercise(stage.querySelector(".mx"), ex, {
    lessonId: "micro", confidence: false,
    onPass: () => {
      award(XP.quick, "5-minute session");
      markActive();
      refreshHeader();
      const step = nextStep();
      stage.querySelector(".end").innerHTML = `<div class="card done-card"><div class="eyebrow">Session counted</div><p>That's today done. If you have more in you, keep going. If not, stop here.</p>
        ${step ? `<p class="teaser"><strong>Waiting for you:</strong> ${esc(step.entry.title)}</p>` : ""}
        <div class="row">${step ? `<a class="btn" href="#/lesson/${step.entry.id}">Keep going</a>` : ""}<a class="btn primary" href="#/home">Done for today</a></div></div>`;
    },
  });
  save();
}

// ---------------------------------------------------------------- market events
export function openEvent(ev, awardFn = award, xpTable = XP) {
  const m = modal(`<div class="event"><div class="eyebrow">Market event</div><h2>${esc(ev.title)}</h2>${renderMarkdown(ev.text)}
    ${ev.kind === "bonus" ? `<div class="row end"><button class="btn primary" data-act="collect">Collect +${ev.xp || xpTable.event} XP</button></div>`
      : `<div class="ev-ex"></div><p class="muted small">Optional. Close this any time: it never blocks your progress.</p>`}</div>`, { wide: ev.kind !== "bonus" });
  if (ev.kind === "bonus") {
    m.root.querySelector("[data-act='collect']").onclick = () => { awardFn(ev.xp || xpTable.event, "market event"); refreshHeader(); m.close(); };
  } else {
    const ex = { id: `event.${ev.id}`, prompt: ev.prompt, starter: ev.starter || "", solution: ev.solution || "", tests: ev.tests || [], setup: ev.setup || "", hints: ev.hints || [] };
    mountExercise(m.root.querySelector(".ev-ex"), ex, { lessonId: "events", confidence: false, datasets: ev.datasets,
      onPass: () => { awardFn(ev.xp || xpTable.event, "market event"); refreshHeader(); toast("Event cleared.", "xp"); } });
  }
}
