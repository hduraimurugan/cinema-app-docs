# Phase 2: Team Management & RBAC Implementation Plan

**Status:** Implementation Complete · **Grounded in:** cinema-hall-api (PostgreSQL/Express), cinema-hall-admin (React 19/shadcn/ui) · **Merged approach:** Architecture doc RBAC model + user's share-link teams concept

---

## 1. Database Schema (5 new tables)

### 1.1 `roles`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | `gen_random_uuid()` |
| `org_id` | UUID FK → organizations(id) | NOT NULL, ON DELETE CASCADE |
| `key` | VARCHAR(50) | Unique per org, e.g. `'owner'`, `'manager'`, `'sales'` |
| `label` | VARCHAR(100) | Human-readable, e.g. `"Sales Staff"` |
| `description` | TEXT | |
| `is_system` | BOOLEAN | DEFAULT FALSE — system roles cannot be deleted or key-changed |
| `permissions_version` | INTEGER | DEFAULT 1 — bumped on change to invalidate JWT cache |
| `created_at` | TIMESTAMPTZ | |
| `updated_at` | TIMESTAMPTZ | |

**Seeded system roles:** owner, admin, manager, sales, finance, marketing, ticket_operator, auditor

### 1.2 `permissions`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `key` | VARCHAR(100) UNIQUE | e.g. `'movies.create'`, `'shows.read'` |
| `label` | VARCHAR(200) | |
| `resource` | VARCHAR(50) | Grouping: movies, shows, screens, bookings, refunds, offers, ads, customers, payment, settings, team, roles, audit, analytics, dashboard, verify-ticket |

### 1.3 `role_permissions`
| Column | Type | Notes |
|---|---|---|
| `role_id` | UUID FK → roles(id) ON DELETE CASCADE | |
| `permission_id` | UUID FK → permissions(id) ON DELETE CASCADE | |
| PRIMARY KEY | (role_id, permission_id) | |

### 1.4 `organization_members`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `org_id` | UUID FK → organizations(id) ON DELETE CASCADE | |
| `admin_id` | UUID FK → cinema_admin_user(id) ON DELETE CASCADE | |
| `role_id` | UUID FK → roles(id) | NOT NULL |
| `status` | VARCHAR(20) | `'invited'`, `'active'`, `'suspended'`, `'removed'` — DEFAULT 'active' |
| `invited_by` | UUID FK → cinema_admin_user(id) | Who sent the invite |
| `invited_at` | TIMESTAMPTZ | |
| `joined_at` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | |
| UNIQUE | (org_id, admin_id) | Also INDEX on admin_id |

### 1.5 `hall_assignments`
| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | |
| `org_member_id` | UUID FK → organization_members(id) ON DELETE CASCADE | |
| `hall_id` | UUID FK → cinema_hall(id) ON DELETE CASCADE | |
| `scope` | VARCHAR(20) | `'full'`, `'read_only'`, `'limited'` — DEFAULT 'full' |
| `assigned_by` | UUID FK → cinema_admin_user(id) | |
| `created_at` | TIMESTAMPTZ | |
| UNIQUE | (org_member_id, hall_id) | |

### 1.6 Schema changes to `cinema_admin_user`
- ALTER role CHECK to allow `'staff'` as new value
- INDEX on email (already exists?)

### 1.7 Backfill
- All existing `cinema_admin_user` with `role IN ('superAdmin', 'admin')` → `organization_members` with `owner` role via `organizations.owner_id`

---

## 2. RBAC Model

### 2.1 Roles and permission mapping

| Role | Key permissions | Maps from share link |
|---|---|---|
| **owner** | ALL permissions + team.manage, roles.manage, org.delete | Existing admin/superAdmin |
| **admin** | All except org.delete, roles.manage, billing.manage | — |
| **manager** | shows.*, screens.*, bookings.*, refunds.*, movies.read/update, settings.hall.read/update, customers.read, dashboard.view | management team |
| **sales** | bookings.read, bookings.cancel, refunds.create/read, dashboard.view, customers.read | sales team |
| **finance** | bookings.read, payment.read, refunds.*, analytics.view, dashboard.view, customers.read | — |
| **marketing** | offers.*, ads.*, movies.read, customers.read, analytics.view, dashboard.view | ads_management + offers_management |
| **ticket_operator** | shows.read, bookings.read, bookings.verify, verify-ticket.use, customers.read, dashboard.view | — |
| **auditor** | All *.read permissions, audit.view, dashboard.view, NO writes | — |

### 2.2 Permission catalog

```
movies.create | movies.read | movies.update | movies.delete
shows.create  | shows.read  | shows.update  | shows.delete  | shows.cancel
screens.create | screens.read | screens.update | screens.delete
bookings.read | bookings.verify | bookings.cancel | bookings.modify
refunds.create | refunds.read | refunds.settle
offers.create | offers.read | offers.update | offers.delete
ads.create | ads.read | ads.update | ads.delete
customers.read | customers.manage
payment.read | payment.manage | payment.settle
settings.org.read | settings.org.update
settings.hall.read | settings.hall.update
settings.user.read | settings.user.update
settings.advanced.manage
team.manage | team.invite | team.revoke
roles.manage | roles.read
audit.view
analytics.view | analytics.manage
dashboard.view
verify-ticket.use
integrations.manage
billing.manage
org.delete
```

### 2.3 Hall scope enforcement

- **`full`** — all role permissions apply normally
- **`read_only`** — strips all `*.create`, `*.update`, `*.delete`, `*.cancel`, `*.settle`, `*.manage` permissions
- **`limited`** — (future, not needed now)

### 2.4 Permission cache

- LRU cache (Map, max 500 entries, 5 min TTL)
- Keyed by `adminId-orgId`
- Invalidated by `permissionsVersion` in JWT (compare cached vs. token version)
- On miss: query `role_permissions` → `role_permissions_view` via org_members → roles → permissions

---

## 3. Backend API

### 3.1 New middleware: `requirePermission.js`

```js
// Usage: router.get("/shows", verifyCinemaAdminAccessToken, requirePermission('shows.read'), handler)
// Checks: 1) JWT valid (via verifyCinemaAdminAccessToken), 2) user has org membership,
//         3) user's role includes the required permission + hall scope check
// On fail: 403 { error: "Permission denied", required: 'shows.read' }
```

Cache layer:
- `loadPermissions(adminId, orgId)` → Set of permission keys
- Check `permissionsVersion` from JWT; if token version > cached version, evict and reload
- Apply hall scope filter if `req.currentHallId` is set

### 3.2 Team routes (`/api/team`)
All protected by `verifyCinemaAdminAccessToken` + `requirePermission('team.manage')`:

```
GET    /api/team                    → listOrgMembers(req, res)
POST   /api/team/invite             → inviteMember(req, res)    // email invite
POST   /api/team/members            → createMember(req, res)    // direct create
GET    /api/team/members/:id        → getMember(req, res)
PATCH  /api/team/members/:id        → updateMember(req, res)
DELETE /api/team/members/:id        → removeMember(req, res)
GET    /api/team/members/:id/halls  → getMemberHalls(req, res)
POST   /api/team/members/:id/halls  → assignHalls(req, res)     // [{ hallId, scope }]
DELETE /api/team/members/:id/halls/:hallId → removeHallAssignment(req, res)
```

**Invite flow:**
1. `POST /api/team/invite` — creates `organization_members` with `status: 'invited'`, generates token, sends email
2. `GET /api/team/accept-invite?token=xxx` — validates token (public)
3. `POST /api/team/accept-invite` — sets password, activates membership

**Direct create flow:**
1. `POST /api/team/members` — creates `cinema_admin_user` with `role: 'staff'`, creates `organization_members` with `status: 'active'`
2. Optionally assigns halls
3. Returns generated password (or allows setting a known password)

### 3.3 Roles routes (`/api/roles`)
All protected by `verifyCinemaAdminAccessToken` + `requirePermission('roles.manage')`:

```
GET    /api/roles               → listRoles(req, res)
POST   /api/roles               → createRole(req, res)
GET    /api/roles/:id           → getRole(req, res)
PATCH  /api/roles/:id           → updateRole(req, res)
DELETE /api/roles/:id           → deleteRole(req, res)
POST   /api/roles/:id/clone     → cloneRole(req, res)
```

### 3.4 JWT extension

**Current payload:** `{ id, email, name, role }`
**New payload:** `{ id, email, name, role, orgId, roleKey, permissionsVersion }`

- `role` stays for backward compat (`verifySuperAdmin` checks `role === 'superAdmin'`)
- `orgId` is resolved at login via `resolveOrgId(admin.id)`
- `roleKey` is the admin's RBAC role key (owner, manager, etc.)
- `permissionsVersion` is `roles.permissions_version` for cache invalidation

**Changes in `auth.Controller.js`:**
- `loginCinemaAdmin`: after login, query `organization_members` + `roles` to get `orgId`, `roleKey`, `permissionsVersion`
- `getCinemaAdminMe`: return `orgId`, `roleKey`, `permissions` (full set), `permissionsVersion`
- `refreshCinemaAdminToken`: reissue with same JWT claims

### 3.5 Accept invite endpoint

```
GET  /api/auth/accept-invite?token=xxx  → validateInviteToken (public)
POST /api/auth/accept-invite            → acceptInvite (public)
```

Uses `admin_verification_tokens` table (reuse existing) with a specific token type.

---

## 4. Frontend

### 4.1 `PermissionContext.jsx`

```jsx
const PermissionContext = createContext();

// Usage: const { can, roleKey, permissions } = usePermissions();
// can('shows.create') → true/false
// canView('shows') → true/false (checks shows.read + hall scope)
// canEdit('shows') → true/false (checks shows.create/update + hall scope)
// roleKey → 'owner', 'manager', 'sales', etc.
// permissions → ['shows.read', 'bookings.read', ...]
```

Loaded from `GET /api/auth/me` → `res.permissions` array.
Stored in `AuthContext` alongside user data.

### 4.2 `TeamManagementPage.jsx`
Route: `/settings/team`

**Layout:**
- Page header: "Team Management" + scope badge (Organization)
- Search bar + "Invite Member" + "Add Member" buttons
- Table: Avatar + Name, Email, Role badge, Status badge, Halls count, Last active, Actions
- Pagination

**Invite Member Dialog:**
- Email field
- Role dropdown (populated from GET /api/roles)
- Hall assignment: multi-select halls with scope per hall (full/read_only)
- "Send Invite" button

**Add Member Dialog:**
- Name, Email, Password, Phone fields
- Role dropdown
- Hall assignments
- "Create Member" button

**Member Detail Drawer:**
- Profile info (read-only)
- Role selector (with confirmation)
- Status toggle (active/suspended)
- Halls section: list assigned halls with scope, edit scope, remove
- "Remove from Organization" button (with confirmation)

### 4.3 `RolesPermissionsPage.jsx`
Route: `/settings/roles`

**Layout:**
- Page header: "Roles & Permissions" + scope badge (Organization)
- Role cards: each shows name, description, member count, is_system badge
- "Create Custom Role" button
- Click role → permission matrix table

**Permission Matrix Table:**
- Grouped by resource section (Movies, Shows, Screens, Bookings, etc.)
- Each row: permission label + toggle switch
- Section-level toggle (select all/none)
- Save/Cancel buttons

**Create Custom Role Dialog:**
- Role key (auto-slugified)
- Label, description
- Clone from existing role dropdown
- Permission matrix
- Save button

### 4.4 Sidebar permission filtering

Sidebar items gain a `permission` field:
```js
const navItems = [
  { title: "Dashboard", url: "/", icon: Home, permission: "dashboard.view" },
  { title: "Screens", url: "/screens", icon: Monitor, permission: "screens.read" },
  { title: "Showtimes", url: "/shows", icon: Calendar, permission: "shows.read" },
  // ... etc
]
```

Filter logic: `!item.permission || can(item.permission)`
- Items with no `permission` field visible to all (e.g., Settings, Profile)
- Super admin bypass: `isSuperAdmin || !item.permission || can(item.permission)`

### 4.5 Settings sidebar additions

New sections in `SettingsLayout` sidebar after "Organization" group:

```js
const managementSections = [
  { path: "team", label: "Team", icon: Users, scope: "org" },
  { path: "roles", label: "Roles", icon: Shield, scope: "org" },
];
```

These require `team.manage` and `roles.read` permissions respectively.

### 4.6 Route guard updates

`AdminProtectedRoute.jsx` → **replaced by** `PermissionGuard.jsx`:
```jsx
<PermissionGuard permission="ads.read">
  <AdsManagement />
</PermissionGuard>
```

Current super-admin routes become permission-gated:
- `/ads` → `ads.read`
- `/offers` → `offers.read`
- `/customers` → `customers.read`
- `/admins` → `team.manage` (now part of Team Management)

---

## 5. Implementation Order

| Step | What | Backend files | Frontend files |
|---|---|---|---|
| **1** | DB migration | `migration_phase2_rbac.sql` | — |
| **2** | `requirePermission` middleware | `middleware/requirePermission.js` | — |
| **3** | Team service | `services/team.service.js` | — |
| **4** | Team controller + routes | `controllers/team.Controller.js`, `routes/team.routes.js` | — |
| **5** | Roles controller + routes | `controllers/roles.Controller.js`, `routes/roles.routes.js` | — |
| **6** | JWT extension + auth changes | `utils/generateTokenAndSetCookie.js`, `controllers/auth.Controller.js`, `routes/auth.routes.js` | — |
| **7** | PermissionContext | — | `src/context/PermissionContext.jsx`, `src/context/AuthContext.jsx` |
| **8** | TeamManagementPage + dialogs | — | `src/pages/settings/TeamManagementPage.jsx`, `src/components/settings/TeamInviteDialog.jsx`, `src/components/settings/MemberDetailDrawer.jsx`, `src/services/settings/teamService.js` |
| **9** | RolesPermissionsPage + Pmtx | — | `src/pages/settings/RolesPermissionsPage.jsx`, `src/components/settings/PermissionMatrixTable.jsx` |
| **10** | Sidebar + SettingsLayout + routes | — | `src/components/AppSidebar.jsx`, `src/pages/settings/SettingsLayout.jsx`, `src/App.jsx`, `src/routes/AdminProtectedRoutes.jsx` |

---

## 6. Key Design Decisions

1. **`organizations.name` stays as source of truth** — no org_name in settings JSONB
2. **`cinema_admin_user.role` column kept** — `'staff'` added as new value; `verifySuperAdmin` stays for backward compat
3. **Staff in `cinema_admin_user`** — all users in one table; `organization_members` links to org
4. **Merge approach** — architecture doc's RBAC model with user's 4 teams mapped to roles
5. **`hall_assignments.scope` replaces `can_view`/`can_edit`** — `full` = can_view+can_edit, `read_only` = can_view only
6. **Both invite flows** — email invite + direct create with password
7. **LRU permission cache** — 5 min TTL, invalidated by `permissionsVersion`
8. **Existing `verifySuperAdmin` middleware kept** — new `requirePermission` used on new routes; existing routes migrated incrementally
9. **`cinema_hall.admin_id` stays** — hall ownership unchanged; `hall_assignments` adds additional members

---

## 7. Bug Fixes (post-implementation)

### 7.1 SQL reserved word
- `desc` renamed to `description` in migration (`column desc Text` → `column description Text`)

### 7.2 requirePermission: staff org resolution
- `resolveOrgId` added fallback to query `organization_members` for staff users (not just `organizations.owner_id`)

### 7.3 Role dropdowns not populating
- `useEffect` guard `if (!roles)` changed to `if (!roles || roles.length === 0)` in `TeamInviteDialog`, `AddMemberDialog`, `MemberDetailDrawer`

### 7.4 Backend GET /api/roles permission
- Changed from `requirePermission('roles.manage')` to `requirePermission('roles.read')` (listing is a read operation)

### 7.5 Staff login redirecting to onboarding
- `HallGuard.jsx`: staff (`role === 'staff'`) bypass the guard entirely
- `App.jsx`: onboarding route redirects staff to `/`

### 7.6 Staff hall access chain (3 fixes)
- `getMyHalls` in `halls.Controller.js`: added `UNION` to also return halls from `hall_assignments`
- `requireActiveHall` in `verifyCinemaAdmin.js`: falls back to `hall_assignments` check when user has no owned halls
- `verifyCinemaHall` in `verifyCinemaAdmin.js`: includes `hall_assignments` via `LEFT JOIN` with JS dedup

### 7.7 Frontend-backend field name alignment
| Frontend (before) | Backend returns | Fix |
|---|---|---|
| `member.roleId` | `role_id`, `role_label`, `role_key` | `getRoleName(member)` reads `member.role_label` directly |
| `member.hallsCount` | `hall_count` | `member.hall_count` |
| `memberData.roleId` | `role_id` | `memberData.member?.role_id` |
| `mh.hallId \|\| mh.id` | `hall_id` (hall UUID), `id` (assignment UUID) | `mh.hall_id` |
| `hallRef.hallId` | `hall_id`, `hall_name` | `hallRef.hall_id`, `hallRef.hall_name` |
| `JSON.stringify(halls)` (bare array) | `req.body.halls` | `JSON.stringify({ halls })` wrapper |
