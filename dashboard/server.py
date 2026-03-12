#!/usr/bin/env python3
"""Muster Dashboard — local web UI for monitoring agents."""

import json
import os
import subprocess
import sys
from datetime import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# Find comms root by walking up
def find_comms_root(start=None):
    d = Path(start or os.getcwd())
    while d != d.parent:
        if (d / "comms" / "team.json").exists():
            return d
        d = d.parent
    return None

_root = find_comms_root()
if not _root:
    print("No muster project found. Run 'muster init' first.")
    sys.exit(1)

ROOT: Path = _root
COMMS = ROOT / "comms"
TEAM_JSON = COMMS / "team.json"


def load_team():
    with open(TEAM_JSON) as f:
        return json.load(f)


def count_md(directory):
    d = Path(directory)
    if not d.is_dir():
        return 0
    return len(list(d.glob("*.md")))


def list_md(directory):
    d = Path(directory)
    if not d.is_dir():
        return []
    files = sorted(d.glob("*.md"), key=lambda f: f.stat().st_mtime, reverse=True)
    result = []
    for f in files:
        try:
            content = f.read_text(errors="replace")[:2000]
        except:
            content = ""
        result.append({
            "name": f.name,
            "content": content,
            "modified": datetime.fromtimestamp(f.stat().st_mtime).isoformat(),
        })
    return result


import re

_ANSI_RE = re.compile(r'\x1b\[[0-9;]*[a-zA-Z]|\x1b\].*?\x07')

def _classify_pane_line(line):
    """Try to classify a raw pane line into a human-readable status."""
    line = _ANSI_RE.sub('', line).strip()
    if not line:
        return None
    low = line.lower()
    # Common opencode / agent CLI patterns
    if any(k in low for k in ['thinking', 'reasoning']):
        return 'thinking'
    if any(k in low for k in ['writing', 'write ', 'creating']):
        return 'writing'
    if any(k in low for k in ['reading', 'read ']):
        return 'reading'
    if any(k in low for k in ['running', 'executing', 'exec ']):
        return 'running command'
    if any(k in low for k in ['searching', 'grep', 'glob', 'finding']):
        return 'searching'
    if any(k in low for k in ['compiling', 'building', 'build ']):
        return 'building'
    if any(k in low for k in ['testing', 'test ']):
        return 'testing'
    if any(k in low for k in ['commit', 'pushing', 'git ']):
        return 'committing'
    if any(k in low for k in ['idle', 'standing down', 'done', 'board clear']):
        return 'done'
    if any(k in low for k in ['blocked', 'waiting']):
        return 'blocked'
    # Return cleaned line truncated
    return line[:80]


def get_pane_status(agent_name):
    """Capture the last few lines from an agent's tmux pane to infer status."""
    try:
        result = subprocess.run(
            ["tmux", "capture-pane", "-t", f"muster:{agent_name}", "-p"],
            capture_output=True, text=True, timeout=2
        )
        if result.returncode != 0:
            return "offline"
        lines = result.stdout.strip().splitlines()[-10:]
        # Walk from bottom up, find first classifiable line
        for line in reversed(lines):
            status = _classify_pane_line(line)
            if status:
                return status
        return "idle"
    except Exception:
        return "offline"


def get_agent_data(team):
    agents = []
    for agent in team["agents"]:
        name = agent["name"]
        agent_dir = COMMS / name
        agents.append({
            **agent,
            "inbox_count": count_md(agent_dir / "inbox"),
            "active_count": count_md(agent_dir / "active"),
            "archive_count": count_md(agent_dir / "archive"),
            "inbox": list_md(agent_dir / "inbox"),
            "active": list_md(agent_dir / "active"),
            "journal": list_md(agent_dir / "journal")[:3],
            "notes": list_md(agent_dir / "notes"),
            "pane_status": get_pane_status(name),
        })
    return agents


def get_board():
    return list_md(COMMS / "board")


def nudge_agent(name):
    try:
        subprocess.run(
            ["tmux", "send-keys", "-t", f"muster:{name}", "NUDGE: Check your inbox and clean your workspace.", "Enter"],
            capture_output=True, timeout=5
        )
        return True
    except:
        return False


def send_message(to_agent, subject, content, priority="medium"):
    inbox = COMMS / to_agent / "inbox"
    inbox.mkdir(parents=True, exist_ok=True)
    slug = subject.lower().replace(" ", "-")[:40]
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    filename = f"{slug}-{ts}.md"
    msg = f"""**From:** user (dashboard)
**Priority:** {priority}
**Subject:** {subject}

{content}
"""
    (inbox / filename).write_text(msg)
    return filename


class DashboardHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # quiet

    def _json(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def _html(self, content):
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(content.encode())

    def do_GET(self):
        parsed = urlparse(self.path)

        if parsed.path == "/api/status":
            team = load_team()
            agents = get_agent_data(team)
            board = get_board()
            running = subprocess.run(
                ["tmux", "has-session", "-t", "muster"],
                capture_output=True
            ).returncode == 0
            self._json({
                "project": team["project"],
                "user_title": team["user_title"],
                "agent_cli": team["agent_cli"],
                "running": running,
                "agents": agents,
                "board": board,
            })

        elif parsed.path == "/":
            self._html(HTML)

        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
        length = int(self.headers.get("Content-Length", 0))
        body = json.loads(self.rfile.read(length)) if length else {}

        if parsed.path == "/api/nudge":
            name = body.get("agent")
            if name:
                ok = nudge_agent(name)
                self._json({"ok": ok})
            else:
                self._json({"error": "agent required"}, 400)

        elif parsed.path == "/api/message":
            to = body.get("to")
            subject = body.get("subject", "message")
            content = body.get("content", "")
            priority = body.get("priority", "medium")
            if to and content:
                filename = send_message(to, subject, content, priority)
                self._json({"ok": True, "file": filename})
            else:
                self._json({"error": "to and content required"}, 400)

        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()


HTML = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>muster</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    font-family: -apple-system, 'Segoe UI', Roboto, monospace;
    background: #0d1117;
    color: #c9d1d9;
    padding: 24px;
    max-width: 1200px;
    margin: 0 auto;
  }
  h1 { color: #58a6ff; font-size: 1.5em; margin-bottom: 4px; }
  .meta { color: #484f58; font-size: 0.85em; margin-bottom: 24px; }
  .meta .running { color: #3fb950; }
  .meta .stopped { color: #484f58; }

  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
    gap: 16px;
    margin-bottom: 24px;
  }
  .card {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 16px;
    transition: border-color 0.2s;
  }
  .card:hover { border-color: #58a6ff; }
  .card.lead { border-left: 3px solid #d2a8ff; }
  .card.warn { border-left: 3px solid #d29922; }
  .card.danger { border-left: 3px solid #f85149; }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
  }
  .card-name {
    font-weight: bold;
    font-size: 1.1em;
    color: #f0f6fc;
  }
  .card-name .lead-badge {
    font-size: 0.7em;
    color: #d2a8ff;
    margin-left: 8px;
    font-weight: normal;
  }
  .card-character {
    color: #484f58;
    font-size: 0.8em;
    margin-bottom: 8px;
    font-style: italic;
  }
  .card-role {
    color: #8b949e;
    font-size: 0.85em;
    margin-bottom: 12px;
  }
  .card-model {
    color: #484f58;
    font-size: 0.75em;
    margin-bottom: 8px;
  }
  .card-status {
    font-size: 0.8em;
    margin-bottom: 12px;
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    color: #58a6ff;
  }
  .card-status.idle {
    color: #484f58;
    font-style: italic;
  }
  .card-status.offline {
    color: #f85149;
    font-style: italic;
  }

  .counts {
    display: flex;
    gap: 16px;
    margin-bottom: 12px;
    font-size: 0.85em;
  }
  .count-item { display: flex; align-items: center; gap: 4px; }
  .count-num { font-weight: bold; }
  .count-num.zero { color: #3fb950; }
  .count-num.warn { color: #d29922; }
  .count-num.danger { color: #f85149; }

  .card-actions {
    display: flex;
    gap: 8px;
    margin-top: 12px;
  }
  button {
    background: #21262d;
    color: #c9d1d9;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 6px 12px;
    cursor: pointer;
    font-size: 0.8em;
    transition: background 0.2s;
  }
  button:hover { background: #30363d; }
  button.nudge { border-color: #d29922; color: #d29922; }
  button.nudge:hover { background: #d29922; color: #0d1117; }
  button.msg { border-color: #58a6ff; color: #58a6ff; }
  button.msg:hover { background: #58a6ff; color: #0d1117; }

  .section-title {
    color: #58a6ff;
    font-size: 1.1em;
    margin: 24px 0 12px;
    border-bottom: 1px solid #21262d;
    padding-bottom: 8px;
  }

  .board-item, .file-item {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 12px;
    margin-bottom: 8px;
  }
  .file-name { color: #58a6ff; font-size: 0.85em; margin-bottom: 4px; }
  .file-content {
    color: #8b949e;
    font-size: 0.8em;
    white-space: pre-wrap;
    max-height: 200px;
    overflow-y: auto;
  }
  .file-time { color: #484f58; font-size: 0.7em; }

  /* Modal */
  .modal-overlay {
    display: none;
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0,0,0,0.7);
    z-index: 100;
    align-items: center;
    justify-content: center;
  }
  .modal-overlay.open { display: flex; }
  .modal {
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 24px;
    width: 480px;
    max-width: 90vw;
  }
  .modal h2 { color: #f0f6fc; font-size: 1.1em; margin-bottom: 16px; }
  .modal label { display: block; color: #8b949e; font-size: 0.85em; margin-bottom: 4px; }
  .modal input, .modal textarea, .modal select {
    width: 100%;
    background: #0d1117;
    color: #c9d1d9;
    border: 1px solid #30363d;
    border-radius: 6px;
    padding: 8px;
    font-size: 0.9em;
    margin-bottom: 12px;
    font-family: inherit;
  }
  .modal textarea { height: 120px; resize: vertical; }
  .modal-actions { display: flex; gap: 8px; justify-content: flex-end; }

  /* Detail panel */
  .detail-panel {
    display: none;
    background: #161b22;
    border: 1px solid #30363d;
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 24px;
  }
  .detail-panel.open { display: block; }
  .detail-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
  }
  .detail-header h2 { color: #f0f6fc; font-size: 1.2em; }
  .detail-close { cursor: pointer; color: #484f58; font-size: 1.2em; }
  .detail-close:hover { color: #f0f6fc; }
  .detail-tabs { display: flex; gap: 8px; margin-bottom: 12px; }
  .detail-tab {
    padding: 4px 12px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 0.85em;
    color: #8b949e;
    background: transparent;
    border: 1px solid transparent;
  }
  .detail-tab.active { color: #58a6ff; border-color: #58a6ff; }
</style>
</head>
<body>

<h1><span style="color:#484f58">muster</span> <span style="color:#58a6ff">/</span> <span id="project-name">loading...</span></h1>
<div class="meta">
  <span id="status-badge">loading...</span>
  &middot; <span id="user-title"></span>
  &middot; <span id="agent-cli"></span>
</div>

<div class="grid" id="agent-grid"></div>

<div class="detail-panel" id="detail-panel">
  <div class="detail-header">
    <h2 id="detail-name"></h2>
    <span class="detail-close" onclick="closeDetail()">&times;</span>
  </div>
  <div class="detail-tabs" id="detail-tabs"></div>
  <div id="detail-content"></div>
</div>

<div class="section-title">Board</div>
<div id="board-list"></div>

<!-- Message Modal -->
<div class="modal-overlay" id="msg-modal">
  <div class="modal">
    <h2>Send Message</h2>
    <label>To</label>
    <select id="msg-to"></select>
    <label>Subject</label>
    <input id="msg-subject" placeholder="e.g. question about auth flow">
    <label>Priority</label>
    <select id="msg-priority">
      <option value="low">Low</option>
      <option value="medium" selected>Medium</option>
      <option value="high">High</option>
      <option value="critical">Critical</option>
    </select>
    <label>Message</label>
    <textarea id="msg-content" placeholder="What do you need?"></textarea>
    <div class="modal-actions">
      <button onclick="closeModal()">Cancel</button>
      <button class="msg" onclick="sendMessage()">Send</button>
    </div>
  </div>
</div>

<script>
let STATE = null;
let selectedAgent = null;

async function fetchStatus() {
  try {
    const res = await fetch('/api/status');
    STATE = await res.json();
    render();
  } catch (e) {
    console.error('Failed to fetch status', e);
  }
}

function countClass(n, threshold) {
  if (n === 0) return 'zero';
  if (n > threshold) return 'danger';
  if (n > 1) return 'warn';
  return '';
}

function cardClass(agent) {
  let cls = 'card';
  if (agent.lead) cls += ' lead';
  if (agent.inbox_count > 3 || agent.active_count > 3) cls += ' danger';
  else if (agent.inbox_count > 1 || agent.active_count > 2) cls += ' warn';
  return cls;
}

function render() {
  if (!STATE) return;

  document.getElementById('project-name').textContent = STATE.project;
  document.getElementById('status-badge').innerHTML = STATE.running
    ? '<span class="running">● running</span>'
    : '<span class="stopped">○ stopped</span>';
  document.getElementById('user-title').textContent = STATE.user_title;
  document.getElementById('agent-cli').textContent = STATE.agent_cli;

  const grid = document.getElementById('agent-grid');
  grid.innerHTML = STATE.agents.map(a => `
    <div class="${cardClass(a)}" onclick="showDetail('${a.name}')">
      <div class="card-header">
        <span class="card-name">${a.name}${a.lead ? '<span class="lead-badge">lead</span>' : ''}</span>
      </div>
      <div class="card-character">${a.character.substring(0, 100)}${a.character.length > 100 ? '...' : ''}</div>
      <div class="card-role">${a.role}</div>
      <div class="card-model">${a.model || ''}</div>
      <div class="card-status ${a.pane_status === 'offline' ? 'offline' : a.pane_status === 'idle' ? 'idle' : 'working'}">${escapeHtml(a.pane_status)}</div>
      <div class="counts">
        <div class="count-item">inbox <span class="count-num ${countClass(a.inbox_count, 3)}">${a.inbox_count}</span></div>
        <div class="count-item">active <span class="count-num ${countClass(a.active_count, 3)}">${a.active_count}</span></div>
        <div class="count-item">archive <span class="count-num">${a.archive_count}</span></div>
      </div>
      <div class="card-actions" onclick="event.stopPropagation()">
        <button class="nudge" onclick="nudge('${a.name}')">nudge</button>
        <button class="msg" onclick="openModal('${a.name}')">message</button>
      </div>
    </div>
  `).join('');

  const board = document.getElementById('board-list');
  if (STATE.board.length === 0) {
    board.innerHTML = '<div style="color:#484f58;font-size:0.85em;">No tasks on the board.</div>';
  } else {
    board.innerHTML = STATE.board.map(f => `
      <div class="board-item">
        <div class="file-name">${f.name}</div>
        <div class="file-content">${escapeHtml(f.content)}</div>
        <div class="file-time">${f.modified}</div>
      </div>
    `).join('');
  }

  // Update detail if open
  if (selectedAgent) {
    const agent = STATE.agents.find(a => a.name === selectedAgent);
    if (agent) renderDetail(agent);
  }
}

function escapeHtml(s) {
  return s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function showDetail(name) {
  selectedAgent = name;
  const agent = STATE.agents.find(a => a.name === name);
  if (!agent) return;
  document.getElementById('detail-panel').classList.add('open');
  renderDetail(agent, 'active');
}

function renderDetail(agent, tab) {
  document.getElementById('detail-name').textContent = `${agent.name} — ${agent.role}`;

  const tabs = ['active', 'inbox', 'journal', 'notes'];
  const tabsEl = document.getElementById('detail-tabs');
  if (!tab) tab = tabsEl.querySelector('.active')?.dataset?.tab || 'active';

  tabsEl.innerHTML = tabs.map(t => `
    <span class="detail-tab ${t === tab ? 'active' : ''}" data-tab="${t}" onclick="renderDetail(STATE.agents.find(a=>a.name==='${agent.name}'), '${t}')">${t} (${(agent[t] || []).length})</span>
  `).join('');

  const content = document.getElementById('detail-content');
  const items = agent[tab] || [];
  if (items.length === 0) {
    content.innerHTML = '<div style="color:#484f58;font-size:0.85em;padding:12px;">Empty.</div>';
  } else {
    content.innerHTML = items.map(f => `
      <div class="file-item">
        <div class="file-name">${f.name}</div>
        <div class="file-content">${escapeHtml(f.content)}</div>
        <div class="file-time">${f.modified}</div>
      </div>
    `).join('');
  }
}

function closeDetail() {
  selectedAgent = null;
  document.getElementById('detail-panel').classList.remove('open');
}

async function nudge(name) {
  const btn = event.target;
  btn.textContent = '...';
  try {
    await fetch('/api/nudge', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({agent: name})
    });
    btn.textContent = 'nudged!';
    setTimeout(() => btn.textContent = 'nudge', 2000);
  } catch (e) {
    btn.textContent = 'failed';
    setTimeout(() => btn.textContent = 'nudge', 2000);
  }
}

function openModal(name) {
  const select = document.getElementById('msg-to');
  select.innerHTML = STATE.agents.map(a =>
    `<option value="${a.name}" ${a.name === name ? 'selected' : ''}>${a.name}</option>`
  ).join('');
  document.getElementById('msg-subject').value = '';
  document.getElementById('msg-content').value = '';
  document.getElementById('msg-modal').classList.add('open');
}

function closeModal() {
  document.getElementById('msg-modal').classList.remove('open');
}

async function sendMessage() {
  const to = document.getElementById('msg-to').value;
  const subject = document.getElementById('msg-subject').value || 'message';
  const content = document.getElementById('msg-content').value;
  const priority = document.getElementById('msg-priority').value;
  if (!content) return;

  await fetch('/api/message', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({to, subject, content, priority})
  });
  closeModal();
  fetchStatus();
}

// Poll every 5 seconds
fetchStatus();
setInterval(fetchStatus, 5000);
</script>
</body>
</html>"""


def main():
    port = 4200
    if len(sys.argv) > 1:
        try:
            port = int(sys.argv[1])
        except ValueError:
            pass

    # Try up to 10 ports if the requested one is taken
    server = None
    for attempt in range(10):
        try:
            server = HTTPServer(("127.0.0.1", port + attempt), DashboardHandler)
            port = port + attempt
            break
        except OSError:
            continue

    if not server:
        print(f"Could not bind to any port in range {port}-{port + 9}")
        sys.exit(1)

    # Write actual port to file so other commands can find it
    port_file = ROOT / ".muster-dashboard-port"
    port_file.write_text(str(port))

    print(f"\n  muster dashboard running at http://localhost:{port}\n")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n  dashboard stopped.\n")
        server.server_close()
        port_file.unlink(missing_ok=True)


if __name__ == "__main__":
    main()
