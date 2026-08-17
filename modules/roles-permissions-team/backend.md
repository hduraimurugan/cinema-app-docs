# Backend — Roles, Permissions & Team Management

## Current Enforcement Notes

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
| `listRoles` | `GET /api/roles` | `roles.read` | Returns all roles for the admin's org, each with its permissions array |
| `createRole` | `POST /api/roles` | `roles.manage` | Creates a role. Accepts `label`, `description`, and optional `permissionKeys` array or `cloneFrom` role ID |
| `getRole` | `GET /api/roles/:id` | `roles.read` | Returns a single role with its permissions |
| `updateRole` | `PATCH /api/roles/:id` | `roles.manage` | Updates label, description, and replaces the entire permission set. Increments `permissions_version` |
| `deleteRole` | `DELETE /api/roles/:id` | `roles.manage` | Deletes a role. Blocks deletion if `is_system` is true or if members are currently assigned |
| `cloneRole` | `POST /api/roles/:id/clone` | `roles.manage` | Copies permissions from the source role into a newly created role |

## Routes

### roles.routes.js
**Path:** `routes/roles.routes.js`

All routes are protected by `verifyCinemaAdminAccessToken` middleware:

| Method | Path | Permission | Handler |
|---|---|---|---|
| GET | `/api/roles` | `roles.read` | listRoles |
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
- Calls `teamService.loadAdminPermissions(adminId, orgId)` to resolve the admin's effective permission set.
- Returns `403` if the permission key is not present.
- `resolveOrgId(adminId)` — Helper that resolves the org ID from the admin's active membership.

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
| `getOrgRoles(orgId)` | Returns all roles for the org, each with its associated permissions and `member_count` |

**`assertNotOrgOwner(orgId, memberId, code, action)`** — internal helper all four
guarded functions call. Queries whether `organization_members.admin_id = organizations.owner_id`
for the given member; if so, throws a `TeamServiceError` with the given `code`
(`CANNOT_MODIFY_OWNER` or `CANNOT_REMOVE_OWNER`). This is enforced server-side —
not just hidden in the UI — so the rule holds even if a client calls the API directly.

**`TeamServiceError`** — a typed `Error` subclass carrying a machine-readable
`code`, so `team.Controller.js` can map failures to the right HTTP status instead
of every validation failure becoming a generic `500`.
