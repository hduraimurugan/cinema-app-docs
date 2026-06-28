# File Reference — User Management & Customers

## Backend Files

| # | File | Purpose | Key Exports |
|---|---|---|---|
| 1 | `cinema-hall-api/controllers/customers.Controller.js` | Controller with `getAllCustomers` and `getCustomerDetails` | `getAllCustomers`, `getCustomerDetails` |
| 2 | `cinema-hall-api/routes/customers.routes.js` | Route definitions, both protected by `verifySuperAdmin` | Router with `GET /` and `GET /:id` |

## Admin Frontend Files

| # | File | Purpose | Key Exports |
|---|---|---|---|
| 3 | `src/pages/UsersPage.jsx` | Admin customer list with search, pagination, stats | `UsersPage` (default) |
| 4 | `src/pages/AdminsPage.jsx` | Admin user list with search, pagination, hall info, logs | `AdminsPage` (default) |
| 5 | `src/services/api.js` | API service layer | `customersAPI`, `adminsAPI` |

## User App Frontend Files

| # | File | Purpose | Key Exports |
|---|---|---|---|
| 6 | `src/pages/UsersPage.jsx` | Customer-facing account info page | `UsersPage` (default) |
| 7 | `src/pages/ProfilePage.jsx` | Edit name, phone, location | `ProfilePage` (default) |
| 8 | `src/pages/SettingsPage.jsx` | Customer settings/preferences | `SettingsPage` (default) |

## Database

| Object | Purpose |
|---|---|
| `customers` table | Primary data storage for all customer records |
| `idx_customers_email` | Unique index on email |
| `idx_customers_phone` | Unique index on phone |
| `idx_customers_name` | Index for ILIKE search on name |
| `idx_customers_created_at` | Index for ordered listing |

## Dependencies & Relationships

```
customers.routes.js
  └─> imports customers.Controller.js
  └─> imports verifySuperAdmin middleware

Admin UsersPage.jsx
  └─> imports customersAPI from services/api.js

Admin AdminsPage.jsx
  └─> imports adminsAPI from services/api.js

User UsersPage.jsx
  └─> imports auth context for current user data

ProfilePage.jsx
  └─> calls profile update endpoint via API service

SettingsPage.jsx
  └─> calls settings update endpoint via API service
```

## Related Modules

| Module | Relationship |
|---|---|
| **Authentication** | Shares `customers` table schema; provides `verifySuperAdmin` middleware |
| **Bookings** | Provides booking data shown in customer details (`recentBookings`) |
| **Movies** | Provides movie titles for booking display |
| **Halls** | Provides hall names for booking display |
