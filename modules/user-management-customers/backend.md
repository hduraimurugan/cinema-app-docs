# Backend — User Management & Customers

## Controller: `customers.Controller.js`

**Path:** `cinema-hall-api/controllers/customers.Controller.js`

### `getAllCustomers`

| Property | Value |
|---|---|
| Method | GET |
| Route | `/api/customers` |
| Middleware | `verifySuperAdmin` |
| Auth | Super Admin only |

**Query Parameters:**

| Param | Type | Default | Description |
|---|---|---|---|
| `search` | string | — | ILIKE filter on name, email, phone |
| `page` | integer | 1 | Page number |
| `limit` | integer | 10 | Items per page |

**Response shape:**

```json
{
  "customers": [
    {
      "id": "uuid",
      "name": "string",
      "email": "string",
      "phone": "string",
      "location": "string | null",
      "is_verified": "boolean",
      "created_at": "timestamp",
      "booking_count": "number"
    }
  ],
  "total": "number",
  "verifiedCount": "number",
  "page": "number",
  "limit": "number",
  "totalPages": "number"
}
```

- `booking_count` is computed per customer via a JOIN/subquery on the bookings table.
- `total` is the total number of customers matching the search filter.
- `verifiedCount` is the count of verified customers matching the search filter.

### `getCustomerDetails`

| Property | Value |
|---|---|
| Method | GET |
| Route | `/api/customers/:id` |
| Middleware | `verifySuperAdmin` |
| Auth | Super Admin only |

**Response shape:**

```json
{
  "customer": {
    "id": "uuid",
    "name": "string",
    "email": "string",
    "phone": "string",
    "location": "string | null",
    "is_verified": "boolean",
    "is_active": "boolean",
    "created_at": "timestamp",
    "updated_at": "timestamp"
  },
  "recentBookings": [
    {
      "id": "uuid",
      "movie_title": "string",
      "hall_name": "string",
      "show_time": "timestamp",
      "status": "string",
      "total_amount": "number",
      "created_at": "timestamp"
    }
  ],
  "activeSessions": [
    {
      "id": "uuid",
      "created_at": "timestamp",
      "expires_at": "timestamp"
    }
  ]
}
```

- `recentBookings` — last 10 bookings for the customer (ordered by `created_at` DESC).
- `activeSessions` — non-expired sessions for the customer from the sessions table.

## Routes: `customers.routes.js`

**Path:** `cinema-hall-api/routes/customers.routes.js`

```javascript
router.get("/", verifySuperAdmin, customersController.getAllCustomers);
router.get("/:id", verifySuperAdmin, customersController.getCustomerDetails);
```

Both routes are protected by `verifySuperAdmin` middleware. No public routes exist for customer data retrieval.
