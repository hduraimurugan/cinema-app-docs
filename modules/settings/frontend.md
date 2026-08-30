# Frontend: Settings Module

## Permission-aware Navigation

Settings navigation is generated from the shared admin page-permission catalog (`src/config/pagePermissions.js`). Organization, cinema-branch, and management sections are shown only when the active admin can read them. The index route selects the first accessible **non-disabled** section instead of always redirecting to General (`SettingsIndexRedirect` at `src/pages/settings/SettingsLayout.jsx:38`, updated `f7952e5` to skip `DISABLED_PATHS`).

`SettingsLayout` (`src/pages/settings/SettingsLayout.jsx:82`) now renders a sticky horizontal tab bar (`SettingsTabBar` at line 140, `f7952e5`) instead of the previous `w-64` sticky sidebar. Groups are separated by vertical dividers (`w-px bg-border/50`), the strip is `overflow-x-auto` with hidden scrollbar, and the active tab is underlined via `Motion.div layoutId="settings-tab-underline"` (spring 500/40). A dirty section shows a single `h-1.5 w-1.5 bg-amber-500` dot next to the label when `!disabled && isSectionDirty(scope, sectionKey)` — the previous `Badge` (`unsaved` with `group-hover` reveal) and `layoutId="settings-nav-active"` background were removed. Three sections are temporarily disabled (`DISABLED_PATHS` at line 12: `cinema-profile`, `showtimes`, `booking`): rendered as `aria-disabled` with a `Soon` badge, `title="Coming soon"`, `cursor-not-allowed`, and never show dirty state.

## Pages

All settings pages live in `src/pages/settings/`.

| Page | Path | Purpose |
|------|------|---------|
| `SettingsLayout.jsx` | `/admin/settings` (`src/pages/settings/SettingsLayout.jsx:82`) | Sticky horizontal tab bar + outlet for nested routes. `f7952e5`: `DISABLED_PATHS` (`cinema-profile`, `showtimes`, `booking` → `Soon`), dirty dot (`isSectionDirty`), active underline (`settings-tab-underline`). |
| `GeneralSettingsPage.jsx` | `/admin/settings/general` | Organization name, timezone, currency, language. Full-width `space-y-6` layout (`a8796a4`). |
| `BookingSettingsPage.jsx` | `/admin/settings/booking` | Max seats per booking, advance booking days, hold minutes, cancellation policy. |
| `PaymentSettingsPage.jsx` | `/admin/settings/payment` | Convenience fee model/amount, GST percentage, applicable states/taxes. Full-width `space-y-6` layout (`a8796a4`); non-super-admin sees read-only stat cards. |
| `ShowtimesSettingsPage.jsx` | `/admin/settings/showtimes` | Default buffer minutes, overlap prevention, default language version, status transitions. |
| `CinemaProfilePage.jsx` | `/admin/settings/cinema-profile` | Hall name, address, district, state, phone, description, operating hours. |
| `RolesPermissionsPage.jsx` | `/admin/settings/roles` | Role management (delegated to Roles module). |
| `TeamManagementPage.jsx` | `/admin/settings/team` | Team member management (delegated to Team module). |

### SettingsLayout Tabs (`f7952e5`)

| Tab | Page | Scope | State |
|-----|------|-------|-------|
| General | GeneralSettingsPage | Organization | enabled |
| Cinema Profile | CinemaProfilePage | Hall | **disabled** — `Soon` badge, `aria-disabled` |
| Showtimes | ShowtimesSettingsPage | Hall | **disabled** — `Soon` |
| Booking | BookingSettingsPage | Hall | **disabled** — `Soon` |
| Payment | PaymentSettingsPage | Organization | enabled |
| Roles & Permissions | RolesPermissionsPage | Organization (cross-module) | enabled |
| Team | TeamManagementPage | Organization (cross-module) | enabled |

Disabled tabs are in `DISABLED_PATHS` (`src/pages/settings/SettingsLayout.jsx:12`) and are skipped by `SettingsIndexRedirect` (line 41).

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
