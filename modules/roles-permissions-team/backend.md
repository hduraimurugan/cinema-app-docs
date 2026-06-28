# Backend — Roles, Permissions & Team Management

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

| Method | Path | Description |
|---|---|---|
| GET | `/api/team/members` | List org members |
| POST | `/api/team/invite` | Send team invite |
| GET | `/api/team/invites` | List pending invites |
| DELETE | `/api/team/members/:id` | Remove member |
| PATCH | `/api/team/members/:id/role` | Change member role |
| PATCH | `/api/team/members/:id/status` | Suspend/activate member |

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
| `loadAdminPermissions(adminId, orgId)` | Returns a `Set` of resolved permission keys for the given admin within the org |
| `getOrgRoles(orgId)` | Returns all roles for the org, each with its associated permissions |
| `validateInviteToken(token)` | Validates a team invite token. Returns `{ email, name, orgName, invitedBy, expired }` |
| `acceptInvite(token, newPassword)` | Accepts a pending invite, creates the admin account, and activates the membership |
