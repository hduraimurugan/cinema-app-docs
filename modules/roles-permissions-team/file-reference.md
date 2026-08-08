# File Reference — Roles, Permissions & Team Management

## Backend

| File | Lines | Description |
|---|---|---|
| `controllers/roles.Controller.js` | ~180 | Role CRUD controller: list, create, get, update, delete, clone |
| `routes/roles.routes.js` | ~40 | Route definitions with permission middleware |
| `routes/team.routes.js` | ~20 | Team member routes (list, invite, create, get, update, remove, hall assignment) |
| `controllers/team.Controller.js` | ~215 | Thin controller layer + ERROR_STATUS/handleServiceError mapping |
| `services/team.service.js` | ~500 | Core service: member CRUD, hall assignment, invite/accept, getOrgRoles, and the assertNotOrgOwner/assertRoleInOrg/assertHallsInOrg guards |
| `middleware/requirePermission.js` | ~160 | Permission-check middleware factory + resolveOrgId + permissionsVersion staleness check |

## Frontend

| File | Lines | Description |
|---|---|---|
| `src/pages/settings/RolesPermissionsPage.jsx` | ~120 | Role CRUD page with permission matrix |
| `src/pages/settings/TeamManagementPage.jsx` | ~250 | Team member list and management page |
| `src/components/settings/CreateRoleDialog.jsx` | ~120 | Dialog for creating/cloning roles |
| `src/components/settings/PermissionMatrixTable.jsx` | ~150 | Visual permission matrix (resource x action grid) |
| `src/components/settings/AddMemberDialog.jsx` | ~100 | Dialog for adding existing users to org |
| `src/components/settings/MemberDetailDrawer.jsx` | ~330 | Slide-out drawer with member details, role/status/hall management, and the owner-protection UI lock |
| `src/components/settings/TeamInviteDialog.jsx` | ~130 | Dialog for inviting new members by email |
| `src/services/settings/teamService.js` | ~80 | API service functions for roles and team |
| `src/context/PermissionContext.jsx` | ~60 | React context providing `can()` function globally |

## Database Migrations

| File | Lines | Description |
|---|---|---|
| `migrations/XXXXXX_create_roles.js` | ~40 | Creates `roles` table with indexes |
| `migrations/XXXXXX_create_permissions.js` | ~35 | Creates `permissions` table |
| `migrations/XXXXXX_create_role_permissions.js` | ~30 | Creates `role_permissions` junction table |
| `migrations/XXXXXX_create_organization_members.js` | ~45 | Creates `organization_members` table |
| `migrations/XXXXXX_create_hall_assignments.js` | ~30 | Creates `hall_assignments` table |
| `migrations/XXXXXX_create_team_invites.js` | ~40 | Creates `team_invites` table |
| `migrations/XXXXXX_seed_system_roles.js` | ~50 | Seeds the 8 system roles |
| `migrations/XXXXXX_seed_permissions.js` | ~80 | Seeds all available permission keys |

## Configuration

| File | Description |
|---|---|
| `.env` — `INVITE_EXPIRY_HOURS` | Configurable invite expiry (default 72 hours) |
