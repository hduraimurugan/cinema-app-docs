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
  "label": "Support Agent",
  "description": "Handles customer inquiries",
  "permissionKeys": ["bookings.read", "customers.read"],
  "cloneFrom": "uuid"  // optional; copies permissions from an existing role
}
```

**Response `201`:** Created role object with permissions.

**Errors:** `409` if a role with the same key already exists in this org.

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
  "permissionKeys": ["bookings.read", "bookings.write", "customers.read"]
}
```

**Note:** The `permissionKeys` array **replaces** the entire existing permission set. Increments `permissions_version`.

**Response `200`:** Updated role object.

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

### `GET /api/team/members`

List all members of the current organization.

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "admin_id": "uuid",
    "name": "John Doe",
    "email": "john@example.com",
    "role": { "id": "uuid", "key": "admin", "label": "Admin" },
    "status": "active",
    "halls": [{ "id": "uuid", "name": "Hall A" }],
    "invited_by": "uuid",
    "invited_at": "2025-01-01T00:00:00Z",
    "joined_at": "2025-01-02T00:00:00Z"
  }
]
```

---

### `POST /api/team/invite`

Send a team invitation.

**Request Body:**

```json
{
  "email": "newmember@example.com",
  "name": "New Member",
  "roleId": "uuid"
}
```

**Response `201`:** `{ "message": "Invitation sent", "invite": { ... } }`

---

### `GET /api/team/invites`

List pending invites.

**Response `200`:** Array of invite objects with email, name, role, status, expires_at.

---

### `DELETE /api/team/members/:id`

Remove a member from the organization.

**Response `200`:** `{ "message": "Member removed" }`

---

### `PATCH /api/team/members/:id/role`

Change a member's role.

**Request Body:**

```json
{
  "roleId": "uuid"
}
```

**Response `200`:** Updated member object.

---

### `PATCH /api/team/members/:id/status`

Suspend or activate a member.

**Request Body:**

```json
{
  "status": "suspended"
}
```

Valid values: `active`, `suspended`.

**Response `200`:** Updated member object.

---

## Invite Accept (No Auth)

### `POST /api/team/invite/accept`

Accepts a team invite (no auth required — uses token).

**Request Body:**

```json
{
  "token": "invite-token-string",
  "password": "secure-password"
}
```

**Response `200`:** `{ "message": "Invite accepted", "user": { ... } }`
