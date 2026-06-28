# Backend — Dashboard & Analytics

## Controller

**File:** `cinema-hall-api/controllers/dashboard.Controller.js`

### Single Handler

```javascript
getDashboardStats(req, res)
```

Called via `GET /api/dashboard/stats`. Requires:

1. `verifyCinemaAdminAccessToken` — JWT auth middleware
2. `requireActiveHall` — ensures the user has an active, selected cinema hall

The cinema hall ID (`req.hall.id`) is extracted from auth context.

### Parallel Query Execution

All 8 queries run concurrently via `Promise.all`:

```javascript
const [todayStats, totalStats, totalCustomers, activeOffers, screensCount, revenueTrend, recentBookings, todayShows] =
  await Promise.all([...]);
```

This minimizes response latency. If any single query fails, the entire response fails (no partial results).

### Query Details

#### 1. Today's Stats
```sql
SELECT
  COUNT(*)::INT AS bookings,
  COALESCE(SUM(total_amount), 0) AS revenue,
  COALESCE(SUM(convenience_fee), 0) AS convenience_fee,
  COALESCE(SUM(gst), 0) AS gst
FROM bookings b
JOIN shows s ON b.show_id = s.id
WHERE s.show_date = CURRENT_DATE
  AND b.cinema_hall_id = $1;
```
Returns single-row aggregate for the current date.

#### 2. All-Time Totals
```sql
SELECT COUNT(*)::INT AS bookings, COALESCE(SUM(total_amount), 0) AS revenue
FROM bookings WHERE cinema_hall_id = $1;
```
Lifetime aggregation.

#### 3. Total Customers
```sql
SELECT COUNT(*)::INT AS count FROM customers;
```
Global count — **not** scoped to the current hall.

#### 4. Active Offers
```sql
SELECT COUNT(*)::INT AS count
FROM offers
WHERE (cinema_hall_id = $1 OR scope = 'global')
  AND is_active = true
  AND valid_until >= NOW();
```
Counts both hall-specific and global offers that are active and not expired.

#### 5. Screens Count
```sql
SELECT COUNT(*)::INT AS count FROM screens WHERE cinema_hall_id = $1;
```

#### 6. Last 7 Days Revenue Trend
```sql
SELECT
  d.date,
  COALESCE(SUM(b.total_amount), 0) AS revenue,
  COUNT(b.id)::INT AS bookings_count
FROM generate_series(
  CURRENT_DATE - INTERVAL '6 days',
  CURRENT_DATE,
  '1 day'::INTERVAL
) d(date)
LEFT JOIN shows s ON s.show_date = d.date
LEFT JOIN bookings b ON b.show_id = s.id AND b.cinema_hall_id = $1
GROUP BY d.date
ORDER BY d.date;
```
Uses `generate_series` to ensure all 7 days appear in results (including zero-revenue days).

#### 7. Recent 5 Bookings
```sql
SELECT
  b.id, b.total_amount, b.booking_status, b.created_at,
  m.title AS movie_title,
  c.name AS customer_name,
  (
    SELECT STRING_AGG(
      (sl.seat_data->>'label')::VARCHAR,
      ', ' ORDER BY (sl.seat_data->>'label')::VARCHAR
    )
    FROM bookings b2
    CROSS JOIN LATERAL jsonb_array_elements(b2.seat_labels) AS sl(seat_data)
    WHERE b2.id = b.id
  ) AS seat_labels
FROM bookings b
JOIN shows s ON b.show_id = s.id
JOIN movies m ON s.movie_id = m.id
JOIN customers c ON b.customer_id = c.id
WHERE b.cinema_hall_id = $1
ORDER BY b.created_at DESC
LIMIT 5;
```
Seat labels are extracted from the JSONB `seat_labels` column on the booking record. Labels come from the screen layout JSONB structure.

#### 8. Today's Shows with Occupancy
```sql
SELECT
  s.id, s.start_time, s.status,
  m.title AS movie_title,
  sc.name AS screen_name,
  (
    SELECT COUNT(*)
    FROM jsonb_array_elements(sc.layout->'seats') AS seat
    WHERE seat->>'blocked' IS DISTINCT FROM 'true'
  ) AS total_seats,
  COALESCE(s.show_booked_seats, 0) AS booked_seats
FROM shows s
JOIN movies m ON s.movie_id = m.id
JOIN screens sc ON s.screen_id = sc.id
WHERE s.show_date = CURRENT_DATE
  AND s.cinema_hall_id = $1
ORDER BY s.start_time;
```
`total_seats` counts all non-blocked seats from the layout JSONB. `booked_seats` uses the pre-calculated `show_booked_seats` column on the show record.

## Response Shape

```json
{
  "today": { "bookings": 12, "revenue": 4500.00, "convenience_fee": 180.00, "gst": 360.00 },
  "allTime": { "bookings": 1847, "revenue": 693450.00 },
  "customers": 3201,
  "activeOffers": 5,
  "screens": 4,
  "revenueTrend": [
    { "date": "2026-06-22T00:00:00.000Z", "revenue": 5200.00, "bookings_count": 14 },
    ...
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

## Error Handling

```javascript
try {
  // Promise.all(...)
  res.json({ ... });
} catch (error) {
  console.error('Error fetching dashboard stats:', error);
  res.status(500).json({ error: 'Internal server error' });
}
```

On failure, a generic 500 error is returned. No granular error differentiation.
