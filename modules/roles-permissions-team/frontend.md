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
- Each role card shows `member_count` and `permission_count` from `GET /api/roles` (both fall back to `0` when absent).
- Role cards are real `<button>` elements — keyboard focusable, with `aria-pressed`. They must not be built from `SettingsCard`, which does not accept an `onClick` prop and silently drops it.
- Supports creating, editing, cloning, and deleting roles.
- System roles (`is_system`) show a `System` badge and cannot be deleted. The `owner` role additionally renders **read-only**, mirroring the `403` the API returns for it.
- The write UI is gated on `can('roles.manage')`; `roles.read` alone reaches the page but sees a disabled editor.
- Permission matrix rows are **pages** (Dashboard, Screens, Showtimes, Settings › Team…), columns are View / Create / Edit / Delete. Ticking a write auto-ticks View; unticking View clears the row. Permission keys the page catalog does not map fall through to an **Advanced** group so a newly seeded key is never uneditable.

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
| `getRoles()` | Fetch all org roles with `member_count` / `permission_count` |
| `getRole(id)` | Fetch one role; `permissions` comes back as **objects**, not strings |
| `createRole(data)` | Create new role — send `permissionKeys` (not `permissions`) |
| `updateRole(id, data)` | Update role label/permissions — send `permissionKeys` |
| `deleteRole(id)` | Delete role |
| `cloneRole(id, data)` | Clone a role |
| `getPermissionCatalog()` | `GET /api/roles/permissions` — the full catalog the matrix renders from |

All of these go through `apiFetch` (`src/services/httpClient.js`), which injects
`X-Hall-Id` / `X-Org-Id` and transparently recovers from a `401 { code: 'TOKEN_STALE' }`
by refreshing once and replaying the request — so a role edit updates a signed-in user's
nav without logging them out.

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
