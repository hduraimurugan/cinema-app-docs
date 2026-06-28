# Hall Management Module

## Module Purpose
Manage the lifecycle of cinema halls within an organization — create, edit, delete, and switch between halls. Screens, shows, and bookings are scoped per hall, making hall management the foundational module for all cinema operations.

## Business Objective
Provide cinema operators a unified interface to manage their physical cinema locations. Each hall acts as an organizational unit that screens, shows, and bookings belong to. Admins can own multiple halls and switch between them to manage each location independently.

## Features
- **CRUD Operations**: Create, edit, delete cinema halls with full metadata
- **Geographic Scoping**: State/district dropdowns from `country-state-city` library
- **Map Integration**: Leaflet-based interactive map with click-to-pin and OpenStreetMap search for precise lat/lng
- **Active Hall Switching**: Dropdown hall switcher in the navbar; active hall persists in `localStorage`
- **Active/Inactive Toggle**: Soft-disable halls without losing data
- **Role-Based Access**: Owner/Admin see all org halls; staff see assigned halls via `hall_assignments`; SuperAdmin scoped to their own org
- **CASCADE Delete**: Deleting a hall removes all screens, shows, and bookings
- **Onboarding Flow**: First-time admin with no halls is redirected to `/onboarding`
- **Hall Guard**: Route-level protection ensuring admin has at least one hall before accessing hall-scoped features

## User Roles Involved
- **Super Admin**: Manage halls within their own organization
- **Cinema Owner/Admin**: Full CRUD on halls within their organization
- **Staff**: Access only assigned halls via `hall_assignments` table
- **Customer**: Browse halls via location-based endpoints (read-only, handled by user API)

## Dependencies
- **React Leaflet / Leaflet**: Map picker for hall location (lat/lng)
- **country-state-city**: Indian state and district dropdown data
- **OpenStreetMap (Nominatim)**: Map search geocoding
- **PostgreSQL**: `cinema_hall` and `hall_assignments` tables
- **shadcn/ui**: UI component library (Sheet, Table, DropdownMenu, AlertDialog, etc.)

## Related Modules
- [Screen Management](../screen-management/README.md) - Screens belong to a hall
- [Show Management](../show-management/README.md) - Shows are scoped to hall screens
- [Authentication](../authentication/README.md) - Admin auth and role resolution
- [Settings](../settings/README.md) - Organization-level configuration
