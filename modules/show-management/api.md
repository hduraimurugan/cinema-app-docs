# API — Show Management

## Base Path: `/api/shows`

---

## Admin Endpoints

### `POST /api/shows/create`
Create a single show.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`, `verifyScreenOwnership`

**Body:**
```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "YYYY-MM-DD",
  "start_time": "HH:mm",
  "end_time": "HH:mm",
  "language_version": "Original",
  "price_override": null
}
```

---

### `POST /api/shows/bulk`
Bulk create shows (cross product: screens × dates × time slots).

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`, `verifyScreenOwnership`

**Body:**
```json
{
  "movie_id": "uuid",
  "screen_ids": ["uuid", "uuid"],
  "dates": ["YYYY-MM-DD", "YYYY-MM-DD"],
  "time_slots": [
    { "start_time": "10:00", "end_time": "12:30" },
    { "start_time": "13:00", "end_time": "15:30" }
  ],
  "language_version": "Original",
  "price_override": null
}
```

**Response:**
```json
{
  "created": ["show_id_1", "show_id_2"],
  "skipped": ["show_id_3 (reason)"]
}
```

---

### `PUT /api/shows/edit/:id`
Edit a show's details.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`, `verifyScreenOwnership`

**Body:** (partial update — only send changed fields)
```json
{
  "movie_id": "uuid",
  "screen_id": "uuid",
  "show_date": "YYYY-MM-DD",
  "start_time": "HH:mm",
  "end_time": "HH:mm",
  "language_version": "Tamil",
  "price_override": 200.00
}
```

**Note:** Changing `show_date` to a future date resets status to `scheduled`.

---

### `DELETE /api/shows/delete/:id`
Hard delete a single show.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

---

### `DELETE /api/shows/bulk`
Hard delete multiple shows.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Body:**
```json
{
  "ids": ["uuid", "uuid", "uuid"]
}
```

---

### `GET /api/shows/date/:date`
Get all shows for a date, grouped by movie.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Response:**
```json
[
  {
    "movie": { "id": "uuid", "title": "...", "poster_url": "..." },
    "shows": [
      { "id": "uuid", "screen_id": "uuid", "start_time": "10:00", "end_time": "12:30", "status": "scheduled" }
    ]
  }
]
```

---

### `GET /api/shows/booking-count/:id`
Get booking count and revenue for a show.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Response:**
```json
{
  "total_booked_seats": 45,
  "total_revenue": 6750.00
}
```

---

### `PUT /api/shows/cancel/:id`
Cancel a show, cascade to bookings, initiate refunds.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

---

### `PUT /api/shows/bulk-cancel`
Cancel multiple shows.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Body:**
```json
{
  "ids": ["uuid", "uuid"]
}
```

---

### `PUT /api/shows/booking-status/:id`
Toggle booking window status.

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Body:**
```json
{
  "status": "booking_started"
}
```

| Target Status | Allowed From | Condition |
|--------------|-------------|-----------|
| `booking_started` | `scheduled` | Always |
| `scheduled` | `booking_started` | No confirmed bookings |
| `scheduled` | `cancelled` | Always (restore) |

---

### `PUT /api/shows/bulk-booking-open`
Open booking for multiple shows at once (`scheduled → booking_started`).

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Body:**
```json
{
  "ids": ["uuid", "uuid"]
}
```

---

### `PUT /api/shows/bulk-restore`
Restore multiple cancelled shows (`cancelled → scheduled`).

**Middlewares:** `verifyCinemaAdminAccessToken`, `requireActiveHall`

**Body:**
```json
{
  "ids": ["uuid", "uuid"]
}
```

---

## Public Endpoints

### `GET /api/shows/get/:id`
Get show details with seat layout and availability.

**Response:**
```json
{
  "id": "uuid",
  "movie": { "id": "uuid", "title": "...", "poster_url": "..." },
  "screen": { "id": "uuid", "name": "Screen 1", "layout": { "rows": [...] } },
  "show_date": "2026-07-15",
  "start_time": "10:00",
  "end_time": "12:30",
  "status": "booking_started",
  "price_override": null,
  "seats": [
    { "seat_id": "A1", "status": "available", "price": 150.00 },
    { "seat_id": "A2", "status": "booked", "price": 150.00 },
    { "seat_id": "A3", "status": "in_booking", "lock_expires_at": "..." }
  ]
}
```

Seat statuses: `available`, `blocked` (HELD), `in_booking`, `booked`.

---

### `POST /api/shows/book/:showId`
Lock a seat for booking.

**Body:**
```json
{
  "seat_id": "A5",
  "seat_label": "A5",
  "row_label": "A",
  "column_number": 5
}
```

**Behavior:**
- Creates record with `status = 'in_booking'` and `lock_expires_at = NOW() + 10 minutes`
- Uses `ON CONFLICT DO NOTHING` — fails silently if seat is already taken
