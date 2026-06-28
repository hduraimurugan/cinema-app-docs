# Components — User Management & Customers

## Admin Pages

### `UsersPage.jsx` (Admin)

**Path:** `src/pages/UsersPage.jsx`

The admin customer list page. Provides a searchable, paginated table of all customers with aggregate statistics.

**Features:**
- Search input (filters by name, email, phone via ILIKE)
- Paginated results table
- Stats bar showing total customers and verified count
- Each row links to customer detail view
- Role-gated — only accessible by Super Admin

**State:**
- `customers` — array of customer objects
- `pagination` — `{ total, verifiedCount, page, limit, totalPages }`
- `search` — current search term
- `loading` — boolean
- `error` — error string or null

**Data Flow:**
```
UsersPage mounts
  └─> calls customersAPI.getAll({ search: "", page: 1, limit: 10 })
       └─> setCustomers(response.data.customers)
       └─> setPagination(response.data.pagination)
  └─> user types in search (debounced)
       └─> calls customersAPI.getAll({ search, page: 1, limit: 10 })
  └─> user clicks page
       └─> calls customersAPI.getAll({ search, page, limit })
```

---

### `AdminsPage.jsx` (Admin)

**Path:** `src/pages/AdminsPage.jsx`

Lists admin users for Super Admin oversight. Displays admin details including associated hall information.

**Features:**
- Search input (filters admin list)
- Paginated results
- Shows hall assignment per admin
- View activity logs action per admin row

**State:**
- `admins` — array of admin user objects (including hall info)
- `pagination` — pagination state
- `search` — current search term
- `logs` — modal/pane state for viewing admin logs
- `loading` — boolean
- `error` — error string or null

**Data Flow:**
```
AdminsPage mounts
  └─> calls adminsAPI.getAll({ search: "", page: 1, limit: 10 })
  └─> user clicks "View Logs" on an admin row
       └─> calls adminsAPI.getLogs(adminId)
       └─> opens logs modal/pane
```

## User App Pages

### `ProfilePage.jsx` (Customer)

**Path:** `src/pages/ProfilePage.jsx`

Allows customers to view and edit their personal information.

**Editable Fields:**
- Name
- Phone
- Location

**Behavior:**
- Pre-populated with current customer data
- Validates inputs before submission
- Calls PUT endpoint on save
- Shows success/error feedback

**State:**
- `profile` — `{ name, phone, location }`
- `isEditing` — boolean toggle
- `loading` — boolean
- `saving` — boolean
- `error` — error string or null
- `success` — success message string or null

---

### `SettingsPage.jsx` (Customer)

**Path:** `src/pages/SettingsPage.jsx`

Customer-facing settings page. Allows account-level configuration.

**Settings options (typical):**
- Notification preferences
- Language/locale
- Theme preference (if applicable)
- Account actions (deactivate, delete)

**State:**
- `settings` — object of setting key/value pairs
- `loading` — boolean
- `saving` — boolean
- `error` — error string or null
- `success` — success message string or null

---

### `UsersPage.jsx` (Customer)

**Path:** `src/pages/UsersPage.jsx`

Customer-facing user information page. Displays the authenticated customer's account details in a read-only view (distinct from the admin `UsersPage`).

**Features:**
- Read-only display of account information
- Link to `ProfilePage` for editing
- Link to `SettingsPage` for preferences
- Shows account creation date, verification status
