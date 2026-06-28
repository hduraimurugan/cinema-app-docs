# Workflows: Settings Module

## Common Operations

### 1. Organization Onboarding — Seed Default Settings

**Trigger:** New organization created.

**Steps:**
1. Admin registers or is invited — organization row created in `organizations` table.
2. Onboarding flow calls PATCH /api/settings/org for each section:
   - Section: `general` → value from organizationDefaults.general
   - Section: `payment` → value from organizationDefaults.payment
   - Section: `tickets` → value from organizationDefaults.tickets
   - Section: `security` → value from organizationDefaults.security
   - Section: `notifications` → value from organizationDefaults.notifications
   - Section: `branding` → value from organizationDefaults.branding
   - Section: `integrations` → value from organizationDefaults.integrations
   - Section: `advanced` → value from organizationDefaults.advanced
3. Each call creates a row in `organization_settings` via `INSERT ... ON CONFLICT DO NOTHING`.

**Relevant files:**
- `settingsDefaults.js` — default values
- `settings.Controller.js` — `resolveOrgId` + PATCH handler
- `SettingsContext.jsx` — reads settings on mount

### 2. Updating Organization Name

**Trigger:** SuperAdmin edits organization name in General Settings.

**Data flow:**
1. User edits `org_name` field in GeneralSettingsPage.
2. Form calls `updateSettings('general', { org_name: 'New Name' })`.
3. PATCH /api/settings/org with section=`general`, value=`{ org_name: "New Name" }`.
4. Controller deep-merges `{ org_name }` into existing `general` JSONB.
5. Controller also executes `UPDATE organizations SET name = 'New Name' WHERE id = :orgId`.
6. SettingsContext updates local state with returned data.

**Source of truth:** `organizations.name` is the canonical name. The JSONB value is a convenience copy for settings UI consistency.

### 3. Configuring Payment Settings

**Trigger:** SuperAdmin configures convenience fee and GST.

**Steps:**
1. Admin navigates to Payment Settings page.
2. `SettingsContext` provides current `settings.payment` values.
3. Admin adjusts `convenience_fee` model/amount and `gst_percentage`.
4. Form calls `updateSettings('payment', patch)`.
5. PATCH /api/settings/org with section=`payment`.
6. Deep-merge updates only the changed fields.
7. Legacy `GET /api/settings` now returns the updated values for customer booking.

### 4. Creating a Hall — Seed Hall Settings

**Trigger:** New cinema hall created.

**Steps:**
1. Hall row created in `cinema_hall` table.
2. Settings service seeds 4 rows in `hall_settings` from `hallDefaults`:
   - cinema_profile, showtimes, booking, offers.
3. Admin navigates to Cinema Profile or Showtimes settings to customize.

### 5. Updating Hall Booking Policy

**Trigger:** Hall admin changes booking rules.

**Steps:**
1. Admin navigates to Booking Settings page (hall-scoped).
2. Page calls `getHallSettings(hallId)` on mount.
3. Admin modifies fields (e.g., `max_seats_per_booking`, `cancellation`).
4. PATCH /api/settings/hall/:hallId with section=`booking`.
5. `requireActiveHall` middleware validates hall is active.
6. Controller deep-merges into existing `booking` JSONB.

### 6. Reading Settings in the Customer Booking Flow

**Trigger:** Customer visits booking page (public, unauthenticated).

**Steps:**
1. Frontend calls `GET /api/settings` (no auth).
2. Controller fetches `organization_settings` where section=`payment`.
3. Returns `{ convenience_fee, gst_percentage }` only.
4. Booking UI displays convenience fee and calculates GST on ticket price.

### 7. Integrating a Payment Gateway

**Trigger:** SuperAdmin configures Razorpay in Integrations settings.

**Steps:**
1. Admin navigates to Integrations section (org settings).
2. Enters Razorpay key and secret.
3. Secret is encrypted before storage (stored as `secret_encrypted`).
4. PATCH /api/settings/org with section=`integrations`.
5. Payment module reads the integration settings at runtime to initialize the gateway.

## Data Flow Diagram

```
Public (no auth)
  │
  ▼
GET /api/settings ────► organization_settings (payment)
  │                         ▲
  └── Customer booking ─────┘

Admin (authenticated)
  │
  ├── SettingsContext (mount)
  │     │
  │     ▼
  │   GET /api/settings/org ────► organization_settings (all sections)
  │     │
  │     └── Provides to all settings pages
  │
  ├── General / Payment / Security / etc.
  │     │
  │     ▼
  │   PATCH /api/settings/org ────► organization_settings (deep merge)
  │
  ├── Cinema Profile / Showtimes / Booking / Offers
  │     │
  │     ▼
  │   GET/PATCH /api/settings/hall/:hallId ────► hall_settings
  │
  └── User preferences
        │
        ▼
      GET/PATCH /api/settings/user ────► user_settings
```

## Error Recovery

| Scenario | Behavior |
|----------|----------|
| Settings fetch fails | UI shows empty state with retry button. SettingsContext keeps previous data if available. |
| Settings save fails | SettingsCard shows error banner. Form data preserved for retry. |
| Hall not found / inactive | `requireActiveHall` returns 403. Page shows "Hall not found" message. |
| Org not found | `resolveOrgId` auto-creates org for SuperAdmin. Other roles get 404. |
| Deep merge conflict | Last write wins (no optimistic locking). `updated_at` can be used for conflict detection if needed. |
