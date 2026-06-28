# Notifications & OTP - Components

## Admin App Component Hierarchy

```
AdminLayout
 └── Notifications (page — placeholder)
      └── Empty state → Bell icon, "No notifications yet", "We will add notifications in future."
      └── Notification list (when populated, future)
           └── Notification item → rounded icon container, title, relative time
```

## User App Component Hierarchy

```
UserLayout
 └── Notifications (page — placeholder)
      └── Empty state → Bell icon, "No notifications yet", "We will add notifications in future."
      └── Notification list (when populated, future)
           └── Notification item → rounded icon container, title, relative time
```

## Component Catalog

### Admin App

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `Notifications` | `admin/src/pages/Notifications.jsx` | - | `notifications[]` (empty) | Admin Layout / Routes | Bell icon, text elements |

### User App

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `Notifications` | `users/src/pages/Notifications.jsx` | - | `notifications[]` (empty) | User Layout / Routes | Bell icon, text elements |

## Data Flow

```
┌──────────────────────┐
│   Auth Event Occurs  │
│ (login, password     │
│  change, lock, etc.) │
└────────┬─────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│      Controller / Auth Service      │
│ Calls email function from           │
│ mail/emails.js                      │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│       mail/emails.js                │
│ Builds email using template from    │
│ emailTemplate.js, sends via         │
│ transporter from mail.config.js     │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│        Nodemailer Transporter       │
│ Sends via Gmail SMTP               │
│ (MAIL_ID / MAIL_PASSWORD env vars) │
└─────────────────────────────────────┘
```
