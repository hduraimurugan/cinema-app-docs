# API: Settings Endpoints

Base path: `/api/settings`

## Legacy Endpoints

### GET /api/settings

Public endpoint used by customer booking flow. Returns only payment settings.

**Response (200):**

```json
{
  "convenience_fee": { "model": "flat", "amount": 2.00 },
  "gst_percentage": 18
}
```

### PUT /api/settings

SuperAdmin-only. Legacy wrapper — delegates to PATCH /api/settings/org with section=`payment`.

**Auth:** `verifyCinemaAdminAccessToken` + `verifySuperAdmin`

**Request body:**

```json
{
  "convenience_fee": { "model": "flat", "amount": 2.50 },
  "gst_percentage": 18
}
```

## Organization Settings

### GET /api/settings/org

Returns all organization settings sections plus org metadata.

**Auth:** `verifyCinemaAdminAccessToken`

**Response (200):**

```json
{
  "organization": {
    "name": "My Cinema",
    "slug": "my-cinema",
    "plan": "premium"
  },
  "settings": {
    "general": { "org_name": "My Cinema", "timezone": "Asia/Kolkata", "currency": "INR", "language": "en" },
    "payment": { "convenience_fee": { "model": "flat", "amount": 2.00 }, "gst_percentage": 18, ... },
    "tickets": { "booking_id_prefix": "BK", "qr_error_correction": "M", ... },
    "security": { "password_policy": { ... }, "session_timeout_minutes": 60, ... },
    "notifications": { "email": { "enabled": false }, ... },
    "branding": { "logo_url": "", "primary_color": "#000000", ... },
    "integrations": { "razorpay": { "key": "" }, ... },
    "advanced": { "feature_flags": {}, "retention_days": { ... } }
  }
}
```

### PATCH /api/settings/org

Update one or more organization settings sections. Deep-merges into existing values.

**Auth:** `verifyCinemaAdminAccessToken` + `verifySuperAdmin`

**Request body:**

```json
{
  "section": "general",
  "value": {
    "org_name": "Updated Cinema Name",
    "timezone": "Asia/Kolkata"
  }
}
```

**Behavior:** If `value` contains `org_name`, the `organizations.name` column is also updated to keep the source of truth in sync.

## Hall Settings

### GET /api/settings/hall/:hallId

Returns all 4 hall settings sections.

**Auth:** `verifyCinemaAdminAccessToken` + `requireActiveHall`

**Response (200):**

```json
{
  "settings": {
    "cinema_profile": { "name": "Hall A", "address": "...", "operating_hours": {} },
    "showtimes": { "default_buffer_minutes": 15, "prevent_overlap": true, ... },
    "booking": { "max_seats_per_booking": 10, "advance_booking_days": 7, ... },
    "offers": { "auto_apply_best": true, ... }
  }
}
```

### PATCH /api/settings/hall/:hallId

Update one hall settings section. Deep-merges into existing values.

**Auth:** `verifyCinemaAdminAccessToken` + `requireActiveHall`

**Request body:**

```json
{
  "section": "booking",
  "value": {
    "max_seats_per_booking": 6,
    "cancellation": { "allowed": true, "window_minutes": 60, "penalty_percentage": 10 }
  }
}
```

## User Settings

### GET /api/settings/user

Returns user-specific settings sections.

**Auth:** `verifyCinemaAdminAccessToken`

**Response (200):**

```json
{
  "settings": {
    "notifications": { ... },
    "analytics": { ... },
    "appearance": { ... }
  }
}
```

### PATCH /api/settings/user

Update one user settings section. Deep-merges into existing values.

**Auth:** `verifyCinemaAdminAccessToken`

**Request body:**

```json
{
  "section": "appearance",
  "value": {
    "theme": "dark",
    "compact_view": true
  }
}
```

## Error Responses

| Status | Scenario |
|--------|----------|
| 400 | Invalid section name, missing required fields |
| 401 | Missing or invalid auth token |
| 403 | Insufficient role (non-SuperAdmin trying org write) |
| 404 | Organization not found, hall not found or inactive |
| 500 | Database error, unexpected server error |

## Summary

| Method | Endpoint | Auth | Scope |
|--------|----------|------|-------|
| GET | /api/settings | Public | Payment (legacy) |
| PUT | /api/settings | SuperAdmin | Payment (legacy) |
| GET | /api/settings/org | Any admin | Organization |
| PATCH | /api/settings/org | SuperAdmin | Organization |
| GET | /api/settings/hall/:hallId | Hall admin | Hall |
| PATCH | /api/settings/hall/:hallId | Hall admin | Hall |
| GET | /api/settings/user | Any admin | User |
| PATCH | /api/settings/user | Any admin | User |
