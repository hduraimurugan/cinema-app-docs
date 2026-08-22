# File Reference: Settings Module

## Backend Files

| # | File | Type | Purpose |
|---|------|------|---------|
| 1 | `cinema-hall-api/controllers/settings.Controller.js` | Controller | All settings endpoint handlers (CRUD for org/hall/user + legacy) |
| 2 | `cinema-hall-api/routes/settings.routes.js` | Routes | Route definitions with middleware chains |

## Frontend Files

| # | File | Type | Purpose |
|---|------|------|---------|
| 3 | `src/pages/settings/SettingsLayout.jsx` | Page | Settings container — sticky horizontal tab bar (`SettingsTabBar` `f7952e5`, `DISABLED_PATHS` Soon, active underline), outlet for nested routes; redirects via `SettingsIndexRedirect` skipping disabled |
| 4 | `src/pages/settings/GeneralSettingsPage.jsx` | Page | Org name, timezone, currency, language form |
| 5 | `src/pages/settings/BookingSettingsPage.jsx` | Page | Max seats, advance booking, hold, cancellation form |
| 6 | `src/pages/settings/PaymentSettingsPage.jsx` | Page | Convenience fee, GST, state taxes form |
| 7 | `src/pages/settings/ShowtimesSettingsPage.jsx` | Page | Buffer, overlap, language defaults, advance booking form |
| 8 | `src/pages/settings/CinemaProfilePage.jsx` | Page | Hall name, address, contact, operating hours form |
| 9 | `src/pages/settings/RolesPermissionsPage.jsx` | Page | Role management (delegated to Roles module) |
| 10 | `src/pages/settings/TeamManagementPage.jsx` | Page | Team management (delegated to Team module) |
| 11 | `src/components/settings/SettingsCard.jsx` | Component | Reusable settings section card wrapper |
| 12 | `src/components/settings/SettingsPageHeader.jsx` | Component | Consistent page header with description |
| 13 | `src/services/settings/settingsService.js` | Service | API functions for org/hall settings |
| 14 | `src/services/api.js` (legacy) | Service | Legacy `settingsAPI` (get/update payment settings) |
| 15 | `src/context/SettingsContext.jsx` | Context | Global settings state provider |
| 16 | `src/lib/settings/settingsDefaults.js` | Library | Default values for all settings sections |

## Database Files

| # | File | Type | Purpose |
|---|------|------|---------|
| 17 | `migrations/...create_organization_settings.js` | Migration | Creates `organization_settings` table |
| 18 | `migrations/...create_hall_settings.js` | Migration | Creates `hall_settings` table |
| 19 | `migrations/...create_user_settings.js` | Migration | Creates `user_settings` table |

## Cross-References by Concern

### Organization Settings (org scope)

| Concern | Files |
|---------|-------|
| Controller | `settings.Controller.js` — `getOrgSettings`, `updateOrgSettings` |
| Routes | `settings.routes.js` — GET/PATCH /api/settings/org |
| UI Pages | `GeneralSettingsPage.jsx`, `PaymentSettingsPage.jsx` |
| Service | `settingsService.js` — `getOrgSettings`, `updateOrgSettings` |
| Context | `SettingsContext.jsx` — global state |
| Defaults | `settingsDefaults.js` — `organizationDefaults` |
| DB Table | `organization_settings` |

### Hall Settings (hall scope)

| Concern | Files |
|---------|-------|
| Controller | `settings.Controller.js` — `getHallSettings`, `updateHallSettings` |
| Routes | `settings.routes.js` — GET/PATCH /api/settings/hall/:hallId |
| UI Pages | `CinemaProfilePage.jsx`, `ShowtimesSettingsPage.jsx`, `BookingSettingsPage.jsx` |
| Service | `settingsService.js` — `getHallSettings`, `updateHallSettings` |
| Defaults | `settingsDefaults.js` — `hallDefaults` |
| DB Table | `hall_settings` |

### User Settings (user scope)

| Concern | Files |
|---------|-------|
| Controller | `settings.Controller.js` — `getUserSettings`, `updateUserSettings` |
| Routes | `settings.routes.js` — GET/PATCH /api/settings/user |
| Service | (handled inline or via generic API client) |
| DB Table | `user_settings` |

### Legacy Payment Settings

| Concern | Files |
|---------|-------|
| Controller | `settings.Controller.js` — `getSettings`, `updateSettings` |
| Routes | `settings.routes.js` — GET/PUT /api/settings |
| Service | `services/api.js` — `settingsAPI.getSettings`, `settingsAPI.updateSettings` |

### UI Components (shared)

| Component | Used By |
|-----------|---------|
| `SettingsCard.jsx` | All settings pages |
| `SettingsPageHeader.jsx` | All settings pages |

## File Dependency Chain

```
settingsDefaults.js
       │
       ▼
settings.Controller.js ◄── settings.routes.js
       │
       ├── organization_settings (DB)
       ├── hall_settings (DB)
       └── user_settings (DB)

SettingsContext.jsx ◄── settingsService.js ◄── settings.Controller.js
       │
       ├── SettingsLayout.jsx
       │     └── GeneralSettingsPage.jsx
       │     └── PaymentSettingsPage.jsx
       │     └── BookingSettingsPage.jsx
       │     └── ShowtimesSettingsPage.jsx
       │     └── CinemaProfilePage.jsx
       │     └── RolesPermissionsPage.jsx
       │     └── TeamManagementPage.jsx
       └── SettingsCard.jsx
       └── SettingsPageHeader.jsx
```
