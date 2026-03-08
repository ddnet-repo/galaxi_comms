# Session 001 — 2026-03-08

## What I Learned

- The pagination helper in `internal/utils/pagination.go` expects 1-indexed pages, not 0-indexed. Wasted 20 minutes on an off-by-one. Remember this.
- Bun ORM's `.Where()` chains are additive — each call ANDs with the previous. Use `.WhereGroup()` for OR conditions.
- The test database resets between test files but NOT between test functions in the same file. Use `t.Cleanup()` to avoid state leaks.

## Patterns Discovered

- All list endpoints follow the same shape: parse query params -> build query -> apply tenant filter -> apply pagination -> execute -> return wrapper. Could be extracted into a generic helper but nobody's asked for that yet. Note for later.

## Where I Left Off

- Finished user search endpoint. Committed. Notified Architect.
- Inbox is empty. Active is clear. Told the team I'm idle.

## Mistakes

- Forgot to add tenant isolation on my first pass of the search query. Caught it in manual testing before committing. Always add the tenant filter FIRST, then build the rest of the query on top of it. Never the other way around.
