# Backend – Ticket Verification

## verifyBookingById

**File:** `backend/src/controllers/booking.Controller.js`

### Route Registration

```js
router.get(
  "/admin/verify/:booking_id",
  verifyCinemaAdminAccessToken,
  requireActiveHall,
  bookingController.verifyBookingById
);
```

### Middleware

| Middleware | Purpose |
|---|---|
| `verifyCinemaAdminAccessToken` | Ensures the caller is an authenticated cinema admin |
| `requireActiveHall` | Ensures the admin has an active (selected) hall context |

### Controller Logic

```
verifyBookingById(req, res)
│
├─ 1. Extract booking_id from req.params
│
├─ 2. UUID regex validation
│      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
│      → 400 "Invalid booking ID format"
│
├─ 3. Call Booking model method to fetch booking
│      Booking.getBookingForVerification(booking_id, hall_id)
│
├─ 4. If no result → 404 "Booking not found"
│
├─ 5. Return 200 with booking object
│
└─ 6. On error → 500 "Failed to fetch booking details"
```

### Query Joins

```sql
SELECT
  b.id, b.booking_id, b.total_amount, b.payment_status,
  b.paid_at, b.cancelled_at, b.created_at,
  s.id AS show_id, s.show_date, s.start_time,
  m.title AS movie_title,
  sc.name AS screen_name,
  c.name AS customer_name, c.email AS customer_email,
  STRING_AGG(st.label, ', ') AS seat_labels,
  r.id AS refund_id, r.status AS refund_status,
  r.razorpay_refund_id, r.amount AS refund_amount
FROM bookings b
JOIN shows s ON b.show_id = s.id
JOIN movies m ON s.movie_id = m.id
JOIN screens sc ON s.screen_id = sc.id
JOIN customers c ON b.customer_id = c.id
LEFT JOIN (
  SELECT * FROM refunds WHERE booking_id = b.id
) r ON 1=1
WHERE b.booking_id = ? AND sc.hall_id = ?
GROUP BY b.id;
```

### Response Shape

```json
{
  "booking": {
    "id": 42,
    "booking_id": "uuid-here",
    "total_amount": 750.00,
    "payment_status": "paid",
    "paid_at": "2026-06-27T18:30:00.000Z",
    "cancelled_at": null,
    "created_at": "2026-06-20T10:15:00.000Z",
    "show_id": 15,
    "show_date": "2026-06-28",
    "start_time": "19:00:00",
    "movie_title": "Interstellar",
    "screen_name": "Screen 1",
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "seat_labels": "A1, A2, A3",
    "refund_id": null,
    "refund_status": null,
    "razorpay_refund_id": null,
    "refund_amount": null
  }
}
```
