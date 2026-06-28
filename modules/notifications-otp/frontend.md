# Notifications & OTP - Frontend

## Admin App (`cinema-hall-admin`)

### Pages

#### `Notifications.jsx`
- **Path**: `src/pages/Notifications.jsx`
- **Purpose**: Admin notification preferences and history page (placeholder)
- **State**: `notifications[]` — currently empty array (future feature)
- **Data Flow**: Empty state shows Bell icon with "No notifications yet" and "We will add notifications in future." placeholder text. When populated, renders a scrollable list with icon, title, and timestamp per notification.
- **Key Functions**:
  - Maps over `notifications` array rendering a rounded icon container, title, and relative time for each item

### Context

#### Notification Preferences (via `user_settings` table)
- Admin notification toggles are stored server-side in `user_settings` under the `notifications` section
- Section: `notifications` with JSONB value:
  ```json
  {
    "email_toggle": true,
    "sms_toggle": false,
    "push_toggle": false,
    "events": {
      "booking_confirmed": ["email"],
      "booking_cancelled": ["email"],
      "daily_report": ["email"]
    }
  }
  ```
- Managed through the [Settings module](../settings/README.md)

## User App (`cinema-hall-users`)

### Pages

#### `Notifications.jsx`
- **Path**: `src/pages/Notifications.jsx`
- **Purpose**: Customer notification settings/history page (placeholder)
- **State**: `notifications[]` — currently empty array (future feature)
- **Data Flow**: Identical empty state to admin version: Bell icon, "No notifications yet" placeholder text
- **Key Functions**:
  - Same rendering logic as admin Notifications page (icon, title, time per item)
