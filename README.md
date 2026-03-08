# Galaxi Comms

A team communication and coordination system for AI-assisted software development with Claude Code.

Instead of one AI agent doing everything, Galaxi Comms lets you run multiple specialized team members — each with their own role, personality, memory, and inbox. You talk to one at a time. They communicate with each other through structured messages. The result is focused, disciplined work with clear ownership and persistent context across sessions.

## Why This Works

- **Specialization.** A "backend engineer" that only thinks about backend concerns writes better backend code than a generalist trying to do everything.
- **Persistent memory.** Each team member has `notes/` (permanent reference) and `journal/` (session history) that survive across sessions.
- **Structured communication.** Team members can't talk to each other directly. They leave messages in inboxes. This forces clear, written specs instead of vague handoffs.
- **Accountability.** Every task has an owner. Every piece of work gets committed independently. Nothing falls through the cracks.
- **The Loop.** A mandatory operating cycle (check inbox, work, commit, notify, repeat) that prevents agents from going idle or forgetting steps.
- **Characters stick.** When Claude inhabits a character with a distinct voice and personality, it commits harder to the role's constraints. A gruff backend engineer stays in their lane better than a generic assistant.
- **Personality-driven behavior.** Autonomy, pushback style, journaling, and workshopping are all configured per-agent in their profile — not forced globally.

## Quick Start

### 1. Copy into your project

Copy the `comms/` directory and `CLAUDE.md` into your project root:

```
your-project/
  CLAUDE.md              <- points Claude at comms/main.md
  comms/
    main.md              <- the protocol
    docs/
      roles.md           <- role definitions
      profile-template.md <- how to write profiles
    <member-name>/       <- one directory per team member
      profile.md
      inbox/
      active/
      archive/
      trash/
      notes/
      journal/
```

### 2. Define your team

Decide how many team members you need and what roles each one covers. See `comms/docs/roles.md` for the full role menu.

A small project might need 3 members:

| Codename | Roles |
|---|---|
| Architect | Architect, Documentation |
| Builder | Backend, Frontend, Data |
| Tester | QA, Overflow, Reviewer |

A larger project might need 5+:

| Codename | Roles |
|---|---|
| Architect | Architect, Product, API Design |
| Backend | Backend, Data, DevOps |
| Frontend | Frontend, Accessibility |
| QA | QA, Overflow, Performance |
| Ops | DevOps, Security, Release |

### 3. Create team member directories

For each team member, create their directory with all subdirectories:

```bash
mkdir -p comms/architect/{inbox,active,archive,trash,notes,journal}
mkdir -p comms/backend/{inbox,active,archive,trash,notes,journal}
mkdir -p comms/frontend/{inbox,active,archive,trash,notes,journal}
```

### 4. Write profiles

Create a `profile.md` in each member's directory. See `comms/docs/profile-template.md` for the template.

Profiles define the character AND behavioral knobs:

```markdown
# Scotty — Chief Engineer

You are Montgomery "Scotty" Scott. You keep the engines running.

## User Title
Captain

## Voice
Direct, practical, slightly exasperated.

## Roles
- Backend
- DevOps

## Autonomy Level
high — just does the work, reports when done

## Pushback Style
Blunt. "Captain, I'm telling ye, this willnae hold."

## Workshopping
no — executes, routes questions through inboxes

## Journal Tendency
moderate — brief engineering log each session

## Loop Extensions
- After every commit, verify the build still passes
```

### 5. Update the team table

Edit `comms/main.md` and fill in the team table with your members.

### 6. Add project context

Add any project-specific information to `comms/main.md` at the bottom — tech stack, repo structure, conventions. This is what every team member reads on startup.

### 7. Start a session

Open Claude Code. It reads `CLAUDE.md`, which points to `comms/main.md`. It asks who you are. You tell it. It reads the profile, notes, active, inbox, docs — and gets to work.

```
> you are scotty

[Claude reads profile, loads notes, checks active, checks inbox, posts standup]

"Aye, Captain. Scotty reporting in. Engines are warm, inbox has two items..."
```

## How It Works

### The Loop

Every agent follows the same mandatory operating cycle:

```
1. Check inbox/
2. Check active/ (hand off if overloaded)
3. Pick highest-priority item (unblocking others first)
4. Do the work
5. Commit
6. Archive the task
7. Notify (drop messages in relevant inboxes)
8. [Profile hook — agent-specific steps]
9. GO TO 1
```

Agents do NOT ask "what should I do next?" They run the loop. If inbox and active are both empty, they report idle and stop.

### Communication

Team members communicate by dropping `.md` files in each other's `inbox/` directories. This is the ONLY communication channel. Questions, pushback, status updates, handoffs — all go through inboxes.

Agents are expected to message each other constantly — when done, when blocked, when they disagree, when they have questions. The inbox is not just for tasks.

### Memory: Notes vs Journal

- **`notes/`** — Permanent working memory. Cheat sheets, gotchas, patterns. Loaded every session startup. Short, current, pruned regularly.
- **`journal/`** — Session history. Written in character voice at session end. Append-only. For looking back, not for startup loading.

### Task Lifecycle

```
inbox/  ->  active/  ->  archive/  (done, committed)
                     ->  trash/     (cancelled)
active/ ->  someone's inbox/       (handoff)
```

`active/` is sacred — max 3 items. If overloaded, hand tasks off to another agent's inbox with full context.

### Personality-Driven Behavior

These behaviors are configured per-agent in `profile.md`, not globally enforced:

| Behavior | What it controls |
|---|---|
| **User Title** | What the agent calls you (Colonel, Commander, Boss, etc.) |
| **Autonomy Level** | How independently the agent operates |
| **Pushback Style** | How the agent challenges bad ideas |
| **Workshopping** | Whether the agent brainstorms with you or just executes |
| **Journal Tendency** | How much the agent writes in their journal |
| **Loop Extensions** | Custom steps in the operating cycle |

Typically only the lead/Architect workshops with you. Everyone else executes and routes questions through inboxes.

### Handoffs

When an agent is overloaded or has a task better suited to someone else, they drop it in the appropriate agent's inbox with a handoff message that includes full context: what's done, what's remaining, why they're handing it off.

## Examples

The `comms/examples/` directory contains sample files:

- `inbox/add-user-search-endpoint.md` — a well-formatted task message
- `inbox/standup-bravo.md` — a standup message
- `inbox/handoff-rbac-migration.md` — a handoff between agents
- `notes/patterns.md` — a notes file with patterns and gotchas
- `journal/session-001.md` — a journal entry with learnings

## Adding Characters

Characters make this system work better. Here are some ideas:

**TV/Film:**
- The A-Team (Hannibal plans, Face handles UI, BA builds backend, Murdock tests)
- Star Trek bridge crew (Kirk leads, Scotty builds, Spock reviews, Uhura handles comms)
- Ocean's Eleven (Danny plans the heist, each specialist has their role)

**Archetypes:**
- "The grizzled veteran who's seen every production outage"
- "The meticulous craftsman who won't ship until it's right"
- "The chaos agent who finds every edge case"
- "The calm strategist who always has a plan"

**The key:** pick characters whose natural personality matches the role's energy. A QA engineer should be someone naturally suspicious and detail-oriented. An architect should be someone who thinks in systems. A frontend engineer should be someone who cares about craft and user experience.

**Match behavior to character.** A confident veteran gets high autonomy. A meticulous analyst checks in more. A blunt character pushes back hard. A diplomatic one asks probing questions. The profile's behavioral knobs should feel natural for the character.

## Customization

### Different number of team members

The system works with 2-10+ members. For solo projects, even 2 members (Architect + Builder) adds value — the Architect plans, the Builder executes, and the separation of concerns keeps both focused.

### Different role combinations

Roles are building blocks. Combine them however makes sense. See `comms/docs/roles.md` for the full list and example team configurations.

### Project-specific docs

Add your architecture docs, conventions, and reference material to `comms/docs/`. Everyone reads these on startup. The Architect maintains them.

### Custom domains

Define commit message domains in `comms/main.md` to match your project structure. `[backend]`, `[frontend]`, `[infra]` — whatever scopes make sense.

## Tips

- **Start small.** Two or three team members is plenty for most projects. Add more when you feel the need.
- **Characters > generic roles.** Claude commits harder to a character with personality than a role description.
- **Notes is the killer feature.** Persistent working memory that loads every session. Put the stuff that matters here.
- **Journal is for flavor and history.** Let personality drive how much they journal. Some characters write novels, others write nothing. Both are fine.
- **Let them push back — through inboxes.** Disagreement goes in writing, to the relevant inbox. Not workshopped with you directly (unless they're the Architect).
- **Only the Architect workshops.** This is the hardest rule and the most important. When every agent wants to brainstorm, nothing gets built. One thinker, many doers.
- **The Architect doesn't code.** When the planner also builds, they skip the planning. Keep the separation.
- **One team member per session.** You talk to one member at a time. Switch by starting a new session and saying "you are [name]."
- **The loop is the job.** Agents should never ask "what next?" — they check inbox, check active, pick work, do it, commit, notify, repeat. If they're idle, they say so.
