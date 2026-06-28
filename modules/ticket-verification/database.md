# Database – Ticket Verification

## Query

The `getBookingForVerification` method in the Booking model executes a single query joining 5 tables.

### Table Relationships

```
bookings
  │
  ├── shows ── movies
  │     │
  │     └── screens ── halls
  │
  └── customers

refunds (LEFT JOIN on refunds.booking_id = booking derived)
```

### Tables Involved

| Table | Alias | Join Type | Purpose |
|---|---|---|---|
| `bookings` | `b` | Base | Booking record with payment status |
| `shows` | `s` | `JOIN` | Resolve show date and time |
| `movies` | `m` | `JOIN` | Movie title for display |
| `screens` | `sc` | `JOIN` | Screen name; also filters by `hall_id` |
| `customers` | `c` | `JOIN` | Customer name and email |
| `refunds` | `r` | `LEFT JOIN` | Refund details (may be null) |

### Hall Scoping

The query filters `sc.hall_id = ?` to ensure that a booking can only be verified against the hall the admin is currently logged into. This prevents an admin from verifying tickets for another hall's shows.

### Refund Subquery

```sql
LEFT JOIN (
  SELECT * FROM refunds WHERE booking_id = b.id
) r ON 1=1
```

This approach retrieves the refund row associated with the booking. Because it is a lateral correlation (referencing `b.id`), it returns at most one refund row per booking.

### Seat Labels Aggregation

Seats are stored in a separate `booked_seats` table (each seat per row). The query uses `STRING_AGG(st.label, ', ')` to flatten all seats into a comma-separated string for display.

### Indexes Used

| Table | Index | Benefit |
|---|---|---|
| `bookings` | `idx_bookings_booking_id` | Fast lookup by UUID string |
| `screens` | `idx_screens_hall_id` | Hall-scoping filter |
| `shows` | `idx_shows_id` | Join to shows |
| `movies` | `idx_movies_id` | Join to movies |
| `customers` | `idx_customers_id` | Join to customers |
| `refunds` | `idx_refunds_booking_id` | LEFT JOIN correlation |
