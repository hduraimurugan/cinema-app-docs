# Database: Settings Tables

## Table: `organization_settings`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `org_id` | UUID | FK → `organizations(id)`, PK (composite) | Organization identifier |
| `section` | VARCHAR | PK (composite) | Section name (general, payment, tickets, security, notifications, branding, integrations, advanced) |
| `value` | JSONB | NOT NULL | Section configuration data |
| `schema_version` | INTEGER | DEFAULT 1 | Tracks schema evolution for migrations |
| `updated_by` | UUID | FK → `cinema_admin_user(id)` | Who last updated this row |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Unique constraint:** `UNIQUE(org_id, section)`

### Organization Sections Reference

| Section | Key Fields |
|---------|------------|
| general | `org_name`, `timezone`, `currency`, `language` |
| payment | `convenience_fee` ({model, amount}), `gst_percentage`, `gst_applies_to`, `state_taxes[]` |
| tickets | `booking_id_prefix`, `qr_error_correction`, `pdf_footer_text` |
| security | `password_policy` ({min_length, require_upper, ...}), `lockout_policy` ({thresholds[]}), `session_timeout_minutes`, `mfa_required`, `invite_expiry_hours` |
| notifications | `email` ({provider, from, enabled}), `sms`, `whatsapp`, `push` |
| branding | `logo_url`, `logo_dark_url`, `banner_url`, `primary_color`, `accent_color`, `font_family`, `app_name`, `default_theme`, `white_label` |
| integrations | `razorpay` ({key, secret_encrypted}), `tmdb` ({api_key}), `cloudinary` ({cloud_name, api_key, api_secret_encrypted}) |
| advanced | `feature_flags`, `retention_days` ({security_logs, audit_logs, sessions, devices}) |

## Table: `hall_settings`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `hall_id` | UUID | FK → `cinema_hall(id)`, PK (composite) | Hall identifier |
| `section` | VARCHAR | PK (composite) | Section name (cinema_profile, showtimes, booking, offers) |
| `value` | JSONB | NOT NULL | Section configuration data |
| `schema_version` | INTEGER | DEFAULT 1 | Tracks schema evolution |
| `updated_by` | UUID | FK → `cinema_admin_user(id)` | Who last updated this row |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Unique constraint:** `UNIQUE(hall_id, section)`

### Hall Sections Reference

| Section | Key Fields |
|---------|------------|
| cinema_profile | `name`, `address`, `district`, `state`, `phone`, `description`, `operating_hours` |
| showtimes | `default_buffer_minutes`, `prevent_overlap`, `default_language_version`, `auto_status_transitions`, `timezone`, `advance_booking_days`, `booking_open_offset_minutes` |
| booking | `max_seats_per_booking`, `advance_booking_days`, `hold_minutes`, `cancellation` ({allowed, window_minutes, penalty_percentage}) |
| offers | `auto_apply_best`, `max_redemptions_per_customer`, `default_validity_days` |

## Table: `user_settings`

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `admin_id` | UUID | FK → `cinema_admin_user(id)`, PK (composite) | Admin user identifier |
| `section` | VARCHAR | PK (composite) | Section name (notifications, analytics, appearance) |
| `value` | JSONB | NOT NULL | Section configuration data |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update timestamp |

**Unique constraint:** `UNIQUE(admin_id, section)`

## Table: `organizations`

Referenced by `organization_settings` and used as the source of truth for organization name.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PK | Organization identifier |
| `name` | VARCHAR | NOT NULL | Organization name (source of truth) |
| `slug` | VARCHAR | UNIQUE, NOT NULL | URL-friendly identifier |
| `owner_id` | UUID | FK → `cinema_admin_user(id)` | Organization owner |
| `plan` | VARCHAR | | Subscription plan |
| `is_active` | BOOLEAN | DEFAULT true | Whether the org is active |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | |

## Entity Relationships

```
organizations (1) ──── (N) organization_settings
organizations (1) ──── (N) cinema_hall
cinema_hall   (1) ──── (N) hall_settings
cinema_admin_user (1) ──── (N) user_settings
```

## JSONB Design Rationale

Settings use JSONB instead of separate columns per field because:

1. **Schema flexibility** — new settings fields can be added without migrations.
2. **Section-at-a-time access** — most operations read/write an entire section, making JSONB efficient.
3. **Deep merge** — PATCH operations can update nested fields without touching sibling keys.
4. **Read pattern** — both admin UI and API return all sections at once; JSONB avoids N+1 joins.
