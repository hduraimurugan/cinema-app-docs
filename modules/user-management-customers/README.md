# User Management & Customers Module

This module handles user administration for the cinema-hall platform. It covers both customer-facing profile management and admin-facing user oversight, including search, pagination, statistics, and role-based access control.

## Scope

- **Customer management** — listing, searching, viewing details (admin)
- **Admin management** — listing admin users, viewing activity logs (super admin only)
- **Customer profile & settings** — personal information editing (customer-facing)

## Key Files

| Layer | File | Purpose |
|---|---|---|
| Backend Controller | `customers.Controller.js` | Customer CRUD + stats |
| Backend Routes | `customers.routes.js` | Route definitions |
| Admin API Service | `services/api.js` | `customersAPI`, `adminsAPI` |
| Admin Pages | `UsersPage.jsx`, `AdminsPage.jsx` | Admin interfaces |
| User Pages | `ProfilePage.jsx`, `SettingsPage.jsx` | Customer interfaces |

## Architecture

```
[Admin Panel] ──> customersAPI.getAll() ──> GET /api/customers (superAdmin)
              ──> customersAPI.getDetails() ──> GET /api/customers/:id (superAdmin)
              ──> adminsAPI.getAll() ──> GET /api/admins (superAdmin)
              ──> adminsAPI.getLogs() ──> GET /api/admins/:id/logs (superAdmin)

[User App]    ──> ProfilePage ──> PUT /api/profile
              ──> SettingsPage ──> PUT /api/settings
```

## Roles

- **Super Admin** — full access to customer list, customer details, admin list, admin logs
- **Customer** — access only to own profile and settings

## Data Source

The `customers` table in the database (shared schema with the Authentication module).
