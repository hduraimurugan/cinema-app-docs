# Backend: Settings Module

## Controller

**File:** `cinema-hall-api/controllers/settings.Controller.js`

Three tiered scopes: organization, hall, and user settings.

### Helper Functions

| Function | Purpose |
|----------|---------|
| `resolveOrgId(req)` | Finds the organization for the authenticated admin. Auto-creates an organization for SuperAdmins if none exists. |
| `getSectionRow(scope, id, section)` | Fetches a single settings row by scope (`organization_settings`, `hall_settings`, `user_settings`) + section name. Returns `null` if not found. |

### Controller Functions

| Function | Endpoint | Description |
|----------|----------|-------------|
| `getSettings` | GET /api/settings | **Public/legacy.** Returns payment settings (convenience_fee, GST) for customer booking flow. |
| `updateSettings` | PUT /api/settings | **SuperAdmin legacy.** Delegates to `updateOrgSettings` with section=`payment`. |
| `getOrgSettings` | GET /api/settings/org | Returns all 8 org settings sections + organization info (name, slug, plan). |
| `updateOrgSettings` | PATCH /api/settings/org | Deep-merges patch into the section. If `org_name` is set, syncs to `organizations.name`. |
| `getHallSettings` | GET /api/settings/hall/:hallId | Returns all 4 hall settings sections. |
| `updateHallSettings` | PATCH /api/settings/hall/:hallId | Deep-merges patch into the section. |
| `getUserSettings` | GET /api/settings/user | Returns user settings sections. |
| `updateUserSettings` | PATCH /api/settings/user | Deep-merges patch into user settings. |

### Deep-Merge Strategy

PATCH endpoints accept a partial payload:

```json
{
  "section": "payment",
  "value": { "convenience_fee": { "amount": 2.50 } }
}
```

Only `value.convenience_fee.amount` is updated. All other keys in the `payment` section remain unchanged. The merge is performed at the JSONB level in the database or application layer.

## Routes

**File:** `cinema-hall-api/routes/settings.routes.js`

| Method | Path | Middleware |
|--------|------|-----------|
| GET | /api/settings | *(none — public)* |
| PUT | /api/settings | `verifyCinemaAdminAccessToken`, `verifySuperAdmin` |
| GET | /api/settings/org | `verifyCinemaAdminAccessToken` |
| PATCH | /api/settings/org | `verifyCinemaAdminAccessToken`, `verifySuperAdmin` |
| GET | /api/settings/hall/:hallId | `verifyCinemaAdminAccessToken`, `requireActiveHall` |
| PATCH | /api/settings/hall/:hallId | `verifyCinemaAdminAccessToken`, `requireActiveHall` |
| GET | /api/settings/user | `verifyCinemaAdminAccessToken` |
| PATCH | /api/settings/user | `verifyCinemaAdminAccessToken` |

### Middleware Notes

- `requireActiveHall` ensures the hall exists and is active before any hall-scoped settings operation.
- `verifySuperAdmin` restricts org-scoped writes to SuperAdmin role only.
- Legacy `PUT /api/settings` is a convenience wrapper; all new integrations should use the scoped endpoints.

## Settings Defaults

**File:** `cinema-hall-admin/src/lib/settings/settingsDefaults.js`

Contains default JSON values for every settings section. Used during:

1. **Organization onboarding** — seeds all 8 org sections with defaults.
2. **Hall creation** — seeds all 4 hall sections with defaults.
3. **Fallback reads** — if a settings row is missing for a section, defaults are returned.

### Structure

```js
export const organizationDefaults = {
  general: { org_name: '', timezone: 'UTC', currency: 'INR', language: 'en' },
  payment: { convenience_fee: { model: 'flat', amount: 0 }, gst_percentage: 0, gst_applies_to: [], state_taxes: [] },
  tickets: { booking_id_prefix: 'BK', qr_error_correction: 'M', pdf_footer_text: '' },
  security: { password_policy: { min_length: 8, require_upper: true, ... }, lockout_policy: { thresholds: [] }, ... },
  notifications: { email: { provider: '', from: '', enabled: false }, sms: {}, whatsapp: {}, push: {} },
  branding: { logo_url: '', logo_dark_url: '', banner_url: '', primary_color: '', ... },
  integrations: { razorpay: { key: '', secret_encrypted: '' }, tmdb: { api_key: '' }, cloudinary: { ... } },
  advanced: { feature_flags: {}, retention_days: { security_logs: 90, audit_logs: 365, sessions: 30, devices: 30 } }
};

export const hallDefaults = {
  cinema_profile: { name: '', address: '', district: '', state: '', phone: '', description: '', operating_hours: {} },
  showtimes: { default_buffer_minutes: 15, prevent_overlap: true, ... },
  booking: { max_seats_per_booking: 10, advance_booking_days: 7, hold_minutes: 10, cancellation: { ... } },
  offers: { auto_apply_best: true, max_redemptions_per_customer: 1, default_validity_days: 30 }
};
```
