# Workflows — Roles, Permissions & Team Management

## 1. Creating a Custom Role

```
1. Admin navigates to Settings → Roles & Permissions
2. Clicks "Create Role"
3. CreateRoleDialog opens
   3a. Enters label (e.g. "Support Agent")
   3b. Selects permissions via PermissionMatrixTable
   3c. Optionally clones from existing role
4. Clicks "Save"
5. POST /api/roles → roles.Controller.createRole
   5a. Server generates key as slug from label (e.g. "support_agent")
   5b. Server inserts row in `roles` table
   5c. Server inserts rows in `role_permissions` junction table
   5d. Server sets permissions_version = 1
6. UI refreshes role list
7. New role is available in member invitations
```

## 2. Inviting a Team Member

```
1. Admin navigates to Settings → Team
2. Clicks "Invite Member"
3. TeamInviteDialog opens
   3a. Enters email, name
   3b. Selects role (e.g. "Support Agent")
   3c. Clicks "Send Invite"
4. POST /api/team/invite → team service
   4a. Generates unique invite token
   4b. Hashes token, stores in team_invites table
   4c. Creates organization_members row with status = "invited"
   4d. Sends invitation email with accept link containing token
5. UI shows success toast; pending invite appears in member list
```

## 3. Accepting a Team Invite

```
1. Recipient clicks link in invitation email
2. Opens accept-invite page (no auth required)
3. Recipient sets password
4. POST /api/team/invite/accept?token=xxx
   4a. Server validates token via team.service.validateInviteToken
   4b. Checks expiry (default 72 hours)
   4c. Creates cinema_admin_user account if needed
   4d. Updates organization_members: status → "active", joined_at = now()
   4e. Marks team_invite status → "accepted"
5. Recipient is redirected to login
6. Can now access the org with assigned role's permissions
```

## 4. Modifying a Role's Permissions

```
1. Admin navigates to Settings → Roles & Permissions
2. Clicks on a role (e.g. "Support Agent")
3. PermissionMatrixTable opens in edit mode
4. Admin toggles permission checkboxes
5. Clicks "Save Changes"
6. PATCH /api/roles/:id → roles.Controller.updateRole
   6a. Server replaces all role_permissions for this role
   6b. Server increments permissions_version
   6c. If JWTs embed permissions_version, affected members see stale data until next token refresh
7. UI updates role list
8. All members with this role have effective permissions changed immediately
   (next API call re-evaluates via loadAdminPermissions)
```

## 5. Suspending a Member

```
1. Admin navigates to Settings → Team
2. Finds member, opens MemberDetailDrawer
3. Clicks "Suspend"
   3a. If this member is the organization owner, the button is disabled
       and unreachable — see workflow 10.
4. PATCH /api/team/members/:id { status: "suspended" }
   4a. Server checks assertNotOrgOwner — passes (not the owner)
   4b. Server updates organization_members.status → "suspended", removed_at → NULL
5. Member is logged out on next request
   (middleware checks member status on authenticated routes)
6. Suspended member appears with red badge in team list
```

## 6. Permission Check Flow (Request Lifecycle)

```
1. Client makes authenticated API request (e.g. DELETE /api/roles/:id)
2. verifyCinemaAdminAccessToken middleware validates JWT
3. requirePermission("roles.manage") middleware:
   3a. Calls teamService.loadAdminPermissions(adminId, orgId)
   3b. loadAdminPermissions queries:
       - organization_members to get member's role_id
       - role_permissions joined with permissions to get all permission keys
       - Returns Set<string> of permission keys
   3c. Checks if "roles.manage" is in the Set
   3d. If not → 403 Forbidden
   3e. If yes → next()
4. roles.Controller.deleteRole executes
```

## 7. UI Permission Gating

```
1. Component renders
2. Calls can('roles.manage') from PermissionContext
3. PermissionContext checks the admin's resolved permission set
   (loaded on login, refreshed on token change)
4. If true → renders "Delete Role" button
5. If false → button is hidden
```

## 8. Deleting a Role

```
1. Admin navigates to Settings → Roles & Permissions
2. Finds a non-system role, clicks "Delete"
3. Confirmation dialog opens
4. User confirms
5. DELETE /api/roles/:id → roles.Controller.deleteRole
   5a. Server checks is_system → blocks if true (400)
   5b. Server counts members with this role → blocks if > 0 (400)
   5c. Server deletes role_permissions rows (CASCADE)
   5d. Server deletes role row
6. UI removes role from list
```

## 9. Cloning a Role

```
1. Admin opens CreateRoleDialog
2. Selects "Clone from existing role" dropdown
3. Picks source role (e.g. "Manager")
4. Modifies label/description as needed
5. Permission matrix pre-fills with source role's permissions
6. Admin adjusts permissions, clicks "Save"
7. POST /api/roles with cloneFrom field
   7a. Server creates new role
   7b. Copies all permission associations from source role
   7c. Custom label/description applied to new role
8. New cloned role appears in list
```

## 10. Owner Protection Guard

Applies whenever the target of a team-management action is the organization's
registered owner (`organization_members.admin_id = organizations.owner_id`).
Enforced identically regardless of entry point — the UI disables the controls,
but the backend check is what actually holds:

```
1. MemberDetailDrawer loads the member via GET /api/team/members/:id
   1a. Response includes is_owner: true for this member
2. UI locks four things for this member:
   2a. Role dropdown         → disabled
   2b. Status buttons        → disabled (Active/Suspended)
   2c. Hall Access controls  → "Add Hall" hidden, each row's remove (X) hidden
   2d. "Remove from Organization" button → replaced with a static message
3. A banner explains why, right under the member's name.
4. If any of these were attempted anyway — a direct API call, a race, a bug —
   team.service.js's assertNotOrgOwner() rejects it before any row is touched:
   4a. updateMember            → 403 CANNOT_MODIFY_OWNER
   4b. removeMember            → 403 CANNOT_REMOVE_OWNER
   4c. assignHalls             → 403 CANNOT_MODIFY_OWNER
   4d. removeHallAssignment    → 403 CANNOT_MODIFY_OWNER
5. To actually change the owner's role, status, or hall access, or to remove
   them, ownership must first be transferred to a different member (not yet
   implemented as a dedicated flow — currently requires direct DB access to
   organizations.owner_id, then re-running migration_phase4's owner-membership
   backfill or an equivalent manual insert).
```

Why owners specifically: `requireActiveHall` already grants an org's `owner`
and `admin` roles full access to every hall in the org, independent of
`hall_assignments` rows — so editing the owner's individual hall grants has no
effect and only invites confusion. And every organization must always have
exactly one reachable owner; letting that member be suspended, demoted, or
removed through this UI would either lock the owner out of their own
organization or leave the org ownerless.
