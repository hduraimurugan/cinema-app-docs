# Components — User App Experience

## Page Components

### `HomePage.jsx`

**Path:** `/`

**States:** Loading (skeleton), Empty (no movies), Error, Active (movies displayed)

**Data Dependencies:** `customerMoviesAPI.getMoviesByLocation()` or `getAllMovies()`, `adsAPI.getActive('homepage')`

**Sub-components:** `TopNavbar`, `AdBanner`, `MoviesList`, `LocationModal`, `CinemaLayout`

### `MoviesPage.jsx`

**Path:** `/movies`

**Props (from router):** `?genre=`, `?language=`, `?search=`

**States:** Loading, Empty (no results), Error, Active

**Data Dependencies:** `customerMoviesAPI.getAllMovies()` with query filters

**Sub-components:** `TopBar`, `SearchMovies`, `MoviesList`, `CinemaLayout`

### `MovieDetailsPage.jsx`

**Path:** `/movies/:id`

**Props (from router):** `:id` (movie ID), `?date=`, `?location=`

**States:** Loading, Error (movie not found), Active

**Data Dependencies:** `customerMoviesAPI.getMovieDetailsWithShowtimes(id, date, location)`

**Behavior:** Groups shows by cinema hall. Clicking a show navigates to `SeatSelectionPage`.

**Sub-components:** `TopBar`, `CinemaLayout`, showtime grid component

### `MovieInfoPage.jsx`

**Path:** `/movies/:id/info`

**States:** Loading, Error, Active

**Data Dependencies:** `customerMoviesAPI.getMovieById(id)`

**Displays:** Synopsis, cast & crew, duration, rating, release date

### `TheatresPage.jsx`

**Path:** `/theatres`

**Props (from router):** `?date=`, `?location=`

**States:** Loading, Empty, Error, Active

**Data Dependencies:** `customerMoviesAPI.getTheatresWithShows(location, date)`

**Sub-components:** `TopBar`, `CinemaLayout`

### `ShowsManagement.jsx`

**Path:** `/theatres/:hallId/shows` or used inline

**States:** Loading, Empty (no shows), Error, Active

**Data Dependencies:** Shows data from movie/theatre endpoints

### `SeatSelectionPage.jsx`

**Path:** `/booking/select-seats`

**State machine:** `idle → count-selection → seat-selection → confirming → navigating`

| State | Description |
|-------|-------------|
| `idle` | Page mounted, loading show data |
| `count-selection` | `SeatCountModal` visible — user picks seat count |
| `seat-selection` | Interactive seat map active, user taps seats |
| `confirming` | Calling `bookingAPI.holdSeats()`, navigating to summary |
| `error` | Seat hold failed (conflict, network) |

**Data Dependencies:** `showsAPI.getShowById(id)` on mount → `bookingAPI.holdSeats()` on proceed

**Props (from router):** `?show_id=`

**Key states:**
- **Seat map loading** — skeleton grid with shimmer
- **Seat map error** — retry button, error message
- **Seat selected** — highlighted seat with price badge
- **Seat unavailable** — greyed out, not selectable
- **Hold in progress** — spinner on "Proceed" button
- **Hold conflict** — toast/alert: "Seat no longer available"

### `OrderSummaryPage.jsx`

**Path:** `/booking/order-summary`

**Props (from router):** `?booking_id=`

**States:** Loading, Error, Active

**Data Dependencies:** Booking data via `bookingAPI.getBookingById()` (or passed via state). `offersAPI.validateOffer()` when code is submitted.

**Key elements:**
- Booking summary (movie, hall, date, time, seats)
- Price breakdown (subtotal, discount, total)
- Offer code input with apply button
- "Pay Now" button → triggers `useRazorpayPayment` hook

### `BookingSuccessPage.jsx`

**Path:** `/booking/success?booking_id=X`

**States:** Loading, Active, Error

**Displays:**
- Success checkmark animation
- Booking ID, movie, hall, showtime, seats
- QR code for entry
- "View Booking" and "Back to Home" buttons

### `BookingFailurePage.jsx`

**Path:** `/booking/failure`

**States:** Default (error displayed), Retrying

**Displays:**
- Failure icon / message
- Retry payment button → re-initiates Razorpay
- Contact support link
- "Back to Home" button

### `Bookings.jsx`

**Path:** `/bookings`

**States:** Loading, Empty, Error, Active (list)

**Tabs:** Upcoming (default) | Past

**Data Dependencies:** `bookingAPI.getMyBookings({ status })`

**Sub-components:** Booking card (thumbnail, title, hall, date, seats, amount, status badge)

### `BookingDetailPage.jsx`

**Path:** `/bookings/:id`

**States:** Loading, Error (not found), Active

**Data Dependencies:** `bookingAPI.getBookingById(id)`

**Displays:** Full booking info with QR code (large, scannable)

### `OffersPage.jsx`

**Path:** `/offers`

**States:** Loading, Empty (no offers), Error, Active

**Data Dependencies:** `offersAPI.getActive()`

**Displays:** Offer cards with code, description, expiry, terms

### `ProfilePage.jsx`

**Path:** `/profile`

**States:** Loading, Active (edit mode), Saving

**Fields:** Name, Phone, Location (city/state)

**Data Dependencies:** Update user profile API

### `SettingsPage.jsx`

**Path:** `/settings`

**States:** Active

**Options:** Theme, notification preferences link, about, logout

### `HallManagement.jsx`

**Path:** `/halls/:id`

**States:** Loading, Error, Active

**Displays:** Hall name, location, amenities, seat map overview

### `Notifications.jsx`

**Path:** `/notifications`

**States:** Loading, Active

**Toggles:** Push notifications, email notifications, promotional alerts

### `ForgotPasswordPage.jsx`

**Path:** `/forgot-password`

**States:** Email input → OTP input → Reset form → Success

## Reusable Components

### `AdBanner.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `placement` | string | — | Ad placement key (`homepage`, `movie-detail`) |
| `onClick` | function | — | Optional click handler override |

**States:** Loading (placeholder skeleton), Active (image banner), Empty (no ad, renders nothing)

**Behavior:** Calls `adsAPI.getActive(placement)` on mount. Calls `adsAPI.recordClick(id)` when clicked.

### `CinemaLayout.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `children` | ReactNode | — | Page content |
| `showTopBar` | bool | `true` | Show/hide top navigation |

**Renders:** Top navigation, main content area with max-width container, optional footer

### `LocationModal.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `open` | bool | — | Modal visibility |
| `onClose` | function | — | Close handler |
| `onSelect` | function | — | Called with `{ city, state }` when location picked |

**States:** Loading (fetching cities), Active (list), Empty (no cities in config)

### `LoginModal.jsx`

See Auth module documentation. Used for sign-in/sign-up before booking.

### `MoviesList.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `movies` | array | `[]` | Array of movie objects |
| `loading` | bool | `false` | Show skeleton grid |
| `error` | bool | `false` | Show error state |
| `onMovieClick` | function | — | Click handler (navigates to detail) |

### `SearchMovies.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `onSearch` | function | — | Called with query string |
| `placeholder` | string | `"Search movies..."` | Input placeholder |
| `results` | array | `[]` | Autocomplete suggestions |

### `SeatCountModal.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `open` | bool | — | Modal visibility |
| `maxSeats` | number | `10` | Max selectable seats |
| `onConfirm` | function | — | Called with selected count |
| `onClose` | function | — | Close handler |

**Behavior:** Shows number picker from 1 to `maxSeats`. "Confirm" button proceeds to seat map.

### `TopBar.jsx`

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `location` | object | — | Current `{ city, state }` |
| `onLocationClick` | function | — | Opens LocationModal |

### `TopNavbar.jsx`

Extended navigation bar with links to Movies, Theatres, Bookings, Offers, Profile.

## UI Components (`ui/`)

31 shadcn/ui components re-exported for use across the app:

`Button`, `Card`, `Dialog`, `Input`, `Select`, `Badge`, `Toast`, `Skeleton`, `Avatar`, `Sheet`, `DropdownMenu`, `Separator`, `Tabs`, `Label`, `Form`, `Checkbox`, `RadioGroup`, `Switch`, `Slider`, `Tooltip`, `Popover`, `Command`, `Calendar`, `ScrollArea`, `Progress`, `Textarea`, `Alert`, `AlertDialog`, `AspectRatio`, `Collapsible`, `Carousel`

Usage: `import { Button } from '@/components/ui/button'`
