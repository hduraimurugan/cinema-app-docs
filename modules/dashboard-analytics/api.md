# API — Dashboard & Analytics

## Endpoint

```
GET /api/dashboard/stats
```

### Authentication

Two middleware layers applied in order:

| Middleware | Purpose |
|-----------|---------|
| `verifyCinemaAdminAccessToken` | Validates JWT, attaches user context |
| `requireActiveHall` | Ensures a cinema hall is selected and active; attaches `req.hall.id` |

### Request

No query parameters, no request body. All context is derived from the auth token and session.

### Response

**Status 200**

```json
{
  "today": {
    "bookings": 12,
    "revenue": 4500.00,
    "convenience_fee": 180.00,
    "gst": 360.00
  },
  "allTime": {
    "bookings": 1847,
    "revenue": 693450.00
  },
  "customers": 3201,
  "activeOffers": 5,
  "screens": 4,
  "revenueTrend": [
    {
      "date": "2026-06-22T00:00:00.000Z",
      "revenue": 5200.00,
      "bookings_count": 14
    }
  ],
  "recentBookings": [
    {
      "id": 1024,
      "total_amount": 450.00,
      "booking_status": "confirmed",
      "created_at": "2026-06-28T09:15:00.000Z",
      "movie_title": "Inception",
      "customer_name": "John Doe",
      "seat_labels": "A1, A2, A3"
    }
  ],
  "todayShows": [
    {
      "id": 89,
      "start_time": "10:30:00",
      "status": "active",
      "movie_title": "Inception",
      "screen_name": "Screen 1",
      "total_seats": 120,
      "booked_seats": 45
    }
  ]
}
```

**Status 500**

```json
{
  "error": "Internal server error"
}
```

### Response Fields

| Field | Type | Description |
|-------|------|-------------|
| `today.bookings` | integer | Number of bookings for today |
| `today.revenue` | number | Total amount for today's bookings |
| `today.convenience_fee` | number | Total convenience fees for today |
| `today.gst` | number | Total GST for today |
| `allTime.bookings` | integer | Lifetime bookings for the hall |
| `allTime.revenue` | number | Lifetime revenue for the hall |
| `customers` | integer | Total registered customers (global) |
| `activeOffers` | integer | Count of active, non-expired offers |
| `screens` | integer | Number of screens configured |
| `revenueTrend[].date` | string (ISO) | Date of the bucket |
| `revenueTrend[].revenue` | number | Revenue for that date |
| `revenueTrend[].bookings_count` | integer | Booking count for that date |
| `recentBookings[].id` | integer | Booking ID |
| `recentBookings[].total_amount` | number | Booking total |
| `recentBookings[].booking_status` | string | Status (confirmed, cancelled, etc.) |
| `recentBookings[].created_at` | string (ISO) | When booking was made |
| `recentBookings[].movie_title` | string | Movie name |
| `recentBookings[].customer_name` | string | Customer name |
| `recentBookings[].seat_labels` | string | Comma-separated seat labels |
| `todayShows[].id` | integer | Show ID |
| `todayShows[].start_time` | string (HH:MM:SS) | Show start time |
| `todayShows[].status` | string | Show status (active, completed, etc.) |
| `todayShows[].movie_title` | string | Movie name |
| `todayShows[].screen_name` | string | Screen name |
| `todayShows[].total_seats` | integer | Total available seats (non-blocked) |
| `todayShows[].booked_seats` | integer | Currently booked seats |

### Error States

| HTTP Status | Condition |
|-------------|-----------|
| 401 | Invalid or missing access token |
| 403 | No active hall selected / hall access denied |
| 500 | Database error or unexpected failure |

### Route Definition

**File:** `cinema-hall-api/routes/dashboard.routes.js`

```javascript
router.get('/stats', verifyCinemaAdminAccessToken, requireActiveHall, getDashboardStats);
```
