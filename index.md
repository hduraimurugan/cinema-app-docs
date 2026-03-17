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
| GET | `/api/ads/active?placement=` | Fetch currently active ads by placement (`banner` or `side`) — public |
| POST | `/api/ads/click/:id` | Record a click-through on an ad (optional customer auth) |
| GET | `/api/ads` | List all ads with click counts — SuperAdmin only |
| GET | `/api/ads/:id/clicks` | List click-through details (customer name/email/phone, timestamp) — SuperAdmin only |
| GET | `/api/offers/active` | List active, eligible, non-expired offers for the logged-in customer |
| POST | `/api/offers/validate` | Validate a coupon code + calculate discount preview (customer auth) |
| GET | `/api/offers` | List all offers with filters — SuperAdmin only |
| POST | `/api/offers/create` | Create a new offer — SuperAdmin only |
| PUT | `/api/offers/update/:id` | Update an offer — SuperAdmin only |
| DELETE | `/api/offers/delete/:id` | Delete an offer — SuperAdmin only |
| GET | `/api/payment/admin/orders` | List all payment orders for admin's cinema hall (with filters) |
| POST | `/api/booking/release` | Release held seats |
| GET | `/api/shows/get/:id` | Get show with seat layout |
| GET | `/api/user/movies/location/theatres` | Cinema halls with movies + shows for a date (TheatresPage) |

---

## Booking Flow Summary

```
Select Seats (/show/:showId)
  → Hold seats (POST /api/booking/hold)
  → Navigate to /order-summary (location.state with seat + show info)
Order Summary (/order-summary)
  → Show price breakdown (tickets + ₹15/ticket convenience fee + GST)
  → [Optional] Enter coupon code → POST /api/offers/validate → discount applied
  → Pay button → Razorpay Checkout modal (offer_code passed to createOrder)
  → Verify payment (POST /api/payment/verify) → offer redemption recorded
  → Navigate to /booking/success?payment_id=pay_xxx
BookingSuccessPage
  → GET /api/booking/by-payment/:id
  → Display movie, show time, seat labels, amount, QR code
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
| Admin payment orders page | `cinema-hall-admin/src/pages/PaymentOrders.jsx` |
| Admin verify ticket page | `cinema-hall-admin/src/pages/VerifyTicket.jsx` |
| Seat selection | `cinema-hall-users/src/pages/SeatSelectionPage.jsx` |
| Order summary (pre-payment) | `cinema-hall-users/src/pages/OrderSummaryPage.jsx` |
| Theatres page | `cinema-hall-users/src/pages/TheatresPage.jsx` |
| Movie info page | `cinema-hall-users/src/pages/MovieInfoPage.jsx` |
| Ad banner (carousel) | `cinema-hall-users/src/components/AdBanner.jsx` |
| Ads controller | `cinema-hall-api/controllers/ads.Controller.js` |
| Ads routes | `cinema-hall-api/routes/ads.routes.js` |
| Admin Ads management page | `cinema-hall-admin/src/pages/AdsManagement.jsx` |
| Ads DB migration | `cinema-hall-api/migration_ads.sql` |
| Offers controller | `cinema-hall-api/controllers/offers.Controller.js` |
| Offers routes | `cinema-hall-api/routes/offers.routes.js` |
| Offers DB migration | `cinema-hall-api/migrations/migration_offers.sql` |
| Admin Offers management page | `cinema-hall-admin/src/pages/OffersManagement.jsx` |
| User Offers browse page | `cinema-hall-users/src/pages/OffersPage.jsx` |
| Movie shows page | `cinema-hall-users/src/pages/MovieDetailsPage.jsx` |
| User movies controller | `cinema-hall-api/controllers/userMovies.Controller.js` |
| User movies routes | `cinema-hall-api/routes/userMovies.routes.js` |
| Admin shows management (list) | `cinema-hall-admin/src/pages/ShowsManagement.jsx` |
| Admin add show | `cinema-hall-admin/src/pages/AddShowPage.jsx` |
| Admin edit show | `cinema-hall-admin/src/pages/EditShowPage.jsx` |
| Admin bulk add shows | `cinema-hall-admin/src/pages/AddMultipleShowsPage.jsx` |
| Movie search dropdown (shared) | `cinema-hall-admin/src/components/MovieSearchDropdown.jsx` |
| Admin screen list | `cinema-hall-admin/src/pages/CinemaScreens.jsx` |
| Admin screen designer (add/edit) | `cinema-hall-admin/src/pages/ScreenDesignerPage.jsx` |

---

*Last Updated: March 9, 2026 — Admin Bookings page: added Screen filter dropdown (fetches from `screensAPI.getMyScreens()`, passes `screen_id` to `GET /api/booking/admin/all`); backend query updated with `$5::uuid` screen filter; full visual redesign (avatar initials, glass-style status pills, screen pill badge, primary-tinted seat chips, 4-column filter grid).*

*March 9, 2026 — Movie detail route split into two pages: `/movie/:movieId` → `MovieInfoPage` (poster, metadata, Book Tickets CTA, About, YouTube trailer embed) and `/movie/shows/:movieId` → `MovieDetailsPage` (date selector + cinema halls + showtimes). Trailer overlay button on poster scrolls to inline YouTube embed.*

*March 9, 2026 — Screen Layout Designer overhaul: replaced passage-type seats with a professional aisle gap system. Aisles are now stored as `aisleAfterColumns: number[]` and `aisleAfterRows: string[]` in the layout JSON (no seat positions consumed). New `Aisle` tool in admin designer — click column headers to add vertical aisles, click row `⬌` buttons to add horizontal aisles. Auto-migration on load: old screens with all-passage columns/rows are automatically converted to the new format (seats renumbered, passage seats removed). Each seat object now includes a `label` field (e.g. `"B-13"`). User-facing `SeatSelectionPage` updated to render matching aisle gaps using layout data. No backend/schema changes required — `layout` JSONB stores new fields additively.*

*March 12, 2026 — Screen Designer split into separate routes: `/screens` (list, `CinemaScreens.jsx`), `/screens/new` (add, `ScreenDesignerPage.jsx`), `/screens/:id/edit` (edit, `ScreenDesignerPage.jsx`). Screen object passed via `location.state` on edit navigation. Redirect guard added for direct URL access. Legacy `AddScreen.jsx` and `EditScreen.jsx` deleted.*

*March 12, 2026 — Shows Management split into separate routes: Add Show modal → `AddShowPage` at `/shows/new`; Edit Show modal → `EditShowPage` at `/shows/:id/edit` (fetches show by ID, pre-fills form); new `AddMultipleShowsPage` at `/shows/bulk` (same movie+screen+date, dynamic time slots list → `POST /api/shows/bulk`). `MovieSearchDropdown` extracted to `src/components/MovieSearchDropdown.jsx` (shared). Auto-fill: selecting a screen populates `price_override` from `screen.premium/gold/silver_price`; selecting a movie populates `language_version` from `movie.language`.*

*March 12, 2026 — Shows Management date selector redesigned: added left/right chevron arrow buttons for week-by-week navigation. New `weekOffset` state shifts the visible 7-day window by ±7 days per click. Past dates are accessible. A week range label (e.g. "March 12 – 18, 2026") is shown above the pills. Pills remain fixed-width (`w-14`), left-aligned with consistent `gap-2` spacing. Navigating weeks auto-selects the first day of the new week. (`ShowsManagement.jsx`)*

*March 12, 2026 — Replaced plain `<input type="date">` with ShadCN Popover + Calendar date picker in `AddShowPage.jsx`, `AddMultipleShowsPage.jsx`, and the Show Date filter in `Bookings.jsx`. All three use `Popover` + `PopoverTrigger` (outlined Button with `CalendarIcon`) + `Calendar mode="single"`. Selected date stored as `YYYY-MM-DD` string via `dayjs`; trigger displays `MMM D, YYYY` or "Pick a date" placeholder.*

*March 12, 2026 — Added Payment Orders page to admin panel. New backend endpoint `GET /api/payment/admin/orders` (auth: `verifyCinemaAdminAccessToken` + `verifyCinemaHall`) returns paginated `payment_orders` with JOINed customer/movie/show/screen data and derived seat labels from screen layout JSONB. Filters: order date, status (created/paid/failed/expired), customer name/email search, movie title search. Frontend: `PaymentOrders.jsx` at `/payment-orders` follows same pattern as `Bookings.jsx` (4-column filter card, shadcn Table, skeleton loading, empty/error states, pagination). Sidebar nav link added under Operations between Bookings and Verify Ticket. `paymentAPI.getOrders()` added to `cinema-hall-admin/src/services/api.js`.*

*March 12, 2026 — Added Refresh button to admin `Bookings.jsx` and `PaymentOrders.jsx`. Button sits in the page header alongside the total count badge; clicking re-fetches with current active filters and page. Icon spins (`animate-spin`) and button is disabled while loading.*

*March 17, 2026 — Offers/coupon system: `offers` + `offer_redemptions` DB tables (`migration_offers.sql`); `ALTER TABLE bookings/payment_orders` adds `offer_code` + `discount_amount` columns. New `GET+POST /api/offers/*` routes (SuperAdmin CRUD + customer validate/active). `createOrder` applies offer discount server-side; `verifyPayment` records redemption atomically. Admin: `OffersManagement.jsx` at `/offers` (SuperAdmin); Offers nav item in AppSidebar. User: `OffersPage.jsx` at `/offers` (card grid + copy-code); coupon input + apply/remove UI in `OrderSummaryPage`; discount line in price breakdown; `offer_code` flows through `useRazorpayPayment` → `paymentAPI.createOrder`.*

*March 16, 2026 — TopBar + TopNavbar UI/UX redesign: mobile search expands inline (no alert), location pill shows full text on desktop, MapPin dot indicator on mobile, numeric notification badge replaces pulsing dot, Sign In always visible (removed from hamburger), user dropdown gains "My Bookings" + avatar header, hamburger simplified to theme/location/bookings. TopNavbar: `-mb-px border-b-2` active indicator, right nav visible at `sm+`, height `h-11`. MoviesPage location strip: "Showing results near" hidden on mobile.*

*March 16, 2026 — SeatSelectionPage BMS-style redesign + new OrderSummaryPage. SeatSelectionPage: dark-themed seat grid (`bg-gray-50 dark:bg-zinc-950`), small 28px square seat buttons with zero-padded 2-digit column numbers, theme-adaptive available/sold/selected colors, row labels on both sides, mobile-responsive horizontal scroll (`overflow-x-auto` + `w-max mx-auto`). "Proceed to Payment" now holds seats then navigates to `/order-summary` with `location.state` (removed inline payment bar). New `OrderSummaryPage` at `/order-summary`: two-column layout (Razorpay panel left, order summary right), countdown timer, ₹15/ticket convenience fee, Pay triggers Razorpay, Cancel releases seats. Route added to `App.jsx`.*

*March 14, 2026 — Added Ads Management system (SuperAdmin only). New `ads` and `ad_clicks` tables (`migration_ads.sql`). Backend: `ads.Controller.js` + `ads.routes.js` registered at `/api/ads`. Public routes: `GET /active?placement=` (serves active ads by date range), `POST /click/:id` (records click with optional customer auth via cookie). SuperAdmin routes: full CRUD + `GET /:id/clicks` (returns customer name/email/phone per click). Admin panel: `AdsManagement.jsx` at `/ads` (SuperAdmin route) — card grid with image preview, placement badge, date range, active toggle, click count, edit/delete/view-clicks actions; create/edit modal with image URL preview, placement selector (Banner/Side), date range, active toggle. User frontend: `AdBanner.jsx` now fetches `placement=banner` ads dynamically (hides if no active ads, clicking records click + opens URL); `MovieInfoPage.jsx` fetches `placement=side` ads and renders a sticky right sidebar on md+ screens. `adsAPI` added to both `cinema-hall-admin/src/services/api.js` and `cinema-hall-users/src/services/api.js`.*
