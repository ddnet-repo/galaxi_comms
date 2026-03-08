# RBAC Migration — Handoff

**From:** Bravo (Backend)
**Type:** handoff
**Priority:** high
**Summary:** Role-based access control migration — adding `role` column to users table and seeding default roles.

## Status
- Schema migration written and tested: `migrations/20260308_add_user_roles.sql`
- Seed data for default roles (admin, member, viewer) is drafted but NOT tested
- Handler changes have NOT been started

## Reason
Overloaded — I have two blocking tasks in active that Charlie and Delta are waiting on. This one isn't blocking anyone yet so it can move.

## What's Remaining
1. Test the seed data migration
2. Update user handlers to check/enforce roles
3. Add role filtering to the user search endpoint
4. Write tests for role-based access checks
