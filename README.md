# Muster

Assemble a team of AI agents with distinct characters, roles, and persistent memory. Each agent is a fictional or historical figure who knows their job and stays in their lane.

**This is a solo dev tool.** You're one person running multiple AI agents as your team. No real humans involved — just you and your agents. Instead of one AI doing everything, you run a crew. They coordinate through a shared task board and direct messages. You manage them in tmux — one command boots everyone up.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ddnet-repo/muster/master/install.sh | sh
```

Requires: `tmux`, `python3`, `inotifywait` (from `inotify-tools`), and an agent CLI like [opencode](https://github.com/anomalyco/opencode). Linux only.

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
- What your agents should call you (Commander, Boss, Your Excellency, etc.)
- Which CLI your agents run (opencode, claude, aider, etc.)
- For each agent: codename, what they do, who they are, autonomy level
- Which agent is the lead (coordinates tasks, manages the board, doesn't code)
- Models per agent (opus for lead/content, sonnet for coding — sensible defaults)

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

**Tip: pick characters who push back.** LLMs already want to please you — that's their default. If you pick characters who are helpful and agreeable (the A-Team, the Avengers, any "team of heroes who love their boss"), you're amplifying the exact sycophancy problem that makes AI output useless. Pick villains, rivals, divas, curmudgeons — characters with opinions who wouldn't just nod along. Darth Vader doesn't care if you like his code review. Sophia Petrillo isn't going to sugarcoat her feedback. Higgins thinks your code is beneath him. That friction is a feature. It's the only way you get honest output from a machine that's wired to agree with you.

## How the team works

- **The board** (`comms/board/`) is the single source of truth for tasks. The lead owns it. Everyone reads it, only the lead writes to it. The lead coordinates — assigns tasks, unblocks people, and tells agents to clean up their workspace when things get messy.
- **Inboxes** are for direct messages — questions, pushback, FYIs. Not task assignment.
- **The loop** — every agent follows the same cycle: check board, check inbox, pick highest priority (unblocking others first), do the work, commit, notify, repeat. They never ask "what should I do next?"
- **Notes** persist across sessions. Gotchas, patterns, things that burned you. Loaded every startup.
- **Journals** are session history in character voice. Append-only.

## Example

```
$ muster init
Project name [my-app]: my-app
Agent CLI command [opencode]: opencode

--- Agent 1 ---
Codename: arc
What does arc do? architecture, planning, task management
Who is arc? Sun Tzu, the ancient Chinese military strategist who wrote The Art of War
Autonomy [1/2/3, default 2]: 1

2 agent(s) so far: arc
[a]dd another or [d]one? a

--- Agent 2 ---
Codename: forge
What does forge do? backend, databases, APIs
Who is forge? Hephaestus, the Greek god of the forge who built weapons for the gods
Autonomy [1/2/3, default 2]: 1

2 agent(s) so far: arc forge
[a]dd another or [d]one? d

Which agent is the lead?
  a) arc — architecture, planning, task management
  b) forge — backend, databases, APIs
Lead [a]: a

Assigning models
  arc [default 2]: 2          <- opus (lead)
  forge [default 1]: 1        <- sonnet (worker)

Done. 2 agent(s) configured for my-app.
Run 'muster start' to launch your team.
```

## Recipes

Don't want to build a team from scratch? Pick a premade one during `muster init`:

```
How do you want to set up your team?
  m) Manual — build from scratch
  r) Recipe — choose a premade team
[m/r]: r

Available recipes:
  a) Dark Side — Star Wars dark side themed team.
  b) Star Trek Villains — Star Trek antagonist themed team.
```

You can also import from any JSON file:

```
muster init --from my-team.json
```

See `docs/recipes/` for the full writeups and `recipes/` for the JSON files.

**Got a fun team?** Send a PR with a JSON file in `recipes/` and a writeup in `docs/recipes/`. We want to see what you come up with.
