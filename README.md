# muster

Assemble AI agent teams with extreme character-driven personalities.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ddnet-repo/muster/master/install.sh | sh
```

Requires: `python3` and [opencode](https://github.com/anomalyco/opencode).

## Usage

```bash
cd your-project
muster init       # wizard: name agents, pick characters, choose a lead
opencode          # open the project — your agents are ready
```

Other commands:
```bash
muster info       # show project setup and team roster
muster add        # add a team member
muster remove     # remove one
muster reset      # wipe everything and start over
```

## What `muster init` does

Asks you:
- Project name
- What your agents should call you (Commander, Boss, My Lord, etc.)
- For each agent: codename, what they do, who they are (as a character), autonomy level
- Which agent is the lead (coordinates, delegates, doesn't code)
- Models per agent (opus for lead/thinking, sonnet for coding)

Then it generates:
```
.opencode/agents/
  <name>.md       <- OpenCode agent definition with extreme character personality
  ...

comms/
  team.json       <- team roster and config
  <name>/
    journal/      <- session logs in character voice (captain's log)
    notes/        <- persistent memory across sessions
  ...

opencode.json     <- OpenCode config
AGENTS.md         <- project instructions
```

## How it works

Muster generates [OpenCode agent definitions](https://opencode.ai/docs/agents/) with extreme character personalities. Each agent is a fully realized character — not a "tone" or a "style," but a complete personality that never breaks.

Coordination happens through OpenCode's native agent teams system: message passing, task management, peer-to-peer communication, auto-wake. Muster doesn't manage any of that — OpenCode does.

What muster adds:
- **Character layer** — Agents ARE their characters. Darth Vader doesn't politely suggest improvements. Scooby-Doo literally talks like Scooby-Doo. The character dynamics drive the team dynamics.
- **Persistent memory** — Each agent has `journal/` (session logs in their voice) and `notes/` (working memory). Read the journals to see your project's history told by characters.
- **Recipes** — Pre-built teams. Mystery Inc., Wu-Tang Clan, Star Wars dark side, Golden Girls, and more.

## Recipes

Pre-built team configurations in `.muster/`. Use them with `muster init --from <file>` or select interactively during init.

| Recipe | Theme | Agents |
|--------|-------|--------|
| `atelier.json` | Famous Artists | leo, frida, dali, basquiat, bob |
| `breaking-bad.json` | Breaking Bad | walt, jesse, gus, mike, saul |
| `dark-side.json` | Star Wars | palpatine, vader, tarkin, maul, thrawn |
| `golden-girls.json` | Golden Girls | dorothy, sophia, blanche, rose |
| `hells-kitchen.json` | Celebrity Chefs | ramsay, bourdain, child, white |
| `magnum-pi.json` | Magnum P.I. | magnum, higgins, rick, tc, robin |
| `mighty-boosh.json` | The Mighty Boosh | howard, vince, gregg, naboo, bollo |
| `mystery-inc.json` | Scooby-Doo | fred, velma, daphne, shaggy |
| `rogues-gallery.json` | Batman Villains | riddler, joker, bane, catwoman, freeze, scarecrow |
| `star-trek-villains.json` | Star Trek | khan, q, borg-queen, gul-dukat, chang |
| `writers-room.json` | Famous Authors | hemingway, poe, wilde, kafka, twain |
| `wrestlemania.json` | Pro Wrestling | undertaker, rock, stone-cold |
| `wu-tang.json` | Wu-Tang Clan | rza, gza, meth, deck, odb |

## Why characters?

When an LLM has a vivid character to inhabit, it commits harder to the role's constraints and communicates more distinctively. The character descriptions are deliberately extreme so that even after context dilution across a long session, the personality still comes through.

A backend engineer named "GZA" who approaches code like Liquid Swords — surgical, deliberate, no wasted bars — will produce more distinctive and consistent output than a generic "Backend Developer" prompt.

The friction between characters is intentional. If Vader force-chokes a subordinate for sloppy code, that's a feature. If Palpatine puts Vader in his place, that's the hierarchy working. Let them be who they are.
