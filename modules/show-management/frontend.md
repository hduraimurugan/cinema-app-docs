# Frontend — Show Management (Admin)

## Pages

### `ShowsManagement.jsx`
Main calendar-style dashboard for managing all shows.

**Features:**
- Date picker to navigate between days
- Shows grouped by movie with movie poster and title
- Each show card displays: screen, start/end time, status badge, language
- Inline actions: edit, delete, cancel, open/close booking, restore
- Bulk action toolbar: bulk cancel, bulk open booking, bulk restore, bulk delete

### `ShowPage.jsx`
Detailed view of a single show.

**Features:**
- Seat map overlay showing the screen layout with color-coded seat status
- Booking statistics (total booked seats, revenue)
- Show metadata (movie, screen, date, time, status)
- Cancel / edit / delete actions

### `AddShowPage.jsx`
Form to create a single show.

**Features:**
- `MovieSearchDropdown` for movie selection
- Screen selector (dropdown of hall's screens)
- Date picker
- Start time / end time inputs
- Language version text input
- Price override (optional number input)
- Submit button

### `AddMultipleShowsPage.jsx`
Form for bulk show creation.

**Features:**
- `MovieSearchDropdown` for movie selection
- Multi-select screen picker (checkboxes)
- Date range selector (start date → end date)
- Multiple time slot entries (add/remove rows with start_time + end_time)
- Language version text input
- Price override (optional)
- Preview table showing the cross-product of all combinations before submission

### `EditShowPage.jsx`
Form to edit an existing show's details.

**Features:**
- Pre-populated with current show data
- Same fields as AddShowPage
- Save button

## Services

**File:** `services/api.js` — `showsAPI` object

| Method | Endpoint | Description |
|--------|----------|-------------|
| `createShow(data)` | `POST /api/shows/create` | Create single show |
| `createMultipleShows(data)` | `POST /api/shows/bulk` | Bulk create shows |
| `editShow(id, data)` | `PUT /api/shows/edit/:id` | Edit show |
| `deleteShow(id)` | `DELETE /api/shows/delete/:id` | Delete show |
| `deleteMultipleShows(ids)` | `DELETE /api/shows/bulk` | Bulk delete |
| `getShowsByDate(date)` | `GET /api/shows/date/:date` | Get shows for date |
| `getShowById(id)` | `GET /api/shows/get/:id` | Get show with seats |
| `bookShow(showId, seatData)` | `POST /api/shows/book/:showId` | Lock seat |
| `getShowBookingCount(id)` | `GET /api/shows/booking-count/:id` | Booking stats |
| `cancelShow(id)` | `PUT /api/shows/cancel/:id` | Cancel show |
| `updateBookingStatus(id, status)` | `PUT /api/shows/booking-status/:id` | Toggle booking |
| `bulkCancelShows(ids)` | `PUT /api/shows/bulk-cancel` | Bulk cancel |
| `bulkRestoreShows(ids)` | `PUT /api/shows/bulk-restore` | Bulk restore |
| `bulkOpenBooking(ids)` | `PUT /api/shows/bulk-booking-open` | Bulk open booking |

## Component Integration

- **`MovieSearchDropdown`** — Used in `AddShowPage`, `AddMultipleShowsPage`, `EditShowPage` for movie selection with search-as-you-type
- **Status Badges** — Applied across all list/detail views with color coding:
  - `scheduled` → gray
  - `booking_started` → green
  - `in_progress` → blue
  - `show_ended` → dark
  - `cancelled` → red
