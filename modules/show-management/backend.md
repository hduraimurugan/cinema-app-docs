# Backend — Show Management

## Controller

**File:** `cinema-hall-api/controllers/shows.Controller.js` (851 lines)

### Functions

#### `createShow`
Creates a single show record.
- **Input:** `movie_id`, `screen_id`, `show_date`, `start_time`, `end_time`, `language_version`, `price_override`
- **Normalization:** `show_date` is normalized to `YYYY-MM-DD` via dayjs
- **Validation:** All required fields must be present; hall_id is set from authenticated hall context

#### `createMultipleShows`
Bulk creates shows as a cross product of `screen_ids × dates × time_slots`.
- Uses a **SAVEPOINT per row** — individual failures do not roll back the entire batch
- Returns `{ created: [...], skipped: [...] }` arrays

#### `editShow`
Partially updates a show with a whitelist of allowed fields.
- Whitelist: `movie_id`, `screen_id`, `show_date`, `start_time`, `end_time`, `language_version`, `price_override`
- If `show_date` is moved to a future date, status auto-resets to `'scheduled'`

#### `deleteShow`
Hard deletes a single show by ID.

#### `deleteMultipleShows`
Bulk delete: `DELETE WHERE id = ANY($1::uuid[])`.

#### `getShowsByDate`
Returns all shows for a given date, grouped by movie.
- Joins: `shows + movies + screens`
- Scoped to the authenticated hall
- Groups results: `{ movie: {...}, shows: [...] }`

#### `getShowById`
Returns full show detail including movie, screen, layout, and seat status mapping.
- Seat status determination:
  - `available` — no record in `show_booked_seats`
  - `blocked` — `hold_expires_at > now()`
  - `in_booking` — `status = 'in_booking'` and `lock_expires_at > now()`
  - `booked` — `status = 'booked'`
  - otherwise reverted to `available`

#### `bookShow`
Locks a seat for booking with a 10-minute expiry.
- Inserts into `show_booked_seats` with `status = 'in_booking'` and `lock_expires_at = NOW() + 10min`
- Uses `ON CONFLICT (show_id, seat_id) DO NOTHING` — if already locked/booked, silently skips

#### `cancelShow`
Cancels a show and cascades to all associated bookings.
- Marks show as `cancelled`
- Marks all `show_booked_seats` with `status = 'booked'` to `cancelled`
- Creates refund records with `status = 'initiated'`
- **Outside the DB transaction**, initiates Razorpay refunds

#### `updateShowBookingStatus`
Controls booking window lifecycle.
- **Open:** `scheduled → booking_started`
- **Revert:** `booking_started → scheduled` (only if no confirmed bookings exist)
- **Restore:** `cancelled → scheduled`

#### `bulkCancelShows`
Iterates over an array of show IDs, calling `cancelShow` logic per show with individual DB transactions + Razorpay refunds.

#### `bulkRestoreShows`
Iterates over an array of show IDs, transitioning each from `cancelled → scheduled`.

#### `bulkOpenBooking`
Iterates over an array of show IDs, transitioning each from `scheduled → booking_started`.

#### `getShowBookingCount`
Returns `COUNT` and `SUM` of completed bookings for a given show.

#### `updateShowStatuses`
Background job that auto-transitions shows based on IST time:
- `booking_started → in_progress` (when show start time passes)
- `in_progress → show_ended` (when show end time passes)
- Handles **midnight-crossing** shows correctly

## Routes

**File:** `cinema-hall-api/routes/shows.routes.js`

### Admin Routes (protected)
All require `verifyCinemaAdminAccessToken` + `requireActiveHall` middleware.

| Method | Path | Additional Middleware | Controller |
|--------|------|----------------------|------------|
| POST | `/api/shows/create` | `verifyScreenOwnership` | `createShow` |
| POST | `/api/shows/bulk` | `verifyScreenOwnership` | `createMultipleShows` |
| PUT | `/api/shows/edit/:id` | `verifyScreenOwnership` | `editShow` |
| DELETE | `/api/shows/delete/:id` | — | `deleteShow` |
| DELETE | `/api/shows/bulk` | — | `deleteMultipleShows` |
| GET | `/api/shows/date/:date` | — | `getShowsByDate` |
| GET | `/api/shows/booking-count/:id` | — | `getShowBookingCount` |
| PUT | `/api/shows/cancel/:id` | — | `cancelShow` |
| PUT | `/api/shows/bulk-cancel` | — | `bulkCancelShows` |
| PUT | `/api/shows/booking-status/:id` | — | `updateShowBookingStatus` |
| PUT | `/api/shows/bulk-booking-open` | — | `bulkOpenBooking` |
| PUT | `/api/shows/bulk-restore` | — | `bulkRestoreShows` |

### Public Routes

| Method | Path | Controller |
|--------|------|------------|
| GET | `/api/shows/get/:id` | `getShowById` |
| POST | `/api/shows/book/:showId` | `bookShow` |
