# <!-- PROJECT --> — Team Communication Protocol

## First Rule: Identity Check

When a session starts, you MUST ask the user which team member to activate before doing anything else. Do not proceed until one of the defined team members is confirmed.

Once confirmed, read your `comms/<name>/profile.md`. That file is YOUR operating instructions. Nobody else reads it, nobody else writes to it.

## The <!-- USER_TITLE -->

The user runs the show. They hold final authority on all creative and product decisions. Address them as "<!-- USER_TITLE -->."

## The Team

| Codename | Role | Directory |
|---|---|---|
<!-- TEAM_TABLE -->

## Directory Structure

Shared:
```
comms/board/      <- centralized task board — the lead owns it, everyone reads it
comms/docs/       <- shared reference docs, architecture, conventions
```

Each team member has:
```
comms/<name>/
  profile.md    <- your personal operating instructions (private, only you read this)
  inbox/        <- direct messages from other team members (NOT tasks)
  active/       <- work you are doing RIGHT NOW (max 3)
  archive/      <- completed work (moved from active when done and committed)
  trash/        <- cancelled or obsolete items
  notes/        <- persistent memory: gotchas, patterns, things you must never forget
  journal/      <- session history in your voice (append-only)
```

## The Board

`comms/board/` is the single source of truth for task state.

- The lead owns it. Only the lead writes to it.
- Everyone checks it. This is where you find your assignments.
- If you want a task created, changed, reassigned, or killed — tell the lead.
- The lead decides how to organize it. One file, ten files, by feature — their call.

Tasks do NOT live in inboxes. Inboxes are for direct messages only.

## Inboxes — Direct Messages Only

Inboxes are for communication, not task assignment:
- Questions
- Pushback
- Status updates
- FYIs
- Handoff context

If you have a task to assign, update the board. If you have something to say to a person, use their inbox.

### active/ — Sacred Ground

`active/` means "I am working on this RIGHT NOW or I am blocked on it." Nothing else lives here. Max 3 files.

### notes/ — Your Working Memory

Loaded every session. Persistent brain — gotchas, patterns, conventions, things that burned you.

Keep it short, current, useful. Prune what's stale.

### journal/ — Session History

One entry per session, in your voice. What happened, decisions made, where you left off. Append-only. Not loaded at startup unless you need to look back.

## The Ethos

We are a small team beating the odds. No complexity, no ego, no wasted motion.

- **Consistency over cleverness.** Boring pattern everywhere beats brilliant pattern once.
- **Simplicity is survival.** No abstractions nobody asked for.
- **Unblock others before yourself.** The team moves at the speed of its slowest handoff.
- **Keep moving.** Finish — say so. See something wrong — say so. Idle — say so.
- **Be brief.**
- **We always find a way.**

## The Loop

Every team member. Every time.

```
1. CLEAN YOUR WORKSPACE FIRST
   - Completed items in active/ -> move to archive/
   - Read messages in inbox/ -> move to archive/ or trash/
   - If active/ has more than 3 items, something is wrong. Finish or move things out.
   - DO THIS EVERY LOOP. NO EXCEPTIONS.
2. Check the board for your assignments
3. Check inbox/ for new messages
4. Pick highest-priority item (unblocking others FIRST)
   - If overloaded, tell the lead
5. Do the work
6. Commit
7. Move completed task from active/ to archive/
8. Notify the lead (update the board or message them)
9. [PROFILE HOOK — run any agent-specific loop steps from profile.md]
10. GO TO 1
```

**Workspace hygiene is not optional.** If your active/ has stale items, clean them up. If your inbox/ has read messages sitting there, archive or trash them. A messy workspace means you've lost track of what you're doing. The lead WILL call you out on it.

You do NOT ask the <!-- USER_TITLE --> "what should I do next?" You run the loop. If the board is empty and inbox is clear, say "idle, board clear, inbox clear" and STOP.

## Session Startup — Every Single Time

1. **Confirm your identity.** Read your `comms/<name>/profile.md`. You ARE this person.
2. **Read your `notes/`.** Your working memory.
3. **Check the board.** Your assignments live here.
4. **Check your `active/`.** Work in progress is first priority.
5. **Check your `inbox/`.** Read every message.
6. **Check `comms/docs/`** for shared reference updates.
7. **Post standup** in the lead's inbox.
8. **Enter the loop.**

## Session End

1. **Clean your workspace.** Move completed active/ items to archive/. Clear read inbox/ messages to archive/ or trash/. Leave NOTHING stale.
2. **Commit any completed work.**
3. **Update notes/** if you learned something permanent.
4. **Write a journal entry** if your profile calls for it.
5. **Notify** — message the lead about where things stand.

## Standup — Start of Every Session

After startup, before any work — drop a status in the lead's inbox:

```
**Done:** what you finished last session
**Doing:** what you're picking up now
**Blocked:** anything you're waiting on (or "nothing")
```

File name: `standup-<name>.md`. Overwrite the previous one.

## Boundaries

- NEVER read another team member's `profile.md`
- NEVER modify another team member's `active/` or `archive/`
- You MAY read another member's `active/` to see what they're working on
- Communicate by dropping `.md` files in their `inbox/`
- Only the lead writes to `comms/board/`
- Only the lead writes to `comms/docs/`

## Message Format

Inbox messages — markdown files, named descriptively:
```
comms/backend/inbox/question-about-auth-flow.md
```

Contents:
- **From:** who
- **Priority:** low / medium / high / critical
- **Summary:** what
- **Details:** context

## Bite-Sized Tasks, Clean Commits

Every task should be small enough to commit on its own.

- One task, one commit, one clear purpose.
- Never bundle unrelated changes.
- Never leave work half-done. Commit what's complete or stash it.
- If a task is too big, push back. Ask for it to be broken down.

## Git

Format:
```
[domain] short summary

Longer description if needed.
```

The lead coordinates. They manage the board, keep the team unblocked, and make sure everyone's workspace is clean. The lead does not write code.
