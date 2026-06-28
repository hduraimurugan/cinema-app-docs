# Backend — Reports & Export

The backend reporting logic lives in three controllers under `cinema-hall-api/controllers/`. All three enforce admin authentication via `verifyCinemaAdminAccessToken` and `requireActiveHall` middleware, which sets `req.currentHallId`.

## Controller: dashboard.Controller.js

### `getDashboardStats`

**Route:** `GET /api/dashboard/stats`

Executes **8 parallel queries** in a single database transaction (using `Promise.all` with a `db.connect()` client) and returns a unified JSON response.

**Queries executed:**

| # | Query | Purpose |
|---|-------|---------|
| a | `today_bookings`, `today_revenue`, `today_convenience_fee`, `today_gst` for shows on `CURRENT_DATE` | Today's booking stats |
| b | `total_bookings`, `total_revenue` (all time) | Lifetime totals |
| c | `total_customers` | Total registered customers |
| d | `active_offers` (hall-specific + global, `valid_until >= NOW()`) | Active offers count |
| e | `total_screens` for the hall | Screen count |
| f | 7 days of revenue/bookings via `generate_series` | Revenue trend |
| g | Recent 5 bookings with movie title, customer name, seat labels | Recent booking list |
| h | Today's shows with total/booked seat counts | Show occupancy |

**Response shape:**

```json
{
  "today": {
    "bookings": 12,
    "revenue": 4500.00,
    "convenience_fee": 240.00,
    "gst": 810.00
  },
  "allTime": {
    "bookings": 1250,
    "revenue": 485000.00
  },
  "customers": 890,
  "activeOffers": 5,
  "screens": 4,
  "revenueTrend": [
    { "date": "2025-01-18", "revenue": 3200.00, "bookings_count": 8 }
  ],
  "recentBookings": [
    { "id": "...", "total_amount": 450, "booking_status": "confirmed", "created_at": "...", "movie_title": "...", "customer_name": "...", "seat_labels": ["A1","A2"] }
  ],
  "todayShows": [
    { "id": "...", "start_time": "14:30", "status": "active", "movie_title": "...", "screen_name": "Screen 1", "total_seats": 120, "booked_seats": 45 }
  ]
}
```

## Controller: booking.Controller.js

### `getCinemaHallBookings`

**Route:** `GET /api/booking/admin/all`

**Query parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `from_date` | `YYYY-MM-DD` | Filter shows on or after this date |
| `to_date` | `YYYY-MM-DD` | Filter shows on or before this date |
| `search` | `string` | Partial match on movie title (case-insensitive) |
| `status` | `string` | Exact match on `booking_status` |
| `screen_id` | `UUID` | Filter by screen |
| `page` | `integer` | Page number (default 1) |
| `limit` | `integer` | Items per page (default 10, max 100) |

**Response shape:**

```json
{
  "bookings": [ /* full booking rows with movie, screen, customer, seat_labels */ ],
  "total": 342,
  "page": 1,
  "stats": {
    "total_revenue": 485000.00,
    "total_convenience_fee": 24000.00,
    "total_gst": 87300.00
  }
}
```

The response includes a `stats` object with revenue aggregates that respect the same filters applied to the booking list. Three separate queries are run: one for the data, one for total count, and one for aggregated stats.

## Controller: refund.Controller.js

### `getRefunds`

**Route:** `GET /api/refunds`

**Query parameters:**

| Param | Type | Description |
|-------|------|-------------|
| `status` | `string` | Filter by `refund_status` (use `"all"` for no filter) |
| `from_date` | `YYYY-MM-DD` | Refunds initiated on or after this date |
| `to_date` | `YYYY-MM-DD` | Refunds initiated on or before this date |
| `page` | `integer` | Page number (default 1) |
| `limit` | `integer` | Items per page (default 10, max 100) |

**Response shape:**

```json
{
  "refunds": [
    {
      "refund_id": "...",
      "booking_id": "...",
      "payment_id": "...",
      "razorpay_refund_id": "...",
      "amount": 450.00,
      "refund_status": "settled",
      "initiated_at": "...",
      "settled_at": "...",
      "failure_reason": null,
      "seat_labels": ["A1","A2"]
    }
  ],
  "total": 23
}
```

### `getRefundByBooking`

**Route:** `GET /api/refunds/booking/:booking_id`

Returns a single refund record for the given booking ID. Returns 404 if no refund exists.

### `manuallySettleRefund`

**Route:** `POST /api/refunds/:refund_id/settle`

Manually marks a refund as `settled` (sets `refund_status = 'settled'` and `settled_at = NOW()`). Verifies the refund belongs to the current cinema hall. Returns 400 if already settled.
