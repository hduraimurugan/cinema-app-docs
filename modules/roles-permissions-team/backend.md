# Backend — Roles, Permissions & Team Management

## Current Enforcement Notes

- `requirePermission()` is wired across **all** admin route files — shows, screens, movies, bookings, refunds, payment, dashboard, halls, offers, settings, roles and team. It was previously present only on `roles` and `team`, which made the sidebar's permission filtering cosmetic: a restricted member could call any other endpoint directly. `ads` and `customers` remain `verifySuperAdmin` because those tables are platform-global, with no `org_id`.
- `requirePermission()` resolves the active organization from membership and checks the role's `permissions_version` before loading permissions.
- A stale token returns `401` with `code: "TOKEN_STALE"`; the admin client refreshes and retries the request.
- `requireActiveOrg` validates `X-Org-Id` membership. `requireActiveHall` validates organization membership plus org-wide, creator, or explicit hall access and sets `req.hallScope`.
- Read-only hall assignments may read but cannot use mutation permission keys.
- Role and hall references are checked against the current organization before team writes.
- The organization owner cannot be modified, removed, or assigned individual hall overrides. This is enforced in the service layer, not only in React.
- Removed memberships are timestamped with `removed_at` and may be revived by a later invite.

## Controllers

### roles.Controller.js
**Path:** `controllers/roles.Controller.js`

| Function | Endpoint | Permission | Description |
|---|---|---|---|
| `listRoles` | `GET /api/roles` | `roles.read` | Returns all roles for the admin's org with `member_count` and `permission_count` |
| `listPermissions` | `GET /api/roles/permissions` | `roles.read` | The full global permission catalog (`id`, `key`, `label`, `resource`). The admin UI renders only what this returns, so the editor's options cannot drift from the schema. **Registered before `/:id`** or Express matches it as a role id |
| `createRole` | `POST /api/roles` | `roles.manage` | Creates a role. Accepts `label`, `description`, and optional `permissionKeys` array or `cloneFrom` — which accepts **either a role id or a role key** |
| `getRole` | `GET /api/roles/:id` | `roles.read` | Returns a single role. `permissions` is an array of **objects** (`{ id, key, label, resource }`), not strings |
| `updateRole` | `PATCH /api/roles/:id` | `roles.manage` | Updates label/description and replaces the entire permission set. See guards below |
| `deleteRole` | `DELETE /api/roles/:id` | `roles.manage` | Deletes a role. Blocks deletion if `is_system` is true or if members are currently assigned |
| `cloneRole` | `POST /api/roles/:id/clone` | `roles.manage` | Copies permissions from the source role into a newly created role, subject to the same escalation guard |

### Write guards on `createRole` / `updateRole` / `cloneRole`

| Guard | Behaviour |
|---|---|
| Owner role is immutable | `updateRole` rejects with `403` if `role.key === 'owner'` and `permissionKeys` is supplied. Renaming is still allowed. The owner role is the org's recovery path — editable, it lets an owner strip `roles.manage` from themselves and lock the organization out permanently |
| No privilege escalation | Any key the **caller** does not already hold is rejected with `403`. Applies to explicit grants and to cloning, so copying the owner role is not a free escalation. `superAdmin` bypasses |
| Unknown keys rejected | Keys absent from the catalog return `400` listing them, rather than being silently dropped — a drifted client used to wipe permissions it could not render |
| Version bump | `permissions_version` is incremented whenever the **permission set** changes, not only when the label changes. This is what invalidates the 1-day access tokens of everyone holding the role |
| Cache invalidation | `clearOrgPermissionCache(orgId)` runs after every role write, clearing the 5-minute per-`adminId:orgId` cache for **all** members of the org |

## Routes

### roles.routes.js
**Path:** `routes/roles.routes.js`

All routes are protected by `verifyCinemaAdminAccessToken` middleware:

| Method | Path | Permission | Handler |
|---|---|---|---|
| GET | `/api/roles` | `roles.read` | listRoles |
| GET | `/api/roles/permissions` | `roles.read` | listPermissions |
| GET | `/api/roles/:id` | `roles.read` | getRole |
| POST | `/api/roles` | `roles.manage` | createRole |
| PATCH | `/api/roles/:id` | `roles.manage` | updateRole |
| DELETE | `/api/roles/:id` | `roles.manage` | deleteRole |
| POST | `/api/roles/:id/clone` | `roles.manage` | cloneRole |

### team.routes.js
**Path:** `routes/team.routes.js`

All routes require `verifyCinemaAdminAccessToken` + `requirePermission('team.manage')` (applied router-wide). See [api.md](api.md) for full request/response shapes and error codes.

| Method | Path | Handler |
|---|---|---|
| GET | `/api/team` | listOrgMembers |
| POST | `/api/team/invite` | inviteMember |
| POST | `/api/team/members` | createMember |
| GET | `/api/team/members/:id` | getMember |
| PATCH | `/api/team/members/:id` | updateMember |
| DELETE | `/api/team/members/:id` | removeMember |
| GET | `/api/team/members/:id/halls` | getMemberHalls |
| POST | `/api/team/members/:id/halls` | assignHalls |
| DELETE | `/api/team/members/:id/halls/:hallId` | removeHallAssignment |

### team.Controller.js
**Path:** `controllers/team.Controller.js`

Thin wrapper around `team.service.js` — resolves `orgId` via `resolveOrgId(req.admin.id)`, then delegates. Owns `ERROR_STATUS`, a lookup mapping service-layer error codes to HTTP status:

```js
const ERROR_STATUS = {
  ROLE_NOT_IN_ORG: 400,
  HALL_NOT_IN_ORG: 400,
  INVALID_HALL: 400,
  ALREADY_MEMBER: 409,
  CANNOT_MODIFY_OWNER: 403,
  CANNOT_REMOVE_OWNER: 403,
}
```

`handleServiceError(err, res)` checks `err instanceof TeamServiceError` first, then
falls back to mapping raw Postgres codes (`23505` → `409 ALREADY_MEMBER`, `23503` →
`400 CROSS_ORG_REFERENCE`) as a backstop for anything that slips past the service
layer's own validation.

## Middleware

### requirePermission.js
**Path:** `middleware/requirePermission.js`

```js
router.get('/', requirePermission('roles.read'), listRoles)
```

- `requirePermission(permissionKey)` — Factory that returns Express middleware.
- Calls `teamService.loadAdminPermissions(adminId, orgId)` to resolve the admin's effective permission set (5-minute cache keyed `adminId:orgId`).
- Returns `403 { error: 'Permission denied', required: <key> }` if the permission key is not present.
- `resolveOrgId(adminId)` — Resolves the org from the admin's active membership. Ordering: **an org with halls outranks a hall-less one**, then ownership, then oldest membership. Must stay in step with `resolveOrgContext` in `utils/generateTokenAndSetCookie.js`, which backs login, refresh and `/me` — otherwise the token and `/me` disagree about which org the caller is in.
- `clearPermissionCache(adminId, orgId)` / `clearOrgPermissionCache(orgId)` — invalidate one member, or every member of an org after a role write.

## Service Layer

### team.service.js
**Path:** `services/team.service.js`

| Function | Description |
|---|---|
| `loadAdminPermissions(adminId, orgId)` | Returns a `Set` of resolved permission keys for the given admin within the org (re-exported from `middleware/requirePermission.js`) |
| `getOrgMembers(orgId, { search, page, limit })` | Paginated, searchable member list. Includes `is_owner` and `hall_count` per row |
| `createMember(orgId, createdBy, data)` | Creates the `cinema_admin_user` + `organization_members` rows in one transaction (password set immediately) |
| `inviteMember(orgId, invitedBy, data)` | Creates or reuses a `cinema_admin_user`, inserts/revives an `organization_members` row with `status='invited'`, issues a verification token |
| `validateInviteToken(token)` | Validates a team invite token. Returns `{ email, name, orgName, invitedBy, expired }` |
| `acceptInvite(token, newPassword)` | Accepts a pending invite, sets the password, activates the membership |
| `updateMember(memberId, orgId, updates)` | Changes `roleId` and/or `status`. **Guarded:** rejects with `CANNOT_MODIFY_OWNER` if the target member is `organizations.owner_id` |
| `removeMember(memberId, orgId)` | Soft-deletes a member (`status='removed'`). **Guarded:** rejects with `CANNOT_REMOVE_OWNER` for the owner |
| `getMemberHalls(memberId, orgId)` | Lists a member's `hall_assignments` |
| `assignHalls(memberId, orgId, halls)` | Grants/updates hall access. **Guarded:** rejects with `CANNOT_MODIFY_OWNER` for the owner — owners already have implicit full access via `requireActiveHall`'s org-wide-role check |
| `removeHallAssignment(memberId, orgId, hallId)` | Revokes one hall assignment. Same owner guard as above |
| `getOrgRoles(orgId)` | Returns all roles for the org with `member_count` and `permission_count` |

**`assertNotOrgOwner(orgId, memberId, code, action)`** — internal helper all four
guarded functions call. Queries whether `organization_members.admin_id = organizations.owner_id`
for the given member; if so, throws a `TeamServiceError` with the given `code`
(`CANNOT_MODIFY_OWNER` or `CANNOT_REMOVE_OWNER`). This is enforced server-side —
not just hidden in the UI — so the rule holds even if a client calls the API directly.

**`TeamServiceError`** — a typed `Error` subclass carrying a machine-readable
`code`, so `team.Controller.js` can map failures to the right HTTP status instead
of every validation failure becoming a generic `500`.
