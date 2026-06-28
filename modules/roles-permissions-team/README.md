# Roles, Permissions & Team Management

This module provides role-based access control (RBAC) and team management for the cinema-hall multi-tenant platform. It governs what administrators can see and do within an organization.

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                   Frontend (React)                   │
│  RolesPermissionsPage  TeamManagementPage           │
│  PermissionContext (can())  AdminProtectedRoute     │
└──────────────────────┬──────────────────────────────┘
                       │ HTTP (REST)
┌──────────────────────┴──────────────────────────────┐
│              Backend (Express / Node.js)              │
│  controllers/roles.Controller.js                    │
│  middleware/requirePermission.js                    │
│  services/team.service.js                           │
│  routes/roles.routes.js                             │
│  routes/team.routes.js                              │
└──────────────────────┬──────────────────────────────┘
                       │ SQL
┌──────────────────────┴──────────────────────────────┐
│              PostgreSQL Database                      │
│  roles | permissions | role_permissions              │
│  organization_members | hall_assignments             │
│  team_invites                                        │
└─────────────────────────────────────────────────────┘
```

## Core Concepts

- **System Roles** — Pre-seeded roles (`owner`, `admin`, `manager`, `sales`, `finance`, `marketing`, `ticket_operator`, `auditor`) that cannot be deleted.
- **Custom Roles** — Organization-specific roles created by administrators with `roles.manage` permission.
- **Permission Keys** — String identifiers (e.g., `roles.read`, `bookings.create`) that gate both API endpoints and UI elements.
- **Permission Versioning** — A `permissions_version` column on roles is incremented on each update and embedded in JWTs for cache invalidation.
- **Member Status** — Members can be `active`, `suspended`, or `invited`.
- **Hall Assignments** — Optional scope restricting a member to specific cinema halls.

## File Reference

See [file-reference.md](file-reference.md) for a complete listing of every source file in this module.

## Quick Links

| Document | Description |
|---|---|
| [frontend.md](frontend.md) | React pages, components, context, and services |
| [backend.md](backend.md) | Controllers, routes, middleware, and service layer |
| [database.md](database.md) | Table schemas, constraints, indexes, and seed data |
| [api.md](api.md) | Full API reference for all endpoints |
| [components.md](components.md) | UI component API and props |
| [workflows.md](workflows.md) | End-to-end user and system workflows |
| [file-reference.md](file-reference.md) | Every source file with line counts and descriptions |
