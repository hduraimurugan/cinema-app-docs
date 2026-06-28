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

A slide-out drawer showing member details with role and status management.

| Prop | Type | Default | Description |
|---|---|---|---|
| `open` | boolean | `false` | |
| `member` | object | `null` | The member object to display |
| `roles` | array | `[]` | Available roles for role change dropdown |
| `onClose` | function | | |
| `onRoleChange` | function | | Called with `(memberId, newRoleId)` |
| `onStatusChange` | function | | Called with `(memberId, newStatus)` |
| `onRemove` | function | | Called with `memberId` |

**Tabs:**
- **Details** — Name, email, status badge, joined date, invited by
- **Hall Assignments** — List of assigned halls
- **Activity** — Recent actions (if available)

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
