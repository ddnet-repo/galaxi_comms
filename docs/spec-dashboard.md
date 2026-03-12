# Spec: Muster Dashboard

## Problem

Viewing agents in tmux windows is clunky. If you're looking at a window, incoming messages replace what you're typing. You can't get a bird's-eye view without flipping through every window. There's no easy way to interact with the lead or send messages without manually creating files.

## Solution

A local web dashboard that runs alongside the tmux session. Agents keep running in tmux — the dashboard is a read/write view into the same comms system.

## Architecture

```
comms/           <- filesystem protocol (unchanged)
muster.db        <- SQLite database (new, view layer)
muster-web/      <- simple Python web server + HTML
```

The filesystem remains the source of truth. SQLite mirrors it for fast querying. A file watcher syncs filesystem -> db. The web UI reads from db and writes to filesystem (which then syncs back to db).

## SQLite Schema

```sql
CREATE TABLE agents (
  name TEXT PRIMARY KEY,
  role TEXT,
  character TEXT,
  model TEXT,
  lead BOOLEAN,
  rules TEXT
);

CREATE TABLE events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  agent TEXT NOT NULL,
  type TEXT NOT NULL,  -- inbox_received, active_started, active_completed, commit, journal
  summary TEXT,
  detail TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agent) REFERENCES agents(name)
);

CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  from_agent TEXT NOT NULL,  -- 'user' for messages from the dashboard
  to_agent TEXT NOT NULL,
  subject TEXT,
  content TEXT,
  priority TEXT DEFAULT 'medium',  -- low, medium, high, critical
  read BOOLEAN DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (to_agent) REFERENCES agents(name)
);

CREATE TABLE snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  agent TEXT NOT NULL,
  inbox_count INTEGER DEFAULT 0,
  active_count INTEGER DEFAULT 0,
  archive_count INTEGER DEFAULT 0,
  last_commit TEXT,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (agent) REFERENCES agents(name)
);
```

## File Watcher -> DB Sync

A Python process watches `comms/` for changes using inotifywait (already a dependency):

- New file in `inbox/` -> INSERT into events (inbox_received) + update snapshots
- File moved to `active/` -> INSERT into events (active_started) + update snapshots
- File moved to `archive/` -> INSERT into events (active_completed) + update snapshots
- New file in `journal/` -> INSERT into events (journal)
- Any change -> update snapshots for that agent

## Web UI

Simple Python HTTP server (no framework, stdlib only — or Flask if we want to be nice about it). Single page.

### Views

**Main dashboard:**
- Grid of agent cards
- Each card: name, character, model, inbox count, active count
- Lead agent highlighted
- Color coding: green = idle, yellow = active, red = inbox > 3

**Agent detail (click a card):**
- Current active tasks (contents of active/)
- Recent inbox messages
- Recent journal entries
- Notes preview
- Event timeline

**Send message (from any view):**
- Pick recipient (or "lead")
- Subject, content, priority
- Writes .md file to their inbox/
- Creates db record

**Board view:**
- Contents of comms/board/
- Read-only from dashboard (only lead writes to board)

### Tech

- Python 3 (already required)
- SQLite 3 (ships with Python)
- No npm, no node, no build step
- Single `muster-web.py` file or small package
- HTML/CSS/JS inlined or in a templates dir
- Auto-refresh via polling or SSE

## Commands

```
muster dashboard    # starts the web server, opens browser
muster dashboard --port 8080
```

Runs alongside `muster start`. Not a replacement for tmux — a companion.

## Migration Path

1. `muster start` seeds the db from team.json
2. File watcher keeps db in sync
3. `muster dashboard` starts the web UI
4. Eventually: agents could write to db directly (faster than filesystem)
5. Eventually: replace tmux entirely — agents run headless, dashboard is the only UI

## Open Questions

- Should agents write to db directly or only through filesystem?
- Should the dashboard be able to modify the board (breaking the "only lead writes" rule)?
- SSE for real-time updates vs polling every N seconds?
- Do we want to show the actual tmux output (terminal content) in the web UI? That's much harder but much cooler.
- Authentication? Probably unnecessary for a local dev tool but worth considering if anyone runs it on a server.

## Not In Scope (Yet)

- Mobile app
- Multi-user
- Cloud hosting
- Agent-to-agent chat in real time (they use inboxes)
- Replacing tmux entirely (future goal)
