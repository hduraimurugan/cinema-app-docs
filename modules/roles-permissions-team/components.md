# Components — Roles, Permissions & Team Management

## CreateRoleDialog

**Path:** `src/components/settings/CreateRoleDialog.jsx`

A modal dialog for creating new roles.

| Prop | Type | Default | Description |
|---|---|---|---|
| `open` | boolean | `false` | Controls dialog visibility |
| `onClose` | function | | Called when dialog is dismissed |
| `onCreated` | function | | Called with the created role object after success |
| `permissions` | array | `[]` | List of available permission objects `{ id, key, label, resource }` |

**Behavior:**
- User enters a role label (auto-generates key as slug).
- User optionally enters a description.
- User selects permissions from a grouped check list.
- User may optionally clone permissions from an existing role via a dropdown.
- Submits to `POST /api/roles`.

---

## PermissionMatrixTable

**Path:** `src/components/settings/PermissionMatrixTable.jsx`

A table with resources as rows and actions as columns, checkboxes at intersections.

| Prop | Type | Default | Description |
|---|---|---|---|
| `permissions` | array | `[]` | All available permission objects |
| `selected` | array (of key strings) | `[]` | Currently selected permission keys |
| `onChange` | function | | Called with updated array of selected keys |
| `readOnly` | boolean | `false` | Renders checkboxes as disabled |

**Structure:**

```
            ┌──────┬──────────┬──────────┬──────────┐
            │ View │  Create  │  Update  │  Delete  │
┌───────────┼──────┼──────────┼──────────┼──────────┤
│ Bookings  │  ☑   │    ☐     │    ☐     │    ☐     │
│ Roles     │  ☑   │    ☑     │    ☐     │    ☐     │
│ Customers │  ☑   │    ☐     │    ☐     │    ☐     │
└───────────┴──────┴──────────┴──────────┴──────────┘
```

---

## AddMemberDialog

**Path:** `src/components/settings/AddMemberDialog.jsx`

A dialog for adding an existing admin user to the organization.

| Prop | Type | Default | Description |
|---|---|---|---|
| `open` | boolean | `false` | |
| `onClose` | function | | |
| `onAdded` | function | | Called with the new member object |
| `roles` | array | `[]` | Available roles for role selection dropdown |

---

## MemberDetailDrawer

**Path:** `src/components/settings/MemberDetailDrawer.jsx`

A slide-out `Sheet` (shadcn) showing one member's details, fetched by `memberId`
on open — not a tabbed view, a single scrollable panel with four sections:
Role, Status, Hall Access, and a Remove action.

| Prop | Type | Default | Description |
|---|---|---|---|
| `memberId` | string | | Member to load; fetch runs in a `useEffect` keyed on this + `open` |
| `open` | boolean | `false` | |
| `onOpenChange` | function | | Sheet open/close handler |
| `onSuccess` | function | | Called after any successful mutation, so the parent list can refetch |
| `roles` | array | `[]` | Pre-fetched roles for the dropdown; fetched lazily if not provided |

**Sections:**
- **Header** — avatar, name, email, and an `Owner` badge (`bg-primary/10`) when `member.is_owner`
- **Owner banner** — shown only for the owner, directly under the header: *"Owners are locked: role, status, hall access, and removal can't be changed here. Transfer ownership first."* Sits outside the section grid so it doesn't disturb the vertical rhythm shared with the non-owner layout.
- **Role** — a `Select` calling `updateMember(memberId, { roleId })` on change
- **Status** — Active/Suspended buttons calling `updateMember(memberId, { status })`
- **Hall Access** — list of assigned halls with an inline "Add Hall" form; per-row remove (`X`) button
- **Remove** — an `AlertDialog`-confirmed destructive button calling `removeMember(memberId)`

**Owner lock (`member.is_owner === true`):** every control above becomes either
`disabled` or is hidden outright — the Role select, both Status buttons, the
"Add Hall" button, and each hall row's remove button are disabled/hidden; the
Remove button is replaced with a static message, *"Owners can't be removed
from the organization."* This is UI-side only for feedback — the real
enforcement is the backend's `assertNotOrgOwner` guard (see
[backend.md](backend.md)), so the rule holds even if these controls were
somehow triggered directly.

The whole content region (everything below the `SheetHeader`) is wrapped in a
`px-4 pb-4` div — `SheetContent` itself ships with no padding, so this wrapper
is what keeps the panel's body aligned with the header instead of running
edge-to-edge.

---

## TeamInviteDialog

**Path:** `src/components/settings/TeamInviteDialog.jsx`

A dialog for inviting new members by email.

| Prop | Type | Default | Description |
|---|---|---|---|
| `open` | boolean | `false` | |
| `onClose` | function | | |
| `onInvited` | function | | Called with the invite object after success |
| `roles` | array | `[]` | Available roles for role selection dropdown |

**Fields:**
- Email (required, email validation)
- Name (required)
- Role (required, dropdown)
- Optional message

**Behavior:**
- On submit, calls `POST /api/team/invite`.
- Displays success snackbar with invite link shown (in development) or confirmation message.
