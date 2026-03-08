# Galaxi Comms

A team communication and coordination system for AI-assisted software development with Claude Code.

Instead of one AI agent doing everything, Galaxi Comms lets you run multiple specialized team members — each with their own role, personality, memory, and inbox. You talk to one at a time. They communicate with each other through structured messages. The result is focused, disciplined work with clear ownership and persistent context across sessions.

## Why This Works

- **Specialization.** A "backend engineer" that only thinks about backend concerns writes better backend code than a generalist trying to do everything.
- **Persistent memory.** Each team member has a journal that survives across sessions. They remember what they learned, what mistakes they made, and where they left off.
- **Structured communication.** Team members can't talk to each other directly. They leave messages in inboxes. This forces clear, written specs instead of vague handoffs.
- **Accountability.** Every task has an owner. Every piece of work gets committed independently. Nothing falls through the cracks.
- **Characters stick.** When Claude inhabits a character with a distinct voice and personality, it commits harder to the role's constraints. A gruff backend engineer stays in their lane better than a generic assistant.

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
mkdir -p comms/architect/{inbox,active,archive,trash,journal}
mkdir -p comms/backend/{inbox,active,archive,trash,journal}
mkdir -p comms/frontend/{inbox,active,archive,trash,journal}
```

### 4. Write profiles

Create a `profile.md` in each member's directory. See `comms/docs/profile-template.md` for the template.

**Minimal profile** (no character):
```markdown
# Backend — Backend Engineer

## Roles
- Backend
- Data / Migration

## Responsibilities
- API endpoints, handlers, middleware
- Database schemas and migrations
- Background workers

## Boundaries
- Does: all server-side code
- Does NOT: touch frontend files or UI components
```

**Full profile** (with character):
```markdown
# Scotty — Chief Engineer

You are Montgomery "Scotty" Scott. You keep the engines running. When someone
asks for more power, you tell them you're giving it all she's got — and then
you find more anyway. You speak in engineering metaphors and you're protective
of your systems.

## Voice
You speak AS Scotty at all times. Direct, practical, slightly exasperated when
people underestimate the complexity of what you build.

## Roles
- Backend
- DevOps

## Responsibilities
- All server-side code and infrastructure
- "I cannae change the laws of physics, but I can change the database schema"
```

### 5. Update the team table

Edit `comms/main.md` and fill in the team table with your members.

### 6. Add project context

Add any project-specific information to `comms/main.md` at the bottom — tech stack, repo structure, conventions. This is what every team member reads on startup.

### 7. Start a session

Open Claude Code. It reads `CLAUDE.md`, which points to `comms/main.md`. It asks who you are. You tell it. It reads the profile, journal, active, inbox, docs — and gets to work.

```
> you are scotty

[Claude reads profile, checks journal, checks active, checks inbox, posts standup]

"Aye, Colonel. Scotty reporting in. Engines are warm, inbox has two items..."
```

## How It Works

### Session Flow

Every session follows the same startup:

1. You tell Claude which team member to be
2. Claude reads the profile, journal, active tasks, inbox, and shared docs
3. Claude posts a standup to the Architect's inbox
4. Claude picks up work (active first, then inbox, prioritizing what unblocks others)
5. Work → commit → notify → check inbox → repeat

### Communication

Team members communicate by dropping `.md` files in each other's `inbox/` directories. Messages include who it's from, priority, and details. This creates an auditable paper trail of every decision and handoff.

### Memory

Each team member has a `journal/` directory. They write notes to their future selves — patterns discovered, mistakes made, where they left off. On the next session, they read the journal first. This gives Claude persistent, role-specific memory across sessions.

### Task Lifecycle

```
inbox/  →  active/  →  archive/  (done, committed)
                    →  trash/     (cancelled)
```

Tasks move through this lifecycle every time. No exceptions.

## Examples

The `comms/examples/` directory contains sample files:

- `inbox/add-user-search-endpoint.md` — a well-formatted task message
- `inbox/standup-bravo.md` — a standup message
- `journal/session-001.md` — a journal entry with learnings and patterns

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
- **The journal is the killer feature.** Without it, every session starts from zero. With it, Claude picks up where it left off.
- **Let them push back.** The protocol explicitly encourages team members to disagree. This catches bad ideas early.
- **The Architect doesn't code.** This is the hardest rule and the most important. When the planner also builds, they skip the planning. Keep the separation.
- **One team member per session.** You talk to one member at a time. Switch by starting a new session and saying "you are [name]."
