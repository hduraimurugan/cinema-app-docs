# Tenant Integrity & Auth/Org Wiring

Summary of the latest commit in each app repo as of 2026-08-08, covering the
two-phase fix to the Organisations (multi-tenant) layer: making tenancy a
database invariant, and making org identity/permissions actually reach the
admin UI. See `settings-module-architecture.md` and `teams_implementation.md`
for the original design this corrects.

## Context

The Organisations layer (`organizations`, `roles`, `organization_members`,
`hall_assignments`) was added incrementally but had two classes of defect:

1. **The schema couldn't enforce its own tenancy.** A member's `role_id` and
   a `hall_assignments` row could reference a *different* organization than
   the member belonged to, with nothing in the application checking either.
   `cinema_hall.admin_id` also cascaded on delete, so removing one admin user
   destroyed that org's halls → screens → shows → bookings.
2. **Org identity never reached the admin frontend.** The token-issuing
   helper resolved a user's `orgId` into a variable it then discarded, so
   login always returned `orgId: undefined` and `permissions: []`; the
   frontend then overwrote even the correct `/me` values with those
   undefineds. `PermissionContext` additionally treated the DB-default
   `admin` role as a superAdmin bypass, so `can()` returned `true` for
   everyone regardless — which is why (1) went unnoticed.

Phase 1 (below, `cinema-hall-api`) makes tenancy a DB invariant via composite
foreign keys. Phase 2 (`cinema-hall-api` + `cinema-hall-admin`) makes org
identity and permissions work end to end.

---

## `cinema-hall-api` — `50b1feb`

**feat: Implement organization and hall access verification**

| File | Change |
|---|---|
| `database/migration_phase4_tenant_integrity.sql` | New. Idempotent migration: `UNIQUE (id, org_id)` anchors on `roles`/`cinema_hall`/`organization_members`; composite FK so a member's role must belong to their own org; `hall_assignments` gains `org_id` and composite FKs to both the member and the hall, closing the cross-org grant; `cinema_hall.admin_id` → `ON DELETE SET NULL` (was `CASCADE`); partial unique index so removed members can be re-invited; `organizations.owner_id` → `ON DELETE RESTRICT`; owner-membership backfill. Includes commented pre-flight audit queries and trailing assertions. |
| `middleware/verifyCinemaAdmin.js` | New `requireActiveOrg` (reads `X-Org-Id`, verifies active membership, sets `req.orgId`/`req.orgRole`). `requireActiveHall` rewritten to resolve through org membership — an org `owner`/`admin` now gets access to any hall in their org (previously only the hall's creator or an explicit assignment worked, so `GET /api/halls` could list a hall that then 403'd). |
| `middleware/requirePermission.js` | `resolveOrgId` is now a pure lookup through `organization_members` (previously it also auto-created an organization as a side effect of a GET, and checked `organizations.owner_id` first). Added `permissionsVersion` staleness check — a token from before a role edit is now rejected with `401 TOKEN_STALE` instead of serving the old permission set for up to a day. |
| `utils/generateTokenAndSetCookie.js` | Now **returns** `{ orgId, roleKey, permissionsVersion }` instead of resolving them into a variable the caller never saw — this was the root cause of `orgId: undefined` on login. |
| `controllers/auth.Controller.js` | Login, Google login, and GitHub login all consume the returned org context and include `orgId`/`roleKey`/`permissions` in the response (Google/GitHub previously omitted them entirely). |
| `controllers/settings.Controller.js` | Removed a duplicate `resolveOrgId` implementation; imports the one in `requirePermission.js`. |
| `controllers/team.Controller.js`, `services/team.service.js` | Validate that a `roleId`/`hallId` passed to invite/create/update-member/assign-halls actually belongs to the target org before writing, mapping violations to 400/409 instead of the migration's new FK constraints surfacing as a raw 500. `inviteMember` now revives a previously-removed member instead of failing. |
| `server.js` | `Access-Control-Allow-Headers` extended to include `X-Org-Id` alongside `X-Hall-Id`. |
| `tests/setup/schema.sql`, `tests/setup/factories.js` | Test schema mirrors the migration; extracted a `createOrganization` factory that seeds roles + owner membership (fixtures previously created orgs with no owner membership, which the new pure `resolveOrgId` can't resolve). |
| `tests/unit/controllers/settings.test.js`, `tests/unit/middleware/verifyCinemaAdmin.test.js` | Updated/added coverage for the above, including `requireActiveOrg` and the org-wide-role hall access path. |

## `cinema-hall-admin` — `2b54a38`

**feat: enhance authentication and permission handling with orgId management and improved role checks**

| File | Change |
|---|---|
| `src/context/AuthContext.jsx` | Removed three places where `orgId`/`roleKey`/`permissions` were read from the top level of the API response and used to *overwrite* the correct values already present on `res.admin`. Now mirrors `user.orgId` into `localStorage.activeOrgId` so the fetch interceptors can attach it without threading context through every service file. |
| `src/context/PermissionContext.jsx` | Removed `role === 'admin'` from the `isSuperAdmin` bypass — `admin` is the default DB role for every registered user, so `can()` was returning `true` unconditionally. Only the platform `superAdmin` role bypasses now; `owner` needs none since it's seeded with every permission. |
| `src/pages/OnboardingPage.jsx` | Added a guard redirecting an already-onboarded admin (`user.orgId` set) away from the onboarding flow — `completeOnboarding` reuses the org but creates a **new hall** every time it runs, so reaching this page a second time was destructive. |
| `src/services/api.js`, `src/services/settings/settingsService.js`, `src/services/settings/teamService.js` | The `hallFetch` interceptor (all three copies) now also attaches `X-Org-Id` from `localStorage`, alongside the existing `X-Hall-Id`. |

## `cinema-hall-users` — `548e50f`

**feat: create MovieDetailsPage to display movie showtimes and cinema halls based on user location**

Not part of this initiative — this is simply the most recent commit in the
`cinema-hall-users` repo (dated 2026-06-21, predates the work above).
Reworked `src/pages/MovieDetailsPage.jsx` (191 insertions / 130 deletions) to
show showtimes and cinema halls filtered by the user's location.

---

## Verification performed

- Backend suite: 360/360 tests pass (`npm run test:run` in `cinema-hall-api`).
- Migration proven against a scratch DB rebuilt from the pre-phase-4 schema:
  reproduces both cross-org vulnerabilities, confirms the pre-flight audit
  catches them, confirms the migration refuses to apply while violations
  exist, and confirms all constraints/assertions hold after remediation +
  apply, including idempotency on a second run.
- Fresh-install path (`docs/db_setup.sql`) verified independently to
  converge on the same schema shape as the migrated path.
- Applied to the real local `cinema_hall_db` via pgAdmin; re-verified
  read-only afterward. One pre-existing (unrelated) data issue was found —
  an org with zero roles seeded, from stale test data — and fixed by
  re-running `db_setup.sql`'s idempotent seeding sections.
- `cinema-hall-admin` production build succeeds.

## Known follow-ups (not covered here)

Role templates + a single `provision_organization()` function to stop
duplicating RBAC seed logic; org-scoping `offers`/`ads`/`movies` (currently
platform-global); the cross-tenant pricing fallback in
`payment.Controller.js` and `settings.Controller.js` (`... LIMIT 1` when an
org can't be resolved); a proper `organization_invitations` table; audit
logging; Postgres RLS as defense in depth.
