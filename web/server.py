"""Sample page backend: serves the tasks in this repository as JSON plus a static frontend.

Standard library only (Python 3.11+ for tomllib).

    python3 web/server.py --port 8000
    GET /api/tasks          list of tasks (id, title, kind, difficulty, category, agent result)
    GET /api/tasks/<id>     one task with statement, difficulty note, validation and agent run
"""
import argparse
import json
import os
import re
import tomllib
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

ROOT = Path(os.environ.get("REPO_ROOT", Path(__file__).resolve().parent.parent))
TASKS = ROOT / "tasks"
TRAJ = ROOT / "trajectories"
STATIC = Path(__file__).resolve().parent / "static"
RESULTS = Path(__file__).resolve().parent / "results.json"
SLUG = re.compile(r"^[a-z0-9][a-z0-9-]*$")


def _title(instruction: str, fallback: str) -> str:
    for line in instruction.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return fallback


def _agent_run(slug: str):
    d = TRAJ / slug
    if not d.is_dir():
        return None
    run = {"reward": None, "tool_calls": None, "summary": None}
    grading = d / "grading.txt"
    if grading.exists():
        text = grading.read_text(errors="replace")
        m = re.search(r"^reward:\s*([0-9.]+)", text, re.M)
        run["reward"] = float(m.group(1)) if m else None
        tail = [l for l in text.splitlines() if re.search(r"\d+ (passed|failed)", l)]
        run["summary"] = tail[-1].strip(" =") if tail else None
    traj = d / "trajectory.md"
    if traj.exists():
        m = re.search(r"^Tool calls:\s*(\d+)", traj.read_text(errors="replace"), re.M)
        run["tool_calls"] = int(m.group(1)) if m else None
    return run


def load_task(slug: str):
    if not SLUG.match(slug):
        return None
    tdir = TASKS / slug
    if not (tdir / "task.toml").is_file():
        return None
    meta = tomllib.loads((tdir / "task.toml").read_text())
    md = meta.get("metadata", {})
    instruction = (tdir / "instruction.md").read_text()
    extra = json.loads(RESULTS.read_text()).get(slug, {}) if RESULTS.exists() else {}
    return {
        "id": slug,
        "title": extra.get("title") or _title(instruction, slug),
        "kind": extra.get("kind"),
        "category": md.get("category"),
        "tags": md.get("tags", []),
        "difficulty": md.get("difficulty"),
        "difficulty_explanation": (md.get("difficulty_explanation") or "").strip(),
        "verification_explanation": (md.get("verification_explanation") or "").strip(),
        "agent_timeout_sec": meta.get("agent", {}).get("timeout_sec"),
        "statement": instruction,
        "validation": extra.get("validation", []),
        "hidden_suite": extra.get("hidden_suite"),
        "agent_run": _agent_run(slug),
    }


def list_tasks():
    out = []
    for tdir in sorted(p for p in TASKS.iterdir() if p.is_dir()):
        t = load_task(tdir.name)
        if t:
            out.append({k: t[k] for k in ("id", "title", "kind", "category", "difficulty",
                                          "hidden_suite", "agent_run")})
    return out


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=str(STATIC), **kw)

    def _json(self, code, obj):
        body = json.dumps(obj, indent=2).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = self.path.split("?", 1)[0].rstrip("/")
        if path == "/api/tasks":
            return self._json(200, list_tasks())
        if path.startswith("/api/tasks/"):
            t = load_task(path[len("/api/tasks/"):])
            return self._json(200, t) if t else self._json(404, {"error": "task not found"})
        if path.startswith("/api"):
            return self._json(404, {"error": "not found"})
        return super().do_GET()

    def log_message(self, fmt, *args):
        pass


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--port", type=int, default=8000)
    a = ap.parse_args()
    print(f"serving http://{a.host}:{a.port}")
    HTTPServer((a.host, a.port), Handler).serve_forever()


if __name__ == "__main__":
    main()
