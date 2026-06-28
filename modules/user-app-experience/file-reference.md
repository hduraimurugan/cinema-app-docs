# File Reference — User App Experience

## Frontend (`cinema-hall-users`)

### Pages

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 1 | `src/pages/HomePage.jsx` | Landing page with now-showing movies | `HomePage` (default) |
| 2 | `src/pages/MoviesPage.jsx` | Movie catalog with genre/language filters | `MoviesPage` (default) |
| 3 | `src/pages/MovieDetailsPage.jsx` | Movie info + hall showtimes | `MovieDetailsPage` (default) |
| 4 | `src/pages/MovieInfoPage.jsx` | Additional movie info (cast, synopsis) | `MovieInfoPage` (default) |
| 5 | `src/pages/TheatresPage.jsx` | Browse halls with shows | `TheatresPage` (default) |
| 6 | `src/pages/ShowsManagement.jsx` | Shows for selected movie/hall | `ShowsManagement` (default) |
| 7 | `src/pages/SeatSelectionPage.jsx` | Interactive seat map | `SeatSelectionPage` (default) |
| 8 | `src/pages/OrderSummaryPage.jsx` | Pre-payment summary with offer | `OrderSummaryPage` (default) |
| 9 | `src/pages/BookingSuccessPage.jsx` | Post-payment success | `BookingSuccessPage` (default) |
| 10 | `src/pages/BookingFailurePage.jsx` | Post-payment failure | `BookingFailurePage` (default) |
| 11 | `src/pages/Bookings.jsx` | Customer booking history | `Bookings` (default) |
| 12 | `src/pages/BookingDetailPage.jsx` | Single booking with QR code | `BookingDetailPage` (default) |
| 13 | `src/pages/OffersPage.jsx` | Available offers | `OffersPage` (default) |
| 14 | `src/pages/ProfilePage.jsx` | Edit profile | `ProfilePage` (default) |
| 15 | `src/pages/SettingsPage.jsx` | App settings | `SettingsPage` (default) |
| 16 | `src/pages/HallManagement.jsx` | Hall info display | `HallManagement` (default) |
| 17 | `src/pages/Notifications.jsx` | Notification preferences | `Notifications` (default) |
| 18 | `src/pages/ForgotPasswordPage.jsx` | Forgot/reset password | `ForgotPasswordPage` (default) |

### Components

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 19 | `src/components/AdBanner.jsx` | Active ad display with click tracking | `AdBanner` (default) |
| 20 | `src/components/CinemaLayout.jsx` | Main layout wrapper | `CinemaLayout` (default) |
| 21 | `src/components/LocationModal.jsx` | City/state picker | `LocationModal` (default) |
| 22 | `src/components/LoginModal.jsx` | Login/signup modal | `LoginModal` (default) |
| 23 | `src/components/MoviesList.jsx` | Movie card grid | `MoviesList` (default) |
| 24 | `src/components/SearchMovies.jsx` | Movie search input | `SearchMovies` (default) |
| 25 | `src/components/SeatCountModal.jsx` | Seat count picker | `SeatCountModal` (default) |
| 26 | `src/components/TopBar.jsx` | Navigation bar with location | `TopBar` (default) |
| 27 | `src/components/TopNavbar.jsx` | Extended navigation bar | `TopNavbar` (default) |

### UI Components

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 28-58 | `src/components/ui/*.jsx` | 31 shadcn/ui components | Named exports per component |

### Hooks

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 59 | `src/hooks/useRazorpayPayment.js` | Razorpay checkout integration | `useRazorpayPayment` (named) |

### Services

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 60 | `src/services/customerAuthAPI.js` | Auth endpoints | `signup`, `login`, `verifyOtp`, etc. |
| 61 | `src/services/customerMoviesAPI.js` | Movie browsing endpoints | `getAllMovies`, `getMovieById`, `getMoviesByLocation`, `getMovieDetailsWithShowtimes`, `getTheatresWithShows` |
| 62 | `src/services/bookingAPI.js` | Booking endpoints | `holdSeats`, `confirmBooking`, `releaseSeats`, `getMyBookings`, `getBookingByPaymentId`, `getBookingById` |
| 63 | `src/services/paymentAPI.js` | Payment endpoints | `createOrder`, `verifyPayment` |
| 64 | `src/services/offersAPI.js` | Offer endpoints | `getActive`, `validateOffer` |
| 65 | `src/services/adsAPI.js` | Ad endpoints | `getActive`, `recordClick` |
| 66 | `src/services/showsAPI.js` | Show endpoints | `getShowById` |
| 67 | `src/services/settingsAPI.js` | Public settings | `getSettings` |

### Utilities

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 68 | `src/utils/passwordPolicy.js` | Password validation rules | `PASSWORD_POLICY_CHECKS` |
| 69 | `src/utils/seatSelection.js` | Seat selection helpers | Helper functions |

## Backend (`cinema-hall-api`)

### Routes / Controllers

| # | File | Purpose | Key Handlers |
|---|------|---------|-------------|
| 70 | `routes/movieRoutes.js` | Movie route definitions | Routes → `movieController.*` |
| 71 | `controllers/movieController.js` | Movie business logic | `list`, `getById`, `getByLocation`, `getTheatres` |
| 72 | `routes/showRoutes.js` | Show route definitions | Routes → `showController.*` |
| 73 | `controllers/showController.js` | Show business logic | `getById` (with seat layout) |
| 74 | `routes/bookingRoutes.js` | Booking route definitions | Routes → `bookingController.*` |
| 75 | `controllers/bookingController.js` | Booking business logic | `hold`, `confirm`, `release`, `myBookings`, `getById` |
| 76 | `routes/paymentRoutes.js` | Payment route definitions | Routes → `paymentController.*` |
| 77 | `controllers/paymentController.js` | Razorpay payment logic | `createOrder`, `verifyPayment` |
| 78 | `routes/offerRoutes.js` | Offer route definitions | Routes → `offerController.*` |
| 79 | `controllers/offerController.js` | Offer business logic | `getActive`, `validate` |
| 80 | `routes/adRoutes.js` | Ad route definitions | Routes → `adController.*` |
| 81 | `controllers/adController.js` | Ad business logic | `getActive`, `recordClick` |
| 82 | `routes/settingsRoutes.js` | Settings route definitions | Routes → `settingController.*` |
| 83 | `controllers/settingController.js` | Settings logic | `getPublicSettings` |

### Models

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 84 | `models/Movie.js` | Movie schema | `Movie` (Mongoose model) |
| 85 | `models/Hall.js` | Hall/theatre schema | `Hall` (Mongoose model) |
| 86 | `models/Show.js` | Show schema | `Show` (Mongoose model) |
| 87 | `models/Booking.js` | Booking schema | `Booking` (Mongoose model) |
| 88 | `models/Offer.js` | Offer schema | `Offer` (Mongoose model) |
| 89 | `models/Ad.js` | Ad schema | `Ad` (Mongoose model) |
| 90 | `models/Setting.js` | Setting schema | `Setting` (Mongoose model) |

### Middleware

| # | File | Purpose | Key Exports |
|---|------|---------|-------------|
| 91 | `middleware/authMiddleware.js` | JWT verification | `authMiddleware` |
| 92 | `middleware/validateRequest.js` | Request body validation | `validateRequest` |
| 93 | `middleware/seatLockMiddleware.js` | Seat availability check | `seatLockMiddleware` |
