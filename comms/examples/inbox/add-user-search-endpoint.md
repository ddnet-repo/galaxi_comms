# Add User Search Endpoint

**From:** Alpha (Architect)
**Priority:** high
**Summary:** Build a search endpoint for users with filtering and pagination.

## Details

We need `GET /api/users/search` with the following:

- Query params: `q` (search string), `role` (filter), `page`, `limit`
- Search across `name` and `email` fields
- Return paginated results with total count
- Respect tenant isolation — only return users within the caller's organization

## References

- User model: `internal/models/user.go`
- Existing list endpoint: `internal/handlers/users.go:45`
- Follow the pagination pattern from the organizations handler

## Acceptance Criteria

- Searches are case-insensitive
- Empty `q` returns all users (filtered by role if provided)
- Default page size: 20, max: 100
- Response includes `total`, `page`, `limit`, `results`
