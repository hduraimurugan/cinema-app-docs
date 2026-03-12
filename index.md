# Documentation Index

Quick reference for all documentation files in this folder.

| File | Description | Key Topics |
|------|-------------|------------|
| [README.md](./README.md) | Project overview and navigation guide | Tech stack, quick start, doc structure |
| [backend.md](./backend.md) | Backend API reference | All endpoints, DB schema, auth, middleware, payment integration |
| [users.md](./users.md) | User frontend documentation | Pages, components, auth flow, booking + payment flow |
| [admin.md](./admin.md) | Admin panel documentation | Movie management, screen designer, show scheduling, bookings overview |
| [payment and booking implementation.md](./payment%20and%20booking%20implementation.md) | Deep dive into seat booking + Razorpay | Hold mechanism, concurrency, payment verify, booking success page |

---

## Key API Endpoints Quick Reference

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/booking/hold` | Hold seats (5-min lock) |
| POST | `/api/payment/create-order` | Create Razorpay order |
| POST | `/api/payment/verify` | Verify signature + confirm booking |
| GET | `/api/booking/by-payment/:id` | Fetch booking by payment_id (success page) |
| GET | `/api/booking/my-bookings` | List all bookings for logged-in customer |
| GET | `/api/booking/admin/all` | List all bookings for admin's cinema hall (with filters) |
| GET | `/api/booking/admin/verify/:id` | Verify a booking by UUID — admin QR scan (scoped to cinema hall) |
| POST | `/api/booking/release` | Release held seats |
| GET | `/api/shows/get/:id` | Get show with seat layout |
| GET | `/api/user/movies/location/theatres` | Cinema halls with movies + shows for a date (TheatresPage) |

---

## Booking Flow Summary

```
Select Seats → Hold (5 min) → Razorpay Checkout → Verify Payment
→ Navigate to /booking/success?payment_id=pay_xxx
→ BookingSuccessPage fetches GET /api/booking/by-payment/:id
→ Display movie, show time, seat labels, amount
```

---

## Critical Files

| Area | File |
|------|------|
| Booking controller | `cinema-hall-api/controllers/booking.Controller.js` |
| Payment controller | `cinema-hall-api/controllers/payment.Controller.js` |
| Booking routes | `cinema-hall-api/routes/booking.routes.js` |
| User frontend API service | `cinema-hall-users/src/services/api.js` |
| Admin frontend API service | `cinema-hall-admin/src/services/api.js` |
| Payment hook | `cinema-hall-users/src/hooks/useRazorpayPayment.js` |
| Success page | `cinema-hall-users/src/pages/BookingSuccessPage.jsx` |
| User bookings page | `cinema-hall-users/src/pages/Bookings.jsx` |
| Admin bookings page | `cinema-hall-admin/src/pages/Bookings.jsx` |
| Admin verify ticket page | `cinema-hall-admin/src/pages/VerifyTicket.jsx` |
| Seat selection | `cinema-hall-users/src/pages/SeatSelectionPage.jsx` |
| Theatres page | `cinema-hall-users/src/pages/TheatresPage.jsx` |
| Movie info page | `cinema-hall-users/src/pages/MovieInfoPage.jsx` |
| Movie shows page | `cinema-hall-users/src/pages/MovieDetailsPage.jsx` |
| User movies controller | `cinema-hall-api/controllers/userMovies.Controller.js` |
| User movies routes | `cinema-hall-api/routes/userMovies.routes.js` |
| Admin shows management | `cinema-hall-admin/src/pages/ShowsManagement.jsx` |
| Admin screen list | `cinema-hall-admin/src/pages/CinemaScreens.jsx` |
| Admin screen designer (add/edit) | `cinema-hall-admin/src/pages/ScreenDesignerPage.jsx` |

---

*Last Updated: March 9, 2026 — Admin Bookings page: added Screen filter dropdown (fetches from `screensAPI.getMyScreens()`, passes `screen_id` to `GET /api/booking/admin/all`); backend query updated with `$5::uuid` screen filter; full visual redesign (avatar initials, glass-style status pills, screen pill badge, primary-tinted seat chips, 4-column filter grid).*

*March 9, 2026 — Movie detail route split into two pages: `/movie/:movieId` → `MovieInfoPage` (poster, metadata, Book Tickets CTA, About, YouTube trailer embed) and `/movie/shows/:movieId` → `MovieDetailsPage` (date selector + cinema halls + showtimes). Trailer overlay button on poster scrolls to inline YouTube embed.*

*March 9, 2026 — Screen Layout Designer overhaul: replaced passage-type seats with a professional aisle gap system. Aisles are now stored as `aisleAfterColumns: number[]` and `aisleAfterRows: string[]` in the layout JSON (no seat positions consumed). New `Aisle` tool in admin designer — click column headers to add vertical aisles, click row `⬌` buttons to add horizontal aisles. Auto-migration on load: old screens with all-passage columns/rows are automatically converted to the new format (seats renumbered, passage seats removed). Each seat object now includes a `label` field (e.g. `"B-13"`). User-facing `SeatSelectionPage` updated to render matching aisle gaps using layout data. No backend/schema changes required — `layout` JSONB stores new fields additively.*

*March 12, 2026 — Screen Designer split into separate routes: `/screens` (list, `CinemaScreens.jsx`), `/screens/new` (add, `ScreenDesignerPage.jsx`), `/screens/:id/edit` (edit, `ScreenDesignerPage.jsx`). Screen object passed via `location.state` on edit navigation. Redirect guard added for direct URL access. Legacy `AddScreen.jsx` and `EditScreen.jsx` deleted.*
