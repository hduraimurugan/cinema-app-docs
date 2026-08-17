# Database — Roles, Permissions & Team Management

## Table: `roles`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | Primary key |
| `org_id` | UUID | FK → organizations(id), NOT NULL | Owning organization |
| `key` | VARCHAR | NOT NULL | Slug identifier (e.g. `custom_support`) |
| `label` | VARCHAR | NOT NULL | Display name |
| `description` | TEXT | | Human-readable description |
| `is_system` | BOOLEAN | DEFAULT false | System roles cannot be deleted |
| `permissions_version` | INT | DEFAULT 1 | Incremented on every permission change |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() | |

**Constraints:** `UNIQUE(org_id, key)`, `UNIQUE(id, org_id)` — the latter is not a
business constraint, it's the anchor `organization_members.role_id` is validated
against (see below) so a role from one org can never be assigned to a member of
another.

## Table: `permissions`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | Primary key |
| `key` | VARCHAR | UNIQUE, NOT NULL | Permission key (e.g. `bookings.create`) |
| `label` | VARCHAR | NOT NULL | Display name |
| `resource` | VARCHAR | NOT NULL | Resource grouping (e.g. `bookings`) |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

## Table: `role_permissions`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `role_id` | UUID | FK → roles(id) ON DELETE CASCADE | |
| `permission_id` | UUID | FK → permissions(id) ON DELETE CASCADE | |

**Constraints:** `UNIQUE(role_id, permission_id)`

## Table: `organization_members`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | Primary key |
| `org_id` | UUID | FK → organizations(id), NOT NULL | |
| `admin_id` | UUID | FK → cinema_admin_user(id), NOT NULL | |
| `role_id` | UUID | **Composite FK** → `roles(id, org_id)`, NOT NULL | Enforces that a member can only ever hold a role belonging to their own org (see `roles.UNIQUE(id, org_id)` above) |
| `status` | VARCHAR | NOT NULL | `active`, `suspended`, `invited`, or `removed` |
| `invited_by` | UUID | FK → cinema_admin_user(id) | Admin who invited this member |
| `invited_at` | TIMESTAMPTZ | | When the invite was sent |
| `joined_at` | TIMESTAMPTZ | | When the invite was accepted |
| `removed_at` | TIMESTAMPTZ | | Set when `status` moves to `removed`; cleared if re-invited |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

**Constraints:**
- `UNIQUE(id, org_id)` — composite anchor `hall_assignments` validates against
- Partial unique index `uniq_active_org_member ON (org_id, admin_id) WHERE status <> 'removed'` — replaces a plain `UNIQUE(org_id, admin_id)`. A removed member's row is kept for history and no longer blocks a fresh invite for that same org+admin pair.
- `role_id` FK is `ON DELETE RESTRICT` — a role with active members cannot be deleted (enforced additionally in `deleteRole`)

**Owner identification:** there is no `is_owner` column. A member is the
organization's owner when `organization_members.admin_id = organizations.owner_id`.
API responses compute this (see [api.md](api.md)) and the UI locks role/status/hall
access/removal for that member (see [workflows.md](workflows.md)).

## Table: `hall_assignments`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | Primary key |
| `org_member_id` | UUID | **Composite FK** → `organization_members(id, org_id)` | |
| `org_id` | UUID | FK → organizations(id), NOT NULL | Denormalized from the member so both sides of the assignment can be validated against the same org |
| `hall_id` | UUID | **Composite FK** → `cinema_hall(id, org_id)` | |
| `scope` | VARCHAR | DEFAULT `'full'` | `full` or `read_only` |
| `assigned_by` | UUID | FK → cinema_admin_user(id) | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

**Constraints:** `UNIQUE(org_member_id, hall_id)`. The two composite FKs
(added by `migration_phase4_tenant_integrity.sql`) guarantee the member and
the hall belong to the *same* organization — previously nothing stopped a
member of org A from being granted access to a hall in org B.

## Team invites — there is no `team_invites` table

Invites reuse two existing tables rather than adding one:

| Concern | Where it lives |
|---|---|
| Who was invited, to which role, by whom | `organization_members` with `status = 'invited'`, `invited_by`, `invited_at` |
| The invite token | `admin_verification_tokens` with `purpose = 'team_invite'` |

`inviteMember` (`services/team.service.js`) stores only the **SHA-256 hash** of the
token, with a **7-day** expiry, and emails the raw value. `acceptInvite` sets the password,
flips the membership to `status = 'active'`, stamps `joined_at`, and deletes the token rows.

Because membership and invite state are the same row, an invite to someone previously
removed **revives** their `status = 'removed'` row instead of inserting a duplicate — which
is exactly why `uniq_active_org_member` is a partial index excluding removed rows.

There is no `INVITE_EXPIRY_HOURS` environment variable; the 7-day window is set in code.

## System Roles (Seeded Data)

| Key | Label | Description |
|---|---|---|
| `owner` | Owner | Full access including billing and org management |
| `admin` | Admin | Full access except billing, org deletion, and role management |
| `manager` | Manager | Shows, screens, bookings, refunds, customers |
| `sales` | Sales | Bookings, refunds, customer inquiries |
| `finance` | Finance | Bookings, payments, refunds, analytics |
| `marketing` | Marketing | Offers, ads, customer analytics |
| `ticket_operator` | Ticket Operator | Verify tickets, view bookings and shows |
| `auditor` | Auditor | Read-only across all resources |

## Key Relationships

```
organizations 1──N roles
                   1──N role_permissions N──1 permissions
organizations 1──N organization_members N──1 cinema_admin_user
                   1──N hall_assignments N──1 cinema_hall
cinema_admin_user 1──N admin_verification_tokens   (purpose = 'team_invite')
```

`permissions` is a **global** catalog keyed by `key`, not per-organization — 55 rows after
`migration_phase5_page_permissions.sql` added `halls.read` and `halls.manage`. Only
`role_permissions` is org-scoped, through `roles`.

### Delete rules that matter

`roles`, `organization_members`, `organization_settings` and `cinema_hall` are all
`ON DELETE CASCADE` from `organizations`, and `cinema_hall` cascades onward into screens,
shows and bookings. Never delete an organization without first confirming it has no halls —
see `database/migration_phase6_remove_phantom_orgs.sql` for the guarded pattern, and
[`../../registration-and-onboarding-flow.md`](../../registration-and-onboarding-flow.md#7-table-map)
for the full cascade map.
