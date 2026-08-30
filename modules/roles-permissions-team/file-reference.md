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
| `src/components/settings/PermissionMatrixTable.jsx` | ~330 | Page-oriented permission matrix (page rows × View/Create/Edit/Delete columns), driven by `config/pagePermissions.js` reconciled against `GET /api/roles/permissions` |
| `src/config/pagePermissions.js` | ~110 | Single page→permission catalog shared by the sidebar, route guards, settings nav and the matrix |
| `src/components/settings/AddMemberDialog.jsx` | ~230 | Right-side `Sheet` for creating a new org member (name/email/password/phone, role, hall access) — autofill-immune inputs, reset on open |
| `src/components/settings/MemberDetailDrawer.jsx` | ~420 | Slide-out drawer with card-based member details (Profile / Role & Status / Hall Access / Danger Zone) and the owner-protection UI lock |
| `src/components/settings/TeamInviteDialog.jsx` | ~130 | Dialog for inviting new members by email |
| `src/services/settings/teamService.js` | ~80 | API service functions for roles and team |
| `src/context/PermissionContext.jsx` | ~60 | React context providing `can()` function globally |

## Database Migrations

Raw idempotent `.sql` files under `cinema-hall-api/database/`, applied by hand (pgAdmin,
psql, or the Neon SQL editor). There is no JavaScript migration runner.

| File | Description |
|---|---|
| `migration_phase2_rbac.sql` | Creates `roles`, `permissions`, `role_permissions`, `organization_members`, `hall_assignments`; seeds the permission catalog, the 8 system roles and their grants |
| `migration_phase3_onboarding.sql` | Onboarding-related schema |
| `migration_phase4_tenant_integrity.sql` | Composite FK `(role_id, org_id) → roles(id, org_id)`, `removed_at`, and the **partial** unique index `uniq_active_org_member … WHERE status <> 'removed'` |
| `migration_phase5_page_permissions.sql` | Adds `halls.read` / `halls.manage` (catalog → 55 keys) and bumps `permissions_version` |
| `migration_phase6_remove_phantom_orgs.sql` | Guarded cleanup of hall-less orgs owned by platform `staff` |
| `audit_org_ownership.sql` | Read-only ownership audit — run before phase 6 |
| `docs/db_setup.sql` | One-shot fresh-install script containing all of the above |

## Configuration

No module-specific environment variables. Invite expiry (7 days) and the verification-token
expiry (24 hours) are set in code, not configuration.
