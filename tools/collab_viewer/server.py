"""Claude ↔ Codex yazışma izleme ekranı — yerel sunucu.

Yazışma dosyalarını (collab/threads/) iki tarafın oturum kayıtlarıyla
birleştirir: mesajlar + arka planda okunan dosyalar, aramalar, komutlar,
web aramaları. Yalnız 127.0.0.1'de dinler; hiçbir şey yazmaz.

    tools/collab.sh ui            # http://127.0.0.1:8765 açılır
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
import webbrowser
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HOME = Path.home()
CODEX_SESSIONS = HOME / ".codex" / "sessions"
CLAUDE_PROJECTS = HOME / ".claude" / "projects"
HERE = Path(__file__).resolve().parent
REPO = HERE.parent.parent

SLUG_RE = re.compile(r"^[a-z0-9-]+$")
HEADER_RE = re.compile(r"^### (Claude|Codex) → (Claude|Codex) · (\d{4}-\d{2}-\d{2} \d{2}:\d{2})\s*$")
STATUS_RE = re.compile(r"^> _(.+) · (\d{4}-\d{2}-\d{2} \d{2}:\d{2})_\s*$")


# ---------------------------------------------------------------- yardımcılar

def ts(value: str) -> float:
    """ISO zaman damgası → epoch saniye (Z ve ofset desteklenir)."""
    return datetime.fromisoformat(value.replace("Z", "+00:00")).timestamp()


def local_minute(value: str) -> float:
    return datetime.strptime(value, "%Y-%m-%d %H:%M").timestamp()


def short_path(p: str) -> str:
    p = p.replace("file://", "")
    for base in (str(REPO) + "/", str(HOME) + "/"):
        if p.startswith(base):
            return p[len(base):] if base != str(HOME) + "/" else "~/" + p[len(base):]
    return p


_cache: dict[str, tuple[tuple[float, int], object]] = {}


def cached(path: Path, parse):
    """Dosya değişmediyse önceki ayrıştırmayı döndür."""
    try:
        st = path.stat()
    except FileNotFoundError:
        return None
    key = (st.st_mtime, st.st_size)
    hit = _cache.get(str(path))
    if hit and hit[0] == key:
        return hit[1]
    value = parse(path)
    _cache[str(path)] = (key, value)
    return value


def jsonl(path: Path):
    with open(path, encoding="utf-8") as fh:
        for line in fh:
            try:
                yield json.loads(line)
            except ValueError:
                continue


# ------------------------------------------------------- Codex oturum kaydı

def find_codex_session(sid: str) -> Path | None:
    hits = glob.glob(str(CODEX_SESSIONS / "**" / f"*{sid}.jsonl"), recursive=True)
    return Path(hits[0]) if hits else None


def parse_codex(path: Path) -> list[dict]:
    out: list[dict] = []
    for e in jsonl(path):
        p = e.get("payload") or {}
        if p.get("type") != "item_completed":
            continue
        item = p.get("item") or {}
        t = ts(e["timestamp"])
        kind = item.get("type")
        if kind == "CommandExecution":
            cmd = item.get("command") or []
            raw = cmd[-1] if cmd else ""
            parsed = item.get("parsed_cmd") or [{"type": "unknown", "cmd": raw}]
            for pc in parsed:
                pt = pc.get("type")
                if pt == "read":
                    out.append(act(t, "Codex", "read", short_path(pc.get("path") or pc.get("name") or ""), raw))
                elif pt == "search":
                    q = pc.get("query") or ""
                    where = short_path(pc.get("path") or "") if pc.get("path") else ""
                    out.append(act(t, "Codex", "search", f"“{q}”" + (f" · {where}" if where else ""), raw))
                elif pt == "list_files":
                    out.append(act(t, "Codex", "list", short_path(pc.get("path") or "."), raw))
                else:
                    out.append(act(t, "Codex", "command", pc.get("cmd") or raw, raw))
        elif kind == "Extension":
            if item.get("kind") == "web.search":
                urls = [r.get("url") for r in (item.get("results") or []) if r.get("url")][:6]
                out.append(act(t, "Codex", "web", item.get("query") or "", "", urls))
            elif item.get("kind", "").startswith("web."):
                a = item.get("action") or {}
                out.append(act(t, "Codex", "web", a.get("url") or item.get("kind"), ""))
        elif kind == "AgentMessage" and item.get("phase") == "commentary":
            text = " ".join(c.get("text", "") for c in item.get("content") or [])
            if text.strip():
                out.append(act(t, "Codex", "note", text.strip(), ""))
    return out


# ------------------------------------------------------ Claude oturum kaydı

def find_claude_session(sid: str) -> Path | None:
    hits = glob.glob(str(CLAUDE_PROJECTS / "*" / f"{sid}.jsonl"))
    return Path(hits[0]) if hits else None


def parse_claude(path: Path) -> list[dict]:
    out: list[dict] = []
    for e in jsonl(path):
        if e.get("type") != "assistant" or e.get("isSidechain"):
            continue
        content = (e.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        t = ts(e["timestamp"])
        for b in content:
            if not isinstance(b, dict) or b.get("type") != "tool_use":
                continue
            item = claude_tool(t, b.get("name") or "", b.get("input") or {})
            if item:
                out.append(item)
    return out


def claude_tool(t: float, name: str, inp: dict) -> dict | None:
    if name == "Read":
        return act(t, "Claude", "read", short_path(inp.get("file_path", "")), "")
    if name == "Grep":
        where = short_path(inp.get("path", "")) if inp.get("path") else ""
        return act(t, "Claude", "search", f"“{inp.get('pattern', '')}”" + (f" · {where}" if where else ""), "")
    if name == "Glob":
        return act(t, "Claude", "list", inp.get("pattern", ""), "")
    if name == "Bash":
        cmd = inp.get("command", "")
        if re.search(r"collab\.sh (codex|claude|new) ", cmd):
            return None  # mesajın kendisi; zaman çizelgesinde zaten var
        return act(t, "Claude", "command", inp.get("description") or cmd.splitlines()[0], cmd)
    if name == "WebSearch":
        return act(t, "Claude", "web", inp.get("query", ""), "")
    if name == "WebFetch":
        return act(t, "Claude", "web", inp.get("url", ""), inp.get("prompt", ""), [inp.get("url", "")])
    if name in ("Edit", "Write", "NotebookEdit"):
        return act(t, "Claude", "write", short_path(inp.get("file_path", "")), "")
    if name == "Agent":
        return act(t, "Claude", "agent", inp.get("description", ""), "")
    if name in ("ToolSearch",):
        return None
    return act(t, "Claude", "tool", name, "")


def act(t: float, who: str, kind: str, target: str, detail: str, urls: list[str] | None = None) -> dict:
    return {"t": t, "who": who, "kind": kind, "target": target, "detail": detail[:600], "urls": urls or []}


# ------------------------------------------------------------- yazışmalar

def read_events(slug: str, threads: Path) -> list[dict]:
    path = threads / f".{slug}.events.jsonl"
    if path.exists():
        evs = list(jsonl(path))
        for e in evs:
            e["t"] = ts(e["ts"])
        return evs
    return md_events(threads / f"{slug}.md")


def md_events(path: Path) -> list[dict]:
    """Eski yazışmalar (olay kaydı yoksa): .md başlıklarından dakika hassasiyeti."""
    evs: list[dict] = []
    cur: dict | None = None
    body: list[str] = []

    def close():
        if cur is not None:
            cur["text"] = "\n".join(body).strip()
            evs.append(cur)

    for line in path.read_text(encoding="utf-8").splitlines():
        m = HEADER_RE.match(line)
        s = STATUS_RE.match(line)
        if m:
            close()
            cur = {"kind": "message", "from": m[1], "to": m[2], "t": local_minute(m[3]), "approx": True}
            body = []
        elif s:
            close()
            cur = None
            evs.append({"kind": "status", "text": s[1], "t": local_minute(s[2]), "approx": True})
        elif cur is not None:
            body.append(line)
    close()
    return evs


def thread_title(path: Path) -> str:
    first = path.read_text(encoding="utf-8").splitlines()[:1]
    return first[0].lstrip("# ").strip() if first else path.stem


def sessions_for(slug: str, threads: Path, events: list[dict]) -> list[tuple[str, str, str]]:
    """(taraf, rol, oturum kimliği) listesi."""
    found: list[tuple[str, str, str]] = []
    for who, fname in (("Codex", f".{slug}.codex-session"), ("Claude", f".{slug}.claude-session")):
        p = threads / fname
        if p.exists() and p.read_text().strip():
            found.append((who, "responder", p.read_text().strip()))
    for e in events:
        if e.get("kind") == "message" and e.get("caller_session"):
            found.append((e["from"], "caller", e["caller_session"]))
    seen, uniq = set(), []
    for f in found:
        if f[2] not in seen:
            seen.add(f[2])
            uniq.append(f)
    return uniq


def activity_for(who: str, sid: str) -> list[dict]:
    if who == "Codex":
        p = find_codex_session(sid)
        return (cached(p, parse_codex) or []) if p else []
    p = find_claude_session(sid)
    return (cached(p, parse_claude) or []) if p else []


def build_thread(slug: str, threads: Path) -> dict:
    md = threads / f"{slug}.md"
    events = read_events(slug, threads)
    events.sort(key=lambda e: e["t"])
    msgs = [e for e in events if e.get("kind") == "message"]
    running = (threads / f".{slug}.lock").exists()
    start = events[0]["t"] if events else md.stat().st_mtime
    # Dakika hassasiyetli eski kayıtlar için pencereyi bir dakika genişlet.
    if events and events[0].get("approx"):
        start -= 60
    last = msgs[-1]["t"] if msgs else start
    waiting_on = msgs[-1]["to"] if running and msgs else None

    sessions = sessions_for(slug, threads, events)
    acts: list[dict] = []
    for who, role, sid in sessions:
        for a in activity_for(who, sid):
            if a["t"] < start:
                continue
            # Son mesajdan sonrası: yalnız şu an cevap yazan tarafın canlı işi.
            if a["t"] > last + (60 if msgs and msgs[-1].get("approx") else 1):
                if not (running and who == waiting_on):
                    continue
            acts.append({**a, "role": role})
    acts.sort(key=lambda a: a["t"])

    timeline: list[dict] = []
    ai = 0
    for e in events:
        if e.get("kind") == "created":
            continue
        gap = []
        while ai < len(acts) and acts[ai]["t"] <= e["t"]:
            gap.append(acts[ai])
            ai += 1
        if gap:
            timeline.append({"type": "activity", "items": gap})
        if e.get("kind") == "message":
            timeline.append({"type": "message", "from": e["from"], "to": e["to"], "t": e["t"],
                             "text": e.get("text", ""), "approx": bool(e.get("approx"))})
        elif e.get("kind") == "status":
            timeline.append({"type": "status", "t": e["t"], "text": e.get("text", "")})
    if ai < len(acts):
        timeline.append({"type": "activity", "items": acts[ai:], "live": running})

    return {
        "slug": slug,
        "title": thread_title(md),
        "running": running,
        "waiting_on": waiting_on,
        "sessions": [{"who": w, "role": r, "id": s} for w, r, s in sessions],
        "timeline": timeline,
        "counts": {"messages": len(msgs), "activity": len(acts)},
    }


def list_threads(threads: Path) -> list[dict]:
    out = []
    for md in threads.glob("*.md"):
        slug = md.stem
        if not SLUG_RE.match(slug):
            continue
        ev = threads / f".{slug}.events.jsonl"
        updated = max(md.stat().st_mtime, ev.stat().st_mtime if ev.exists() else 0)
        out.append({
            "slug": slug,
            "title": thread_title(md),
            "updated": updated,
            "running": (threads / f".{slug}.lock").exists(),
            "turns": sum(1 for line in md.read_text(encoding="utf-8").splitlines() if HEADER_RE.match(line)),
        })
    out.sort(key=lambda x: x["updated"], reverse=True)
    return out


# -------------------------------------------------------------------- sunucu

def make_handler(threads: Path):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):  # sessiz
            pass

        def send(self, code: int, body: bytes, ctype: str):
            self.send_response(code)
            self.send_header("Content-Type", ctype)
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def json(self, value):
            self.send(200, json.dumps(value, ensure_ascii=False).encode(), "application/json; charset=utf-8")

        def do_GET(self):
            path = self.path.split("?")[0]
            try:
                if path in ("/", "/index.html"):
                    self.send(200, (HERE / "index.html").read_bytes(), "text/html; charset=utf-8")
                elif path == "/api/threads":
                    self.json(list_threads(threads))
                elif path.startswith("/api/thread/"):
                    slug = path.rsplit("/", 1)[-1]
                    if not SLUG_RE.match(slug) or not (threads / f"{slug}.md").exists():
                        self.send(404, b"{}", "application/json")
                    else:
                        self.json(build_thread(slug, threads))
                else:
                    self.send(404, b"not found", "text/plain")
            except Exception as exc:  # ekran çökmesin; hatayı göster
                self.send(500, json.dumps({"error": str(exc)}).encode(), "application/json")

    return Handler


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--threads", required=True)
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--no-open", action="store_true")
    args = ap.parse_args()
    threads = Path(args.threads)
    srv = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(threads))
    url = f"http://127.0.0.1:{args.port}"
    print(f"İzleme ekranı: {url}  (Ctrl+C ile kapat)", flush=True)
    if not args.no_open:
        webbrowser.open(url)
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    sys.exit(main())
