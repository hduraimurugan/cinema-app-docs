# Database — Show Management

## Tables

### `shows`

Core table representing a single movie screening.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | `UUID` | `PK` | | Unique show identifier |
| `movie_id` | `UUID` | `FK → movies(id) NOT NULL` | | The movie being screened |
| `screen_id` | `UUID` | `FK → screens(id) NOT NULL` | | The screen where shown |
| `show_date` | `DATE` | `NOT NULL` | | Screening date (YYYY-MM-DD) |
| `start_time` | `TIME` | `NOT NULL` | | Screening start time |
| `end_time` | `TIME` | `NOT NULL` | | Screening end time |
| `language_version` | `VARCHAR` | | `'Original'` | Language of the screening |
| `price_override` | `DECIMAL` | `NULLABLE` | `NULL` | Override price (falls back to hall default if NULL) |
| `status` | `VARCHAR` | | `'scheduled'` | Current lifecycle status |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | | Record update timestamp |

**Status Values:**
- `scheduled` — Show created, booking not yet open
- `booking_started` — Booking window open
- `in_progress` — Show is currently running
- `show_ended` — Show has finished
- `cancelled` — Show was cancelled

### `show_booked_seats`

Tracks individual seat state per show.

| Column | Type | Constraints | Default | Description |
|--------|------|-------------|---------|-------------|
| `id` | `UUID` | `PK` | | Unique record identifier |
| `show_id` | `UUID` | `FK → shows(id) NOT NULL` | | Associated show |
| `seat_id` | `VARCHAR` | `NOT NULL` | | Seat identifier from screen layout (seat.id) |
| `seat_label` | `VARCHAR` | `NOT NULL` | | Human-readable seat label (e.g. "A1") |
| `row_label` | `VARCHAR` | `NOT NULL` | | Row identifier |
| `column_number` | `INT` | `NOT NULL` | | Column number |
| `status` | `VARCHAR` | | `'available'` | `available` / `in_booking` / `booked` / `HELD` |
| `lock_expires_at` | `TIMESTAMPTZ` | `NULLABLE` | | When an `in_booking` lock expires (10 min from creation) |
| `hold_expires_at` | `TIMESTAMPTZ` | `NULLABLE` | | When a HELD seat expires |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL` | | Record creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL` | | Record update timestamp |

**Constraints:**
- `UNIQUE(show_id, seat_id)` — Prevents duplicate seat bookings for the same show

## Indexes

- `shows.show_date` — Used for date-based queries (`getShowsByDate`)
- `shows.status` — Used for background status update queries
- `show_booked_seats.show_id` — Used for seat status lookups per show
- `show_booked_seats.UNIQUE(show_id, seat_id)` — Enforces one booking per seat per show

## Relationships

```
shows.movie_id  ──→ movies.id
shows.screen_id ──→ screens.id
show_booked_seats.show_id ──→ shows.id
```
