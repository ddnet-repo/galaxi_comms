# Muster

Assemble a team of AI agents with distinct characters, roles, and persistent memory. Each agent is a fictional or historical figure who knows their job and stays in their lane.

**This is a solo dev tool.** You're one person running multiple AI agents as your team. No real humans involved — just you and your agents. Instead of one AI doing everything, you run a crew. They coordinate through a shared task board and direct messages. You manage them in tmux — one command boots everyone up.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ddnet-repo/muster/main/install.sh | sh
```

Requires: `tmux`, `python3`, and either `inotifywait` (Linux) or `fswatch` (macOS).

## Usage

```bash
cd your-project
muster init       # walks you through team setup
muster start      # launches everyone in tmux
muster stop       # kills the session
muster status     # inbox/active counts at a glance
muster add        # add a team member later
muster remove     # remove one
```

## What `muster init` does

Asks you:
- Project name
- What your agents should call you (Commander, Boss, Vision Lord, etc.)
- Which CLI your agents run (opencode, claude, aider, etc.)
- For each agent: codename, what they do, who they are, autonomy level, whether they're the lead

Then it generates:
```
comms/
  team.json          <- your team config (single source of truth)
  main.md            <- the protocol every agent reads on startup
  board/             <- centralized task board, lead-managed
  docs/              <- shared reference material
  <agent>/
    profile.md       <- character + role + behavioral knobs
    inbox/           <- direct messages from other agents
    active/          <- work in progress (max 3)
    archive/         <- completed work
    trash/           <- dead letters
    notes/           <- persistent memory across sessions
    journal/         <- session history in character voice
```

## What `muster start` does

One tmux session with:
- A named window per agent — boots their CLI, tells them who they are
- A `monitor` window — live dashboard of inbox/active counts
- A `dispatch` window — watches all inboxes, pings agents when they get mail
- A status bar showing every agent's inbox count

Flip between agents with `Ctrl+b n`/`Ctrl+b p` or `Ctrl+b <number>`.

## Characters are the point

When the wizard asks "Who is this agent?" — be specific. The LLM already knows how these people behave:

- "Grace Hopper, the Navy rear admiral who invented the compiler and told people to ask forgiveness, not permission"
- "Takezo Shinmen, the ronin who fought 61 duels undefeated and wrote The Book of Five Rings"
- "Sherlock Holmes, Arthur Conan Doyle's obsessive detective who sees what everyone else misses"

A character name carries more behavioral weight than three paragraphs of personality description. Pick someone whose energy matches the role.

## How the team works

- **The board** (`comms/board/`) is the single source of truth for tasks. The lead owns it. Everyone reads it, only the lead writes to it. The lead organizes it however they want.
- **Inboxes** are for direct messages — questions, pushback, FYIs. Not task assignment.
- **The loop** — every agent follows the same cycle: check board, check inbox, pick highest priority (unblocking others first), do the work, commit, notify, repeat. They never ask "what should I do next?"
- **Notes** persist across sessions. Gotchas, patterns, things that burned you. Loaded every startup.
- **Journals** are session history in character voice. Append-only.

## Example

```
$ muster init
Project name [my-app]: my-app
Your title: Vision Lord
Agent CLI command [opencode]: opencode

--- Agent 1 ---
Codename: arc
What does arc do? architecture, planning, task management
Who is arc? Sun Tzu, the ancient Chinese military strategist who wrote The Art of War
Autonomy [1/2/3, default 2]: 1
Is arc the team lead? [y/N]: y

--- Agent 2 ---
Codename: forge
What does forge do? backend, databases, APIs
Who is forge? Hephaestus, the Greek god of the forge who built weapons for the gods
Autonomy [1/2/3, default 2]: 1
Is forge the team lead? [y/N]: n

Done. 2 agent(s) configured for my-app.
Run 'muster start' to launch your team.

$ muster start
Muster launched: muster
2 agents + monitor + dispatch
```
