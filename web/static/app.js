// Sample page frontend: task list (#/) and task detail (#/task/<id>). No dependencies.
const app = document.getElementById("app");

function esc(s) {
  return String(s ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
}

// Minimal Markdown: fenced code, headings, lists, inline code, bold, paragraphs.
function md(src) {
  const out = [];
  const lines = String(src).split("\n");
  let i = 0, para = [], list = null;
  const inline = t => esc(t).replace(/`([^`]+)`/g, "<code>$1</code>").replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
  const flushPara = () => { if (para.length) { out.push("<p>" + inline(para.join(" ")) + "</p>"); para = []; } };
  const flushList = () => { if (list) { out.push("<" + list.tag + ">" + list.items.map(x => "<li>" + inline(x) + "</li>").join("") + "</" + list.tag + ">"); list = null; } };
  while (i < lines.length) {
    const line = lines[i];
    if (line.startsWith("```")) {
      flushPara(); flushList();
      const buf = []; i++;
      while (i < lines.length && !lines[i].startsWith("```")) buf.push(lines[i++]);
      out.push("<pre><code>" + esc(buf.join("\n")) + "</code></pre>"); i++; continue;
    }
    if (!list && /^ {4}\S/.test(line)) {
      flushPara();
      const buf = [];
      while (i < lines.length && (/^ {4}/.test(lines[i]) || (!lines[i].trim() && /^ {4}\S/.test(lines[i + 1] || "")))) buf.push(lines[i++].slice(4));
      out.push("<pre><code>" + esc(buf.join("\n")) + "</code></pre>"); continue;
    }
    const h = line.match(/^(#{1,4})\s+(.*)$/);
    if (h) { flushPara(); flushList(); out.push(`<h${h[1].length}>${inline(h[2])}</h${h[1].length}>`); i++; continue; }
    const li = line.match(/^\s*(?:[-*]|(\d+)\.)\s+(.*)$/);
    if (li) {
      flushPara();
      const tag = li[1] ? "ol" : "ul";
      if (!list || list.tag !== tag) { flushList(); list = { tag, items: [] }; }
      list.items.push(li[2]); i++; continue;
    }
    if (!line.trim()) { flushPara(); flushList(); i++; continue; }
    if (list && /^\s{2,}\S/.test(line)) { list.items[list.items.length - 1] += " " + line.trim(); i++; continue; }
    flushList(); para.push(line.trim()); i++;
  }
  flushPara(); flushList();
  return out.join("\n");
}

function reward(run) {
  if (!run || run.reward === null) return '<span class="pill">no agent run</span>';
  const cls = run.reward >= 1 ? "ok" : "bad";
  return `<span class="pill ${cls}">agent reward ${run.reward}</span>` +
         (run.tool_calls ? `<span class="pill">${run.tool_calls} tool calls</span>` : "");
}

async function getJSON(url) {
  const r = await fetch(url);
  if (!r.ok) throw new Error((await r.json()).error || r.statusText);
  return r.json();
}

async function showList() {
  const tasks = await getJSON("/api/tasks");
  app.innerHTML = tasks.map(t => `
    <a class="card" href="#/task/${esc(t.id)}">
      <h2>${esc(t.title)}</h2>
      <div class="muted">${esc(t.id)}</div>
      <div class="row">
        <span class="pill">${esc(t.kind)}</span>
        <span class="pill">difficulty: ${esc(t.difficulty)}</span>
        <span class="pill">${esc(t.hidden_suite)}</span>
        ${reward(t.agent_run)}
      </div>
    </a>`).join("");
}

async function showTask(id) {
  const t = await getJSON("/api/tasks/" + encodeURIComponent(id));
  const v = t.validation.map(r => `<tr><td>${esc(r.run)}</td><td class="${r.reward >= 1 ? "ok" : "bad"}">${esc(r.reward)}</td><td>${esc(r.detail)}</td></tr>`).join("");
  const run = t.agent_run;
  app.innerHTML = `
    <a class="back" href="#/">&larr; All tasks</a>
    <div class="card">
      <h2>${esc(t.title)}</h2>
      <div class="row">
        <span class="pill">${esc(t.kind)}</span>
        <span class="pill">difficulty: ${esc(t.difficulty)}</span>
        <span class="pill">category: ${esc(t.category)}</span>
        <span class="pill">agent timeout ${esc(Math.round((t.agent_timeout_sec || 0) / 60))} min</span>
      </div>
    </div>
    <div class="card"><h3>Difficulty note</h3><div class="note">${esc(t.difficulty_explanation)}</div></div>
    <div class="card"><h3>Validation (real Docker runs)</h3>
      <div class="tablewrap"><table><tr><th>Run</th><th>Reward</th><th>Detail</th></tr>${v}</table></div></div>
    <div class="card"><h3>Agent result</h3>
      ${run ? `<p>${reward(run)}</p><p class="muted">${esc(run.summary || "")}</p>
      <p class="muted">Full run: <code>trajectories/${esc(t.id)}/trajectory.md</code></p>` : "<p class='muted'>No agent run recorded.</p>"}
    </div>
    <div class="card statement"><h3>Statement (what the agent sees)</h3>${md(t.statement)}</div>
    <div class="card"><h3>How it is graded</h3><div class="note">${esc(t.verification_explanation)}</div></div>`;
}

async function route() {
  const m = location.hash.match(/^#\/task\/([a-z0-9-]+)$/);
  try { m ? await showTask(m[1]) : await showList(); }
  catch (e) { app.innerHTML = `<p class="bad">Error: ${esc(e.message)}</p>`; }
  window.scrollTo(0, 0);
}
window.addEventListener("hashchange", route);
route();
