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

A right-side `Sheet` (shadcn, `w-full sm:max-w-lg p-0`) for creating a new organization member (account + password, role, hall access). Refactored from a `Dialog` in `b014eb6a`.

| Prop | Type | Default | Description |
|---|---|---|---|
| `open` | boolean | `false` | |
| `onClose` | function | | |
| `onAdded` | function | | Called with the new member object |
| `roles` | array | `[]` | Available roles for role selection dropdown |

**Behavior (`b014eb6a`):**
- The form is a flex-column that fills the sheet height: `SheetHeader`, a scrollable body (`flex-1 px-4`), and a `SheetFooter` (top-bordered) with Cancel / Create Member.
- Form fields reset in a `useEffect` keyed on `open` (previously only cleared after a successful submit).
- Each input gets `name` + `autoComplete` attributes (`autoComplete="new-password"` on the password, `"off"` elsewhere), plus two hidden dummy `username`/`new-password` fields — absorbing Chrome's saved-login autofill so it can't hijack the form.
- Hall Access rows render in a `max-h-64 overflow-y-auto` list with per-hall Full Access / Read Only scope select.

---

## MemberDetailDrawer

**Path:** `src/components/settings/MemberDetailDrawer.jsx`

A slide-out `Sheet` (shadcn) showing one member's details, fetched by `memberId`
on open — not a tabbed view, a single scrollable panel organized into `Card`
sections (refactored to cards in `b014eb6a`): Profile, Role & Status, Hall
Access, and a Danger Zone.

| Prop | Type | Default | Description |
|---|---|---|---|
| `memberId` | string | | Member to load; fetch runs in a `useEffect` keyed on this + `open` |
| `open` | boolean | `false` | |
| `onOpenChange` | function | | Sheet open/close handler |
| `onSuccess` | function | | Called after any successful mutation, so the parent list can refetch |
| `roles` | array | `[]` | Pre-fetched roles for the dropdown; fetched lazily if not provided |

**Sections (`b014eb6a` card layout):**
- **Profile card** — avatar, name, and an `Owner` badge with a `Crown` icon when `member.is_owner`; email/phone rows (`Mail`/`Phone` icons); a 2-col Joined / Last login grid (`CalendarDays`/`Clock`, formatted by a local `formatDate` helper)
- **Owner banner** — shown only for the owner, directly under the profile card: *"Owners are locked: role, status, hall access, and removal can't be changed here. Transfer ownership first."* (with a `Lock` icon)
- **Role & Status card** — `ShieldCheck` header; a `Select` calling `updateMember(memberId, { roleId })` on change, and Active/Suspended buttons (`CircleDot`/`AlertTriangle`) calling `updateMember(memberId, { status })`
- **Hall Access card** — `Building2` header; list of assigned halls (icon tile + name + scope badge) with an inline "Add Hall" form and per-row remove (`X`) button
- **Danger Zone card** — destructive-styled `Card` (`border-destructive/30 bg-destructive/[0.03]`, `AlertTriangle` header) containing the `AlertDialog`-confirmed "Remove from Organization" button calling `removeMember(memberId)`

**Owner lock (`member.is_owner === true`):** every control above becomes either
`disabled` or is hidden outright — the Role select, both Status buttons, the
"Add Hall" button, and each hall row's remove button are disabled/hidden; the
Remove button is replaced with a static message, *"Owners can't be removed
from the organization."* This is UI-side only for feedback — the real
enforcement is the backend's `assertNotOrgOwner` guard (see
[backend.md](backend.md)), so the rule holds even if these controls were
somehow triggered directly.

The whole content region (everything below the `SheetHeader`) is wrapped in a
`px-4 pb-6 space-y-4` div — `SheetContent` itself ships with no padding, so this
wrapper is what keeps the panel's body aligned with the header instead of
running edge-to-edge, and spaces the `Card` sections.

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
