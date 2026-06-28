# Hall Management - Backend

## Routes

### `halls.routes.js`
- **Path**: `routes/halls.routes.js`
- **Purpose**: Cinema hall CRUD endpoints
- **Middleware**: All routes use `verifyCinemaAdminAccessToken` only. `requireActiveHall` is intentionally omitted — these routes manage halls themselves, not data within a hall.

| Endpoint | Method | Controller |
|----------|--------|------------|
| `/api/halls` | GET | `getMyHalls` |
| `/api/halls` | POST | `createHall` |
| `/api/halls/:id` | PUT | `updateHall` |
| `/api/halls/:id` | DELETE | `deleteHall` |

## Controllers

### `halls.Controller.js`
- **Path**: `controllers/halls.Controller.js`

| Function | Purpose |
|----------|---------|
| `getMyHalls` | Returns halls scoped to the admin's organization. SuperAdmin → org-scoped (same as owner/admin). Owner/Admin role → all halls in their org. Staff/other roles → halls via `hall_assignments` JOIN. Returns only `is_active = TRUE` halls, ordered by `created_at ASC`. |
| `createHall` | Creates a new hall with name, location, district, state, latitude, longitude, phone, description. Validates required fields (name, location, district, state). Resolves `orgId` from `req.admin.orgId` or falls back to querying `organization_members`. Returns 400 if user has no org. |
| `updateHall` | Updates hall fields using `COALESCE` for partial updates. Access check: superAdmin bypass, then checks org_id matches + role is owner/admin or hall.admin_id matches. Returns 403 if hall not found or access denied. |
| `deleteHall` | CASCADE deletes hall (FK constraints remove screens → shows → bookings). Same access check logic as `updateHall`. Returns 200 with success message or 403. |

### Access Control Logic
All mutating endpoints follow the same pattern:
1. If `req.admin.role === 'superAdmin'` → grant access immediately
2. Look up the admin's `organization_members` record (active status)
3. Check that the hall's `org_id` matches the member's `org_id`
4. Grant access if role is `owner` or `admin`, or if `hall.admin_id === req.admin.id`
5. Deny with 403 otherwise

For `getMyHalls`, the query varies by role: owner/admin get all org halls via `org_id` filter; other roles get halls through `hall_assignments` JOIN.
