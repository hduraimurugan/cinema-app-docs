# Frontend — User Management & Customers

## Admin Frontend

### API Service (`services/api.js`)

**`customersAPI`**

```javascript
customersAPI.getAll({ search, page, limit })
// -> GET /api/customers?search=...&page=...&limit=...
// -> Returns { customers[], total, verifiedCount, page, limit, totalPages }

customersAPI.getDetails(id)
// -> GET /api/customers/:id
// -> Returns { customer, recentBookings[], activeSessions[] }
```

**`adminsAPI`**

```javascript
adminsAPI.getAll({ search, page, limit })
// -> GET /api/admins?search=...&page=...&limit=...
// -> Returns { admins[], total, page, limit, totalPages }

adminsAPI.getLogs(id)
// -> GET /api/admins/:id/logs
// -> Returns { logs[] }
```

### Pages

| Page | Route (approx) | Description |
|---|---|---|
| `UsersPage.jsx` | `/admin/users` | Customer list with stats |
| `AdminsPage.jsx` | `/admin/admins` | Admin user list |

### Routing & Guards

Both admin pages are protected by a route guard that checks for Super Admin role. If the authenticated user is not a Super Admin, they are redirected to a 403 or dashboard page.

```javascript
// Conceptual guard
<Route
  path="/admin/users"
  element={
    <RequireAdmin>
      <UsersPage />
    </RequireAdmin>
  }
/>
```

## User App Frontend

### Pages

| Page | Route (approx) | Description |
|---|---|---|
| `UsersPage.jsx` | `/account` | Account info (read-only) |
| `ProfilePage.jsx` | `/account/profile` | Edit name, phone, location |
| `SettingsPage.jsx` | `/account/settings` | Preferences & account actions |

### State Management

User profile data is typically fetched on app load and stored in a global/auth context so it's available across all user pages. Mutations (profile update, settings update) update the local state and optionally refresh the global context.

### Typical Data Flow

```
[ProfilePage] --PUT /api/profile--> [Backend] --update DB--> [Success]
      |                                                                |
      └--------< update local state <----------< response <-----------┘
```

```
[SettingsPage] --PUT /api/settings--> [Backend] --update DB--> [Success]
      |                                                                  |
      └--------< update local state <----------< response <-------------┘
```
