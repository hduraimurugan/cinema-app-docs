# API Reference — User Management & Customers

## Admin Endpoints

### GET /api/customers

List all customers with pagination and search (Super Admin only).

**Authentication:** Bearer token (Super Admin role required)

**Query Parameters:**

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `search` | string | No | — | Search term for name, email, or phone (ILIKE) |
| `page` | integer | No | 1 | Page number |
| `limit` | integer | No | 10 | Items per page |

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "customers": [
      {
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "location": "New York",
        "is_verified": true,
        "is_active": true,
        "created_at": "2025-01-15T10:30:00Z",
        "booking_count": 12
      }
    ],
    "pagination": {
      "total": 150,
      "verifiedCount": 98,
      "page": 1,
      "limit": 10,
      "totalPages": 15
    }
  }
}
```

**Error Responses:**

| Code | Condition |
|---|---|
| 401 | Missing or invalid token |
| 403 | User is not a Super Admin |
| 500 | Server error |

---

### GET /api/customers/:id

Get detailed information about a specific customer (Super Admin only).

**Authentication:** Bearer token (Super Admin role required)

**Path Parameters:**

| Name | Type | Description |
|---|---|---|
| `id` | UUID | Customer ID |

**Success Response (200):**

```json
{
  "success": true,
  "data": {
    "customer": {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "John Doe",
      "email": "john@example.com",
      "phone": "+1234567890",
      "location": "New York",
      "is_verified": true,
      "is_active": true,
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-06-20T14:00:00Z"
    },
    "recentBookings": [
      {
        "id": "660e8400-e29b-41d4-a716-446655440001",
        "movie_title": "Inception",
        "hall_name": "Hall A",
        "show_time": "2025-06-25T19:00:00Z",
        "status": "completed",
        "total_amount": 25.00,
        "created_at": "2025-06-20T10:00:00Z"
      }
    ],
    "activeSessions": [
      {
        "id": "770e8400-e29b-41d4-a716-446655440002",
        "created_at": "2025-06-28T08:00:00Z",
        "expires_at": "2025-06-28T20:00:00Z"
      }
    ]
  }
}
```

**Error Responses:**

| Code | Condition |
|---|---|
| 401 | Missing or invalid token |
| 403 | User is not a Super Admin |
| 404 | Customer not found |
| 500 | Server error |

## Frontend API Service Methods

### `customersAPI.getAll({ search, page, limit })`

Calls `GET /api/customers` with query parameters. Returns paginated customer list.

### `customersAPI.getDetails(id)`

Calls `GET /api/customers/:id`. Returns customer profile, recent bookings, and active sessions.

### `adminsAPI.getAll({ search, page, limit })`

Calls the admins endpoint with pagination and search. Returns admin user list.

### `adminsAPI.getLogs(id)`

Calls the admin activity logs endpoint. Returns audit trail for a specific admin.
