# Frontend: Settings Module

## Pages

All settings pages live in `src/pages/settings/`.

| Page | Path | Purpose |
|------|------|---------|
| `SettingsLayout.jsx` | `/admin/settings` | Container with navigation tabs for all settings sub-pages. Renders an outlet for nested routes. |
| `GeneralSettingsPage.jsx` | `/admin/settings/general` | Organization name, timezone, currency, language. |
| `BookingSettingsPage.jsx` | `/admin/settings/booking` | Max seats per booking, advance booking days, hold minutes, cancellation policy. |
| `PaymentSettingsPage.jsx` | `/admin/settings/payment` | Convenience fee model/amount, GST percentage, applicable states/taxes. |
| `ShowtimesSettingsPage.jsx` | `/admin/settings/showtimes` | Default buffer minutes, overlap prevention, default language version, status transitions. |
| `CinemaProfilePage.jsx` | `/admin/settings/cinema-profile` | Hall name, address, district, state, phone, description, operating hours. |
| `RolesPermissionsPage.jsx` | `/admin/settings/roles` | Role management (delegated to Roles module). |
| `TeamManagementPage.jsx` | `/admin/settings/team` | Team member management (delegated to Team module). |

### SettingsLayout Tabs

| Tab | Page | Scope |
|-----|------|-------|
| General | GeneralSettingsPage | Organization |
| Cinema Profile | CinemaProfilePage | Hall |
| Showtimes | ShowtimesSettingsPage | Hall |
| Booking | BookingSettingsPage | Hall |
| Payment | PaymentSettingsPage | Organization |
| Roles & Permissions | RolesPermissionsPage | Organization (cross-module) |
| Team | TeamManagementPage | Organization (cross-module) |

## Services

### settingsService.js

**File:** `src/services/settings/settingsService.js`

| Function | API Call | Description |
|----------|----------|-------------|
| `getOrgSettings()` | GET /api/settings/org | Fetch all org settings + org info |
| `updateOrgSettings(section, value)` | PATCH /api/settings/org | Update org settings section |
| `getHallSettings(hallId)` | GET /api/settings/hall/:hallId | Fetch all hall settings |
| `updateHallSettings(hallId, section, value)` | PATCH /api/settings/hall/:hallId | Update hall settings section |

### Legacy API in services/api.js

| Function | API Call | Description |
|----------|----------|-------------|
| `settingsAPI.getSettings()` | GET /api/settings | Legacy — returns payment settings only |
| `settingsAPI.updateSettings(data)` | PUT /api/settings | Legacy — updates payment settings only |

## Context

### SettingsContext.jsx

**File:** `src/context/SettingsContext.jsx`

Provides global settings state to the admin application.

**On mount:** Fetches org settings via `getOrgSettings()`.

**Provides:**
- `settings` — the full settings object (all sections).
- `settingsLoading` — boolean, true while initial fetch is in progress.
- `updateSettings(section, value)` — calls `updateOrgSettings` and updates local state optimistically.

```jsx
import { useSettings } from '@/context/SettingsContext';

function MyComponent() {
  const { settings, updateSettings } = useSettings();

  return (
    <div>
      <p>Timezone: {settings.general?.timezone}</p>
      <button onClick={() => updateSettings('general', { timezone: 'UTC' })}>
        Reset Timezone
      </button>
    </div>
  );
}
```

## Data Flow

```
SettingsContext (mount)
       │
       ▼
getOrgSettings() ────────────► PATCH /api/settings/org
       │                              ▲
       ▼                              │
 settings object ◄──── updateSettings()
       │
       ▼
    Pages read via context
       │
       ├── GeneralSettingsPage
       ├── PaymentSettingsPage
       ├── BookingSettingsPage
       ├── ShowtimesSettingsPage
       ├── CinemaProfilePage
       └── (Roles, Team via other modules)
```

Hall settings are fetched separately per-page using `getHallSettings(hallId)` when the user navigates to a hall-scoped settings page. They are not stored in the global SettingsContext.
