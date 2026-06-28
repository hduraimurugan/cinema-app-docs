# Database — Dashboard & Analytics

## Tables Involved

| Table | Role in Dashboard |
|-------|------------------|
| `bookings` | Revenue, counts, recent bookings |
| `shows` | Date filtering, status, occupancy (via `show_booked_seats`) |
| `movies` | Movie titles for shows and bookings |
| `screens` | Screen names and layout JSONB for seat counts |
| `customers` | Total customer count |
| `offers` | Active offer count (hall-scoped and global) |
| `cinema_halls` | Context (hall ID extracted from auth) |

## Key Columns

### `bookings`
| Column | Type | Used For |
|--------|------|----------|
| `id` | INT PK | Count, joins |
| `cinema_hall_id` | INT FK | Hall scoping |
| `show_id` | INT FK | Join to shows |
| `customer_id` | INT FK | Join to customers |
| `total_amount` | DECIMAL | Revenue aggregation |
| `convenience_fee` | DECIMAL | Fee breakdown |
| `gst` | DECIMAL | Tax breakdown |
| `booking_status` | VARCHAR | Display in recent bookings |
| `seat_labels` | JSONB | Seat label extraction |
| `created_at` | TIMESTAMP | Recent bookings ordering |

### `shows`
| Column | Type | Used For |
|--------|------|----------|
| `id` | INT PK | Joins |
| `cinema_hall_id` | INT FK | Hall scoping |
| `movie_id` | INT FK | Join to movies |
| `screen_id` | INT FK | Join to screens |
| `show_date` | DATE | Today's filtering, revenue trend |
| `start_time` | TIME | Display |
| `status` | VARCHAR | Display |
| `show_booked_seats` | INT | Occupancy count (pre-calculated) |

### `screens`
| Column | Type | Used For |
|--------|------|----------|
| `id` | INT PK | Joins, count |
| `cinema_hall_id` | INT FK | Hall scoping |
| `name` | VARCHAR | Display |
| `layout` | JSONB | Seat enumeration (query 8) |

The `layout` JSONB structure contains a `seats` array. Each seat object includes a `label` and a `blocked` flag. Unblocked seats are counted as `total_seats`.

### `offers`
| Column | Type | Used For |
|--------|------|----------|
| `id` | INT PK | Count |
| `cinema_hall_id` | INT FK | Hall scoping (nullable) |
| `scope` | VARCHAR | 'global' or hall-specific |
| `is_active` | BOOLEAN | Active filter |
| `valid_until` | DATE | Expiry filter |

### `customers`
| Column | Type | Used For |
|--------|------|----------|
| `id` | INT PK | Count |

## JSONB Seat Label Extraction

In Query 7 (Recent 5 Bookings), seat labels are extracted from the `seat_labels` JSONB array using:

```sql
CROSS JOIN LATERAL jsonb_array_elements(b2.seat_labels) AS sl(seat_data)
```

Each element in `seat_labels` is a JSON object with a `label` key. The values are concatenated with `STRING_AGG` ordered by label.

## Index Recommendations

| Index | Justification |
|-------|---------------|
| `bookings(cinema_hall_id, show_id)` | Covers all hall-scoped booking queries |
| `bookings(created_at DESC)` WHERE `cinema_hall_id = ?` | Recent bookings ordering |
| `shows(cinema_hall_id, show_date)` | Today's shows and revenue trend joins |
| `offers(cinema_hall_id, is_active, valid_until)` | Active offer count |
| `screens(cinema_hall_id)` | Screen count |

## Design Decisions

- **`show_booked_seats`** is a pre-calculated column on `shows`, updated when bookings are created/cancelled. This avoids expensive JSONB traversal on every dashboard load.
- **`generate_series`** in Query 6 ensures zero-revenue days appear in the trend rather than being omitted.
- **Global customer count** (Query 3) is not hall-scoped. This is a system-wide metric.
- **Seat labels** are stored as a JSONB array on the booking record (denormalized from the screen layout at booking time) to allow efficient display without live layout traversal.
