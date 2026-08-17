# API Reference — Roles, Permissions & Team Management

Base path: `/api`

All endpoints require `verifyCinemaAdminAccessToken` middleware (Bearer token in `Authorization` header).

---

## Roles

### `GET /api/roles`

List all roles for the current organization.

**Permission:** `roles.read`

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "key": "admin",
    "label": "Admin",
    "description": "...",
    "is_system": true,
    "permissions_version": 3,
    "permissions": [
      { "id": "uuid", "key": "bookings.read", "label": "View Bookings", "resource": "bookings" }
    ],
    "member_count": 5,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
]
```

---

### `POST /api/roles`

Create a new role.

**Permission:** `roles.manage`

**Request Body:**

```json
{
  "key": "support_agent",
  "label": "Support Agent",
  "description": "Handles customer inquiries",
  "permissionKeys": ["bookings.read", "customers.read"],
  "cloneFrom": "uuid-or-role-key"  // optional; copies permissions from an existing role
}
```

`key` and `label` are both required. `cloneFrom` accepts either the source role's **id or
its key**.

**Response `201`:** Created role object with permissions.

**Errors:**
- `409` if a role with the same key already exists in this org
- `400` if `permissionKeys` contains a key absent from the catalog (the response lists them)
- `403` if it contains a permission the caller does not hold

---

### `GET /api/roles/permissions`

The global permission catalog — every key the system knows about. The admin UI renders its
matrix from this response, so its options can never drift from the schema.

**Permission:** `roles.read`

> Declared **before** `/api/roles/:id` in `roles.routes.js`; otherwise Express matches
> `permissions` as a role id.

**Response `200`:**

```json
{
  "permissions": [
    { "id": "uuid", "key": "bookings.read", "label": "Read Bookings", "resource": "bookings" }
  ]
}
```

55 rows as of `migration_phase5_page_permissions.sql`.

---

### `GET /api/roles/:id`

Get a single role.

**Permission:** `roles.read`

**Response `200`:** Role object with permissions array.

---

### `PATCH /api/roles/:id`

Update a role's label, description, and permissions.

**Permission:** `roles.manage`

**Request Body:**

```json
{
  "label": "Senior Support Agent",
  "description": "Handles escalated inquiries",
  "permissionKeys": ["bookings.read", "bookings.modify", "customers.read"]
}
```

**Note:** The `permissionKeys` array **replaces** the entire existing permission set, and
increments `permissions_version` — which invalidates the access tokens of everyone holding
the role. Send `permissionKeys`, not `permissions`; the latter is ignored.

**Response `200`:** Updated role object.

**Errors:**

| Status | When |
|---|---|
| `403` | Editing permissions on the `owner` role — it always has full access. Renaming it is still allowed |
| `403` | `permissionKeys` contains a permission the caller does not hold (message lists them). `superAdmin` bypasses |
| `400` | `permissionKeys` contains a key absent from the catalog (message lists them) — keys are never silently dropped |
| `404` | Role not found in the caller's org |

---

### `DELETE /api/roles/:id`

Delete a role.

**Permission:** `roles.manage`

**Errors:**
- `400` if `is_system` is true
- `400` if one or more active members are assigned this role

**Response `200`:** `{ "message": "Role deleted successfully" }`

---

### `POST /api/roles/:id/clone`

Clone a role's permissions into a new role.

**Permission:** `roles.manage`

**Request Body:**

```json
{
  "label": "Auditor Clone",
  "description": "Read-only (copied from auditor)"
}
```

**Response `201`:** New role object with identical permissions.

---

## Team Members

Base path for this section: `/api/team`. All routes additionally require the
`team.manage` permission (`requirePermission('team.manage')`, applied router-wide
in `team.routes.js`), on top of the module-wide `verifyCinemaAdminAccessToken`.

### `GET /api/team`

List all members of the current organization. Supports `?search=`, `?page=`, `?limit=` query params.

**Response `200`:**

```json
{
  "members": [
    {
      "id": "uuid",
      "admin_id": "uuid",
      "name": "John Doe",
      "email": "john@example.com",
      "status": "active",
      "role_id": "uuid",
      "role_key": "admin",
      "role_label": "Admin",
      "is_owner": false,
      "hall_count": 2,
      "invited_by": "uuid",
      "invited_at": "2025-01-01T00:00:00Z",
      "joined_at": "2025-01-02T00:00:00Z"
    }
  ],
  "total": 4
}
```

`is_owner` is computed by comparing `organization_members.admin_id` to
`organizations.owner_id` — it is not a stored column. It gates the owner
protections described in [workflows.md](workflows.md).

---

### `POST /api/team/invite`

Send a team invitation to an email that may or may not already have an account.

**Request Body:**

```json
{
  "email": "newmember@example.com",
  "roleId": "uuid",
  "halls": [{ "hallId": "uuid", "scope": "full" }]
}
```

**Response `201`:** `{ "message": "Invite sent successfully", "token": "raw-token", "memberId": "uuid", "email": "..." }`

**Errors:** `400 ROLE_NOT_IN_ORG` / `400 HALL_NOT_IN_ORG` if `roleId`/`halls` don't belong to this org; `409 ALREADY_MEMBER` if the invitee already has a live (non-removed) membership.

---

### `POST /api/team/members`

Create a member directly (sets a password immediately, skips the invite-email step).

**Request Body:** `{ "name", "email", "password", "phone"?, "roleId", "halls"? }`

**Response `201`:** `{ "message": "Member created successfully", "member": { "memberId", "adminId", "name", "email" } }`

**Errors:** same as `POST /api/team/invite`.

---

### `GET /api/team/members/:id`

Fetch a single member's detail, including `is_owner`.

**Response `200`:** `{ "member": { ...same shape as the list row, plus role_description... } }`

---

### `PATCH /api/team/members/:id`

Change a member's role and/or status in one call.

**Request Body:**

```json
{
  "roleId": "uuid",
  "status": "suspended"
}
```

Either field is optional; send only what's changing. Valid `status` values: `active`, `suspended`, `removed`.

**Response `200`:** `{ "message": "Member updated successfully", "member": { ... } }`

**Errors:**
- `400 ROLE_NOT_IN_ORG` — `roleId` belongs to a different organization
- `403 CANNOT_MODIFY_OWNER` — the target member is the organization's owner (`organizations.owner_id`). Owners' role and status cannot be changed through this endpoint — transfer ownership first.

---

### `DELETE /api/team/members/:id`

Remove a member from the organization (soft delete — sets `status = 'removed'`, `removed_at = now()`; the row is kept so the member can be re-invited later).

**Response `200`:** `{ "message": "Member removed successfully" }`

**Errors:** `403 CANNOT_REMOVE_OWNER` — the organization owner cannot be removed.

---

### `GET /api/team/members/:id/halls`

List a member's hall assignments (`{ id, hall_id, scope, hall_name, hall_location, created_at }[]`).

---

### `POST /api/team/members/:id/halls`

Grant or update hall access for a member.

**Request Body:** `{ "halls": [{ "hallId": "uuid", "scope": "full" | "read_only" }] }`

**Response `200`:** `{ "message": "Halls assigned successfully", "halls": [...] }`

**Errors:**
- `400 HALL_NOT_IN_ORG` / `400 INVALID_HALL`
- `403 CANNOT_MODIFY_OWNER` — owners already have implicit full access to every hall in their org via `requireActiveHall`'s org-wide-role check, so their individual `hall_assignments` rows cannot be edited here.

---

### `DELETE /api/team/members/:id/halls/:hallId`

Revoke a specific hall assignment.

**Response `200`:** `{ "message": "Hall assignment removed successfully" }`

**Errors:** `403 CANNOT_MODIFY_OWNER` (same reason as above).

---

## Invite Accept (No Auth)

### `POST /api/auth/accept-invite`

Accepts a team invite (public — no auth required, identified by token). Note this lives under `/api/auth`, not `/api/team` — it's handled by `auth.Controller.acceptInvite`, which delegates to `teamService.acceptInvite`.

**Request Body:**

```json
{
  "token": "invite-token-string",
  "newPassword": "secure-password"
}
```

**Response `200`:** `{ "message": "Invite accepted successfully. You can now log in." }`

**Errors:** `400 { code: "INVALID_TOKEN" }`, `400 { code: "TOKEN_EXPIRED" }`.
