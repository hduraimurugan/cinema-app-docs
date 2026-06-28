# Database — Reports & Export

## Tables Involved

All reporting queries join across these tables. The cinema hall lookup chain is `cinema_hall → screens → shows → bookings`.

| Table | Role in Reporting |
|-------|-------------------|
| `bookings` | Core table: total_amount, convenience_fee, gst_amount, booking_status, seats (jsonb), created_at |
| `shows` | Links bookings to movies and screens; show_date and start_time used for time-based filtering |
| `screens` | Links shows to cinema_hall; layout (jsonb) contains seat definitions for seat label resolution |
| `movies` | Provides movie title for display |
| `customers` | Provides customer name and email |
| `refunds` | Refund records: amount, refund_status, initiated_at, settled_at, razorpay_refund_id |
| `offers` | Counted in dashboard stats (active offers with hall scope or global) |
| `cinema_hall` | Tenant isolation — all queries filter by `sc.cinema_hall_id = $1` |

## Key Columns

### bookings

| Column | Type | Purpose |
|--------|------|---------|
| `total_amount` | `numeric` | Total booking amount (before any breakdown) |
| `convenience_fee` | `numeric` | Convenience fee portion |
| `gst_amount` | `numeric` | GST portion |
| `booking_status` | `text` | Filterable status (confirmed, cancelled, etc.) |
| `seats` | `jsonb` | Array of seat IDs; cross-referenced with screen layout for label resolution |
| `created_at` | `timestamptz` | Booking creation timestamp |

### refunds

| Column | Type | Purpose |
|--------|------|---------|
| `amount` | `numeric` | Refunded amount |
| `refund_status` | `text` | Current status (pending, settled, failed) |
| `initiated_at` | `timestamptz` | When the refund was initiated |
| `settled_at` | `timestamptz` | When the refund was settled (nullable) |

## Seat Label Resolution Pattern

Both `getCinemaHallBookings` and `getRefunds` use the same PostgreSQL pattern to convert stored seat IDs into human-readable seat labels:

```sql
ARRAY(
  SELECT (seat_data->>'row') || (seat_data->>'column')
  FROM jsonb_array_elements(sc.layout->'seats') AS seat_data
  WHERE seat_data->>'id' IN (SELECT jsonb_array_elements_text(b.seats))
) AS seat_labels
```

This cross-references the booking's `seats` JSONB array (IDs) with the screen's `layout->'seats'` JSONB array (full seat definitions with row/column) to produce labels like `{"A1", "A2", "B3"}`.

## Revenue Trend Generation

The dashboard uses PostgreSQL's `generate_series` to produce zero-filled 7-day trend data:

```sql
SELECT gs.date::date AS date,
       COALESCE(SUM(b.total_amount), 0) AS revenue,
       COUNT(b.id) AS bookings_count
FROM generate_series(
    CURRENT_DATE - INTERVAL '6 days',
    CURRENT_DATE,
    INTERVAL '1 day'
) AS gs(date)
LEFT JOIN shows sh ON sh.show_date = gs.date
    AND sh.screen_id IN (SELECT id FROM screens WHERE cinema_hall_id = $1)
LEFT JOIN bookings b ON b.show_id = sh.id
GROUP BY gs.date
ORDER BY gs.date
```

This guarantees all 7 days appear in the result, even days with zero bookings.
