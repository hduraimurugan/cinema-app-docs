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

**Constraints:** `UNIQUE(org_id, key)`

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
| `role_id` | UUID | FK → roles(id), NOT NULL | |
| `status` | VARCHAR | NOT NULL | `active`, `suspended`, or `invited` |
| `invited_by` | UUID | FK → cinema_admin_user(id) | Admin who invited this member |
| `invited_at` | TIMESTAMPTZ | | When the invite was sent |
| `joined_at` | TIMESTAMPTZ | | When the invite was accepted |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

**Constraints:** `UNIQUE(org_id, admin_id)`

## Table: `hall_assignments`

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK | Primary key |
| `org_member_id` | UUID | FK → organization_members(id) | |
| `hall_id` | UUID | FK → cinema_hall(id) | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() | |

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
