# Workflows — User Management & Customers

## Workflow 1: Admin Searches Customers

```
[Admin] opens UsersPage
  │
  ├─> Page calls customersAPI.getAll({ search: "", page: 1, limit: 10 })
  │     └─> GET /api/customers (verifySuperAdmin)
  │           └─> Query: SELECT with LEFT JOIN bookings, GROUP BY, ILIKE, LIMIT/OFFSET
  │           └─> Returns: { customers[], total, verifiedCount, page, limit, totalPages }
  │
  ├─> Admin types search term
  │     └─> Debounced API call with search param
  │     └─> Table updates with filtered results
  │     └─> Stats bar updates (total/verified recount for filtered set)
  │
  └─> Admin clicks pagination
        └─> API call with new page number
        └─> Table renders next page
```

## Workflow 2: Admin Views Customer Details

```
[Admin] clicks a customer row
  │
  ├─> Navigate to /admin/users/:id
  │
  ├─> Page calls customersAPI.getDetails(id)
  │     └─> GET /api/customers/:id (verifySuperAdmin)
  │           └─> Query 1: SELECT customer by id
  │           └─> Query 2: SELECT recent 10 bookings (JOIN movies, halls)
  │           └─> Query 3: SELECT active sessions (WHERE expires_at > NOW())
  │
  └─> Renders:
        ├─> Customer profile card (name, email, phone, location, status)
        ├─> Recent bookings table (movie, hall, time, status, amount)
        └─> Active sessions list (session ID, created, expires)
```

## Workflow 3: Admin Manages Other Admins

```
[Super Admin] opens AdminsPage
  │
  ├─> Page calls adminsAPI.getAll({ search: "", page: 1, limit: 10 })
  │     └─> Returns: { admins[], total, page, limit, totalPages }
  │
  ├─> Page displays admin list with hall assignments
  │
  └─> Super Admin clicks "View Logs" on an admin
        └─> calls adminsAPI.getLogs(adminId)
        └─> Opens modal/pane showing audit trail
```

## Workflow 4: Customer Edits Profile

```
[Customer] navigates to ProfilePage
  │
  ├─> Form pre-filled with current name, phone, location
  │
  ├─> Customer edits fields
  │
  ├─> Customer clicks Save
  │     └─> Client-side validation
  │     └─> PUT /api/profile { name, phone, location }
  │           └─> Backend validates + updates DB
  │           └─> Returns updated profile
  │     └─> UI shows success message
  │     └─> Global auth context optionally refreshed
  │
  └─> Customer clicks Cancel
        └─> Form reverts to original values
```

## Workflow 5: Customer Views Account

```
[Customer] navigates to UsersPage (/account)
  │
  ├─> Displays read-only account information
  │     ├─> Name, email, phone, location
  │     ├─> Verification status
  │     ├─> Member since date
  │
  └─> Quick links to ProfilePage (edit) and SettingsPage (preferences)
```

## Workflow 6: Customer Manages Settings

```
[Customer] navigates to SettingsPage
  │
  ├─> Loads current settings (notifications, language, etc.)
  │
  ├─> Customer toggles/changes settings
  │
  └─> Customer clicks Save
        └─> PUT /api/settings { ... }
        └─> Backend updates preferences
        └─> UI shows success feedback
```
