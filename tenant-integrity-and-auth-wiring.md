# Tenant Integrity & Auth/Org Wiring

Log of the 2026-08-08 initiative that fixed the Organisations (multi-tenant)
layer: making tenancy a database invariant, making org identity/permissions
actually reach the admin UI, and locking down the organization owner as a
protected member. See `settings-module-architecture.md` and
`teams_implementation.md` for the original design this corrects, and
`docs/modules/roles-permissions-team/` for the module docs kept in sync with
the owner-protection work below.

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

## Follow-up fixes surfaced by smoke-testing

Testing the above against the real app surfaced three more issues, all
now fixed.

### `cinema-hall-api` — `server.js` (folded into `50b1feb`)

Adding `X-Org-Id` to the frontend interceptors (above) had no matching
backend change: `Access-Control-Allow-Headers` still only listed
`Content-Type, Authorization, X-Hall-Id`, so any request carrying both
headers failed CORS preflight with no useful error beyond "CORS error" in
the browser. Fixed by adding `X-Org-Id` to the allow-list.

### `cinema-hall-admin` — `fa801d3`

**fix: correct member count property in RolesPermissionsPage**

`GET /api/roles` has always returned each role's member count as
`member_count` (snake_case, straight off the SQL alias). The Roles &
Permissions page read `role.memberCount || role.membersCount` — neither key
exists on the response — so every role card showed **0 members** regardless
of actual membership. Pre-existing bug, unrelated to the tenant-integrity
work; just surfaced by using the page during smoke-testing. One-line fix in
`src/pages/settings/RolesPermissionsPage.jsx`; documented in
[`modules/roles-permissions-team/frontend.md`](modules/roles-permissions-team/frontend.md).

### `cinema-hall-api` — `c35886b`, `cinema-hall-admin` — `2f9bbeb`

**feat: Add checks to prevent modification or removal of organization owner**
**feat: enhance MemberDetailDrawer with owner role restrictions and UI improvements**

Manual testing of Team Management surfaced that the org owner (the admin in
`organizations.owner_id`) could have their role changed, be suspended, have
their hall access edited, or be removed entirely through the same UI as any
other member — any of which either locks the owner out of their own org or
leaves it ownerless. Fixed with a server-side guard
(`assertNotOrgOwner` in `team.service.js`, returning `403
CANNOT_MODIFY_OWNER` / `403 CANNOT_REMOVE_OWNER`) enforced on
`updateMember`, `removeMember`, `assignHalls`, and `removeHallAssignment` —
plus a matching UI lock in `MemberDetailDrawer.jsx` (disabled controls, a
banner explaining why, hall-access editing hidden). Full detail in
[`modules/roles-permissions-team/workflows.md`](modules/roles-permissions-team/workflows.md#10-owner-protection-guard),
[`backend.md`](modules/roles-permissions-team/backend.md), and
[`components.md`](modules/roles-permissions-team/components.md).

Note there is currently no "transfer ownership" flow — the guard is
correctly restrictive, but there is also no supported way to change who
holds `organizations.owner_id` short of a direct DB update. Tracked as a
known follow-up below.

---

## Deployment

### Local (`cinema_hall_db`)

1. Ran `migration_phase4_tenant_integrity.sql` via pgAdmin — succeeded clean,
   re-verified read-only afterward (all constraints, the partial unique
   index, and zero cross-org violations confirmed).
2. Found one pre-existing, unrelated data issue: an org ("Test's Cinema",
   owned by a stale test account) had **zero roles seeded at all**, so the
   migration's owner-membership backfill (which needs a matching `owner`
   role to insert against) silently skipped it. Fixed by re-running
   `docs/db_setup.sql` in full — its seeding sections are idempotent
   (`WHERE NOT EXISTS` guarded) so this only filled in what was missing for
   that one org and no-op'd everywhere else.

### Neon (production)

1. Ran the same migration in the Neon SQL Editor. It got through steps 1–6
   cleanly, then failed at the `hall_assignments_hall_same_org_fkey`
   constraint — real cross-org data existed in production: one staff member
   (`org_member_id 116a83e9-...`, org "Duraimurugan H's Cinema") held
   `full`-scope `hall_assignments` into **two other, unrelated
   organizations'** halls ("Ram Muthuram's Cinema" and "Pss Multiplex's
   Cinema"). This is exactly the class of bug the migration exists to close.
2. Because the migration runs inside an explicit `BEGIN...COMMIT`, the
   failure rolled back cleanly — nothing was written.
3. Diagnosed the two offending rows via a read-only join query, confirmed
   they were stale/invalid cross-tenant grants (not a legitimate shared
   business relationship), and removed them with a DELETE scoped to just
   those two `hall_assignments.id` values.
4. Re-ran the full migration — completed cleanly (`COMMIT`, 20 statements).
   Re-verified read-only: all 7 named constraints present, the partial
   unique index present, `cinema_hall.admin_id` confirmed `SET NULL` on
   delete, zero remaining cross-org violations of either kind, and — unlike
   local — no orgs missing an owner membership, so no `db_setup.sql`
   re-run was needed on Neon.
5. Smoke-tested the deployed admin app (`cinema-hall-admin.vercel.app`)
   against the migrated Neon database post-deploy: login, org context
   resolution, and a data-heavy page all confirmed working with no CORS or
   500 errors.

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
logging; Postgres RLS as defense in depth; a dedicated "transfer ownership"
flow (currently `organizations.owner_id` can only be changed via direct DB
access, which is also the only way to un-stick a member the owner-protection
guard now correctly refuses to modify).
