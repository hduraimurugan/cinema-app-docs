# Settings Module

Three-tier settings system supporting organization-level, hall-level, and user-level configuration through JSONB columns for flexible, schema-less storage.

## Architecture Overview

```
┌─────────────────────────────────────────────────┐
│                 Settings Module                   │
├──────────┬──────────┬────────────────────────────┤
│   Org    │   Hall   │          User              │
│ Settings │ Settings │        Settings             │
├──────────┼──────────┼────────────────────────────┤
│ general  │ cinema_  │ notifications              │
│ payment  │  profile │ analytics                  │
│ tickets  │ showtimes│ appearance                 │
│ security │ booking  │                            │
│ notifica │ offers   │                            │
│ tions    │          │                            │
│ branding │          │                            │
│ integra  │          │                            │
│ tions    │          │                            │
│ advanced │          │                            │
└──────────┴──────────┴────────────────────────────┘
         │              │              │
         ▼              ▼              ▼
  organization_    hall_settings   user_settings
    settings       (JSONB)         (JSONB)
    (JSONB)
```

## Key Design Decisions

- **JSONB columns** — each scope has one row per section. Values are flexible JSON objects, no migration needed for new fields.
- **Deep-merge strategy** — PATCH sends only changed fields which are merged into the existing JSONB value.
- **Three tiers** — organization settings apply globally, hall settings override per-venue, user settings customize individual admin experience.
- **Seeded on onboarding** — all sections get default values from `settingsDefaults.js` when an organization or hall is created.
- **org_name source of truth** — organization name lives in `organizations.name`, not in the settings JSONB, to maintain referential integrity.

## Scope Diagram

| Scope | Table | Sections | Auth Required |
|-------|-------|----------|---------------|
| Organization | `organization_settings` | general, payment, tickets, security, notifications, branding, integrations, advanced | SuperAdmin |
| Hall | `hall_settings` | cinema_profile, showtimes, booking, offers | ActiveHall access |
| User | `user_settings` | notifications, analytics, appearance | Any authenticated admin |

## Directory Structure

```
docs/modules/settings/
├── README.md              ← This file
├── backend.md             ← Controllers, routes, defaults
├── database.md            ← Schema and table reference
├── api.md                 ← API endpoint reference
├── frontend.md            ← Pages and service layer
├── components.md          ← Reusable UI components
├── workflows.md           ← Common operations and flows
└── file-reference.md      ← Cross-reference of all files
```
