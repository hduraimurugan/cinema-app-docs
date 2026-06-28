# Frontend — Roles, Permissions & Team Management

## Pages

### RolesPermissionsPage
**Path:** `src/pages/settings/RolesPermissionsPage.jsx`

Role CRUD with an interactive permission matrix. Displayed under Settings > Roles & Permissions.

- Lists all organization roles with their permission sets.
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
