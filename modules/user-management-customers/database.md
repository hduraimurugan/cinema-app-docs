# Database — User Management & Customers

## Table: `customers`

The `customers` table is the primary data source for this module. Its schema is shared with the Authentication module.

| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | UUID | PK, DEFAULT gen_random_uuid() | Unique identifier |
| `name` | VARCHAR(255) | NOT NULL | Customer's full name |
| `email` | VARCHAR(255) | NOT NULL, UNIQUE | Login email |
| `phone` | VARCHAR(20) | NOT NULL, UNIQUE | Phone number |
| `password_hash` | TEXT | NOT NULL | Bcrypt hash |
| `location` | VARCHAR(255) | NULLABLE | Geographical location |
| `is_verified` | BOOLEAN | DEFAULT false | Email/phone verified flag |
| `is_active` | BOOLEAN | DEFAULT true | Account active flag |
| `refresh_token` | TEXT | NULLABLE | Current refresh token |
| `reset_password_token` | TEXT | NULLABLE | Password reset token |
| `reset_password_expires` | TIMESTAMPTZ | NULLABLE | Reset token expiry |
| `created_at` | TIMESTAMPTZ | DEFAULT NOW() | Row creation time |
| `updated_at` | TIMESTAMPTZ | DEFAULT NOW() | Last update time |

## Indexes

- `idx_customers_email` on `email` (unique)
- `idx_customers_phone` on `phone` (unique)
- `idx_customers_name` on `name` (for ILIKE search)
- `idx_customers_created_at` on `created_at` (for ordered listing)

## Queries Used

### Search Customers (ILIKE)

```sql
SELECT c.*, COUNT(b.id) AS booking_count
FROM customers c
LEFT JOIN bookings b ON b.customer_id = c.id
WHERE c.name ILIKE $1 OR c.email ILIKE $1 OR c.phone ILIKE $1
GROUP BY c.id
ORDER BY c.created_at DESC
LIMIT $2 OFFSET $3;
```

### Verified Count

```sql
SELECT COUNT(*) FROM customers WHERE is_verified = true;
```

### Recent Bookings for a Customer

```sql
SELECT b.id, m.title AS movie_title, h.name AS hall_name,
       b.show_time, b.status, b.total_amount, b.created_at
FROM bookings b
JOIN movies m ON m.id = b.movie_id
JOIN halls h ON h.id = b.hall_id
WHERE b.customer_id = $1
ORDER BY b.created_at DESC
LIMIT 10;
```

### Active Sessions for a Customer

```sql
SELECT id, created_at, expires_at
FROM sessions
WHERE customer_id = $1 AND expires_at > NOW();
```
