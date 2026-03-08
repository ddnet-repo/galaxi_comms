# Patterns & Gotchas

## Pagination
- `internal/utils/pagination.go` expects 1-indexed pages, NOT 0-indexed
- Default page size: 20, max: 100
- Always return `total`, `page`, `limit`, `results` in response wrapper

## Tenant Isolation
- ALWAYS add tenant filter FIRST, then build the rest of the query on top
- Never the other way around — you will forget it if it's not the first thing
- Every query that touches user data must be scoped to the caller's org

## Bun ORM
- `.Where()` chains are additive (AND)
- Use `.WhereGroup()` for OR conditions
- Test DB resets between test files but NOT between test functions — use `t.Cleanup()`

## Conventions
- All list endpoints follow: parse params -> build query -> tenant filter -> paginate -> execute -> return wrapper
- Error responses use `internal/errors/api_error.go` — never return raw errors
