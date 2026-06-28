# Components: Settings Module

## SettingsCard

**File:** `src/components/settings/SettingsCard.jsx`

Reusable wrapper card for a single settings section. Used consistently across all settings pages.

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | string | — | Section title displayed in card header |
| `description` | string | — | Helper text explaining the section |
| `children` | ReactNode | — | Form fields or content |
| `loading` | boolean | false | Shows skeleton placeholder while loading |
| `saving` | boolean | false | Disables form and shows saving indicator |
| `error` | string | — | Error message banner |
| `onSave` | function | — | Called with form data on save |
| `actions` | ReactNode | — | Custom action buttons (defaults to Save) |

### Usage

```jsx
<SettingsCard
  title="Timezone"
  description="Set the default timezone for all showtimes and reports."
  loading={settingsLoading}
  saving={isSaving}
  onSave={handleSave}
>
  <TimezoneSelector value={timezone} onChange={setTimezone} />
</SettingsCard>
```

### States

| State | Behavior |
|-------|----------|
| **Default** | Renders title, description, children, save button |
| **Loading** | Shows skeleton placeholder — children are hidden |
| **Saving** | Save button shows spinner, inputs are disabled |
| **Error** | Error banner appears above children (auto-dismiss optional) |
| **Success** | Brief success toast, button resets to default |

### Styling

- Card with subtle border and rounded corners
- Header with title and description in muted typography
- Padding consistent with design system spacing tokens
- Save button aligned to bottom-right

## SettingsPageHeader

**File:** `src/components/settings/SettingsPageHeader.jsx`

Consistent header rendered at the top of each settings page.

### Props

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `title` | string | — | Page title |
| `description` | string | — | Brief description of the page purpose |
| `backLink` | string | — | Optional back navigation link |
| `actions` | ReactNode | — | Additional header actions (e.g., "Reset to defaults") |

### Usage

```jsx
<SettingsPageHeader
  title="General Settings"
  description="Manage your organization's basic configuration."
/>
```

## Component Tree

```
SettingsLayout
├── SettingsPageHeader
├── Tab Navigation
└── Outlet
    ├── GeneralSettingsPage
    │   └── SettingsCard (general)
    ├── PaymentSettingsPage
    │   ├── SettingsCard (convenience fee)
    │   └── SettingsCard (GST)
    ├── BookingSettingsPage
    │   ├── SettingsCard (limits)
    │   └── SettingsCard (cancellation)
    ├── ShowtimesSettingsPage
    │   ├── SettingsCard (buffer & overlap)
    │   ├── SettingsCard (language defaults)
    │   └── SettingsCard (advance booking)
    └── CinemaProfilePage
        ├── SettingsCard (basic info)
        ├── SettingsCard (address)
        └── SettingsCard (operating hours)
```

Reusable components are shared across pages. Each page composes `SettingsCard` instances with form fields specific to its section's data shape.
