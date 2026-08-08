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

## Table: `team_invites`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | |
| `org_id` | UUID | NOT NULL | |
| `email` | VARCHAR | NOT NULL | Invited email address |
| `name` | VARCHAR | NOT NULL | Invited person's name |
| `role_id` | UUID | | Target role |
| `invited_by` | UUID | | Admin who created the invite |
| `token_hash` | VARCHAR | NOT NULL | Hashed invite token |
| `status` | VARCHAR | NOT NULL | `pending`, `accepted`, `expired` |
| `expires_at` | TIMESTAMPTZ | NOT NULL | Default: now + 72 hours |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

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
organizations 1──N team_invites
```
