# File Reference — Show Management

## Backend Files

### `cinema-hall-api/controllers/shows.Controller.js` (851 lines)

| Function | Line ~ | Purpose |
|----------|---------|---------|
| `createShow` | 1 | Creates a single show record |
| `createMultipleShows` | 30 | Bulk creates shows (screen × date × time cross product) |
| `editShow` | 80 | Partially updates a show with field whitelist |
| `deleteShow` | 120 | Hard deletes a single show |
| `deleteMultipleShows` | 150 | Bulk delete by UUID array |
| `getShowsByDate` | 180 | Gets shows grouped by movie for a date |
| `getShowById` | 230 | Gets full show detail with seat layout and statuses |
| `bookShow` | 320 | Locks a seat with 10-min in_booking status |
| `cancelShow` | 370 | Cancels show, cascades to bookings, initiates refunds |
| `updateShowBookingStatus` | 440 | Transitions show status for booking lifecycle |
| `bulkCancelShows` | 500 | Iterates shows with per-show cancel logic |
| `bulkRestoreShows` | 550 | Iterates shows restoring cancelled → scheduled |
| `bulkOpenBooking` | 590 | Iterates shows opening scheduled → booking_started |
| `getShowBookingCount` | 630 | Returns COUNT and SUM of completed bookings |
| `updateShowStatuses` | 670 | Auto-transitions shows based on IST time |

### `cinema-hall-api/routes/shows.routes.js`

| Line ~ | Route | Middleware | Handler |
|--------|-------|-----------|---------|
| 1 | `POST /api/shows/create` | `verifyCinemaAdminAccessToken`, `requireActiveHall`, `verifyScreenOwnership` | `createShow` |
| 10 | `POST /api/shows/bulk` | Same as above | `createMultipleShows` |
| 20 | `PUT /api/shows/edit/:id` | Same as above | `editShow` |
| 30 | `DELETE /api/shows/delete/:id` | Admin + Hall | `deleteShow` |
| 35 | `DELETE /api/shows/bulk` | Admin + Hall | `deleteMultipleShows` |
| 40 | `GET /api/shows/date/:date` | Admin + Hall | `getShowsByDate` |
| 45 | `GET /api/shows/booking-count/:id` | Admin + Hall | `getShowBookingCount` |
| 50 | `PUT /api/shows/cancel/:id` | Admin + Hall | `cancelShow` |
| 55 | `PUT /api/shows/bulk-cancel` | Admin + Hall | `bulkCancelShows` |
| 60 | `PUT /api/shows/booking-status/:id` | Admin + Hall | `updateShowBookingStatus` |
| 65 | `PUT /api/shows/bulk-booking-open` | Admin + Hall | `bulkOpenBooking` |
| 70 | `PUT /api/shows/bulk-restore` | Admin + Hall | `bulkRestoreShows` |
| 75 | `GET /api/shows/get/:id` | Public | `getShowById` |
| 80 | `POST /api/shows/book/:showId` | Public | `bookShow` |

---

## Database Files

### Migration / Schema

| Table | Purpose |
|-------|---------|
| `shows` | Core show records with movie, screen, date, time, status |
| `show_booked_seats` | Seat-level booking state per show |

---

## Frontend Files

| File | Type | Purpose |
|------|------|---------|
| `ShowsManagement.jsx` | Page | Calendar dashboard with date picker, show cards, bulk actions |
| `ShowPage.jsx` | Page | Single show detail with seat map and booking stats |
| `AddShowPage.jsx` | Page | Form for creating a single show |
| `AddMultipleShowsPage.jsx` | Page | Form for bulk show creation with preview |
| `EditShowPage.jsx` | Page | Form for editing an existing show |
| `services/api.js` (showsAPI) | Service | API client methods for all show endpoints |
| `MovieSearchDropdown` | Component | Searchable movie selector used in show forms |

---

## Data Flow Summary

```
Admin Action
    │
    ▼
React Page (ShowsManagement / AddShowPage / etc.)
    │
    ▼
showsAPI (services/api.js)
    │
    ▼  HTTP Request
shows.routes.js
    │
    ▼  Middleware (auth, hall, ownership)
shows.Controller.js
    │
    ▼  SQL
PostgreSQL (shows + show_booked_seats)
    │
    ▼  Response
JSON returned to frontend
```
