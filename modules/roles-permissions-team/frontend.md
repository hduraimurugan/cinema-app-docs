# Frontend — Roles, Permissions & Team Management

## Current Permission UI

- `src/config/pagePermissions.js` is the single page-to-permission catalog used by routes, sidebar navigation, settings navigation, and the permission editor.
- `RolesPermissionsPage` shows `member_count` and `permission_count`, scrolls to the selected role editor, and renders the Owner role as read-only.
- `PermissionMatrixTable` supports page-level View/Create/Edit/Delete actions, extra actions, advanced permissions, reset, dirty state, and save callbacks.
- `SettingsLayout` filters every settings section by its read permission and redirects `/settings` to the first accessible section.
- Unsaved settings changes are represented by an amber dot and an `unsaved` label on hover.

## Pages

### RolesPermissionsPage
**Path:** `src/pages/settings/RolesPermissionsPage.jsx`

Role CRUD with an interactive permission matrix. Displayed under Settings > Roles & Permissions.

- Lists all organization roles with their permission sets.
- Each role card shows the role's member count via the `member_count` field returned by `GET /api/roles` (falls back to `0` when absent).
- Supports creating, editing, cloning, and deleting roles.
- System roles (`is_system`) show a lock icon and cannot be deleted.
- Permission matrix displays all resources as rows and actions as columns, with checkboxes to toggle.

### TeamManagementPage
**Path:** `src/pages/settings/TeamManagementPage.jsx`

Team member list and management. Displayed under Settings > Team.

- Lists all members of the current organization with status badges (active/suspended/invited).
- Supports inviting new members, changing roles, suspending/activating members, and removing members.
- Shows hall assignments for each member.

## PermissionContext

**Path:** `src/context/PermissionContext.jsx`

A React context that provides a `can(permissionKey)` function to every component in the admin tree.

```jsx
const { can } = usePermissions()
if (can('roles.manage')) {
  // render "Create Role" button
}
```

Used by `AdminProtectedRoute` for route-level permission gating. Components use it for fine-grained UI toggling.

## Services

**Path:** `src/services/settings/teamService.js`

| Function | Description |
|---|---|
| `getMembers()` | Fetch all org members |
| `inviteMember(email, name, roleId)` | Send team invite |
| `removeMember(id)` | Remove member from org |
| `updateRole(memberId, roleId)` | Change member's role |
| `updateStatus(memberId, status)` | Suspend or activate member |
| `getRoles()` | Fetch all org roles with permissions |
| `createRole(data)` | Create new role |
| `updateRole(id, data)` | Update role label/permissions |
| `deleteRole(id)` | Delete role |
| `getPermissions()` | Fetch available permission keys |

## Component Tree

```
RolesPermissionsPage
├── CreateRoleDialog
└── PermissionMatrixTable

TeamManagementPage
├── AddMemberDialog
├── MemberDetailDrawer
└── TeamInviteDialog
```
