# Frontend — User App Experience

## Current Experience Updates

- Movie cards and hero slides normalize `vote_average` and display a one-decimal rating only when it is a positive number.
- `MovieDetailsPage` uses a location-first empty state, sticky date selector, responsive hall cards, available/fast-filling indicators, theatre favorites, and Google Maps directions.
- Favorite theatre IDs are persisted in local storage as `favourite_theatres`.
- Directions use hall latitude/longitude when available and otherwise fall back to a Google Maps address search.

## Pages

| Page | Path | Description |
|------|------|-------------|
| `HomePage.jsx` | `/` | Landing page with now-showing movies, location-based content |
| `MoviesPage.jsx` | `/movies` | Movie catalog with genre/language filters and search |
| `MovieDetailsPage.jsx` | `/movies/:id` | Movie info + showtimes grouped by hall for a location+date |
| `MovieInfoPage.jsx` | `/movies/:id/info` | Additional movie metadata (cast, crew, synopsis) |
| `TheatresPage.jsx` | `/theatres` | Browse halls with shows for a selected location+date |
| `ShowsManagement.jsx` | `/theatres/:hallId/shows` | Shows list for a selected movie or hall |
| `SeatSelectionPage.jsx` | `/booking/select-seats` | Interactive seat map with pricing tiers; proceed to booking |
| `OrderSummaryPage.jsx` | `/booking/order-summary` | Pre-payment summary with offer code input |
| `BookingSuccessPage.jsx` | `/booking/success?booking_id=X` | Confirmation with booking details after payment |
| `BookingFailurePage.jsx` | `/booking/failure` | Error page after failed payment with retry option |
| `Bookings.jsx` | `/bookings` | Customer's booking history (past + upcoming) |
| `BookingDetailPage.jsx` | `/bookings/:id` | Single booking detail with QR code |
| `OffersPage.jsx` | `/offers` | Available offers for the customer |
| `ProfilePage.jsx` | `/profile` | Edit name, phone, location |
| `SettingsPage.jsx` | `/settings` | App settings, notification preferences |
| `HallManagement.jsx` | `/halls/:id` | Hall info display (layout, amenities) |
| `Notifications.jsx` | `/notifications` | Notification preferences management |
| `ForgotPasswordPage.jsx` | `/forgot-password` | Forgot/reset password flow |

## Components

| Component | Purpose |
|-----------|---------|
| `AdBanner.jsx` | Displays active ads with click tracking |
| `CinemaLayout.jsx` | Main layout wrapper (header, content, footer) |
| `LocationModal.jsx` | City/state location picker modal |
| `LoginModal.jsx` | Login/signup modal (see Auth module docs) |
| `MoviesList.jsx` | Movie card grid with poster, title, genre |
| `SearchMovies.jsx` | Search input with autocomplete for movies |
| `SeatCountModal.jsx` | Modal to select number of seats before entering seat map |
| `TopBar.jsx` | Top navigation bar with location display |
| `TopNavbar.jsx` | Extended navigation bar |
| `ui/` | 31 shadcn/ui components (Button, Card, Dialog, Input, etc.) |

## Hooks

### `useRazorpayPayment.js`

Integrates Razorpay checkout into the booking flow.

**Flow:**
1. Load Razorpay SDK script dynamically (if not already loaded)
2. Call `POST /api/payment/create-order` with booking details
3. Receive `order_id` from backend
4. Open Razorpay checkout modal with `order_id`, amount, prefill details
5. Handle success callback → call `POST /api/payment/verify` with Razorpay signature
6. Handle failure callback → navigate to `BookingFailurePage`
7. On verification success → navigate to `BookingSuccessPage`

**Returns:** `{ initiatePayment, loading, error }`

## Services (API Service Layer)

| File | Key Functions |
|------|--------------|
| `customerAuthAPI` | `signup()`, `login()`, `verifyOtp()`, `forgotPassword()`, `resetPassword()` |
| `customerMoviesAPI` | `getAllMovies()`, `getMovieById()`, `getMoviesByLocation()`, `getMovieDetailsWithShowtimes()`, `getTheatresWithShows()` |
| `bookingAPI` | `holdSeats()`, `confirmBooking()`, `releaseSeats()`, `getMyBookings()`, `getBookingByPaymentId()`, `getBookingById()` |
| `paymentAPI` | `createOrder()`, `verifyPayment()` |
| `offersAPI` | `getActive()`, `validateOffer()` |
| `adsAPI` | `getActive(placement)`, `recordClick(adId)` |
| `showsAPI` | `getShowById()` — returns show detail with seat layout |
| `settingsAPI` | `getSettings()` — returns public settings (Razorpay key, etc.) |

## Utilities

| File | Description |
|------|-------------|
| `passwordPolicy.js` | Exports `PASSWORD_POLICY_CHECKS` array for client-side password validation |
| `seatSelection.js` | Helper functions for seat selection UI state management |
