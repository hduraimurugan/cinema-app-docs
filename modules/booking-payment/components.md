# Components

## Customer App Components (`cinema-hall-users/src/`)

### pages/SeatSelectionPage
- Interactive seat map rendered from `showData.screen.layout`
- Calls `bookingAPI.holdSeats()` to lock selected seats
- Uses `SeatCountModal` for ticket count selection
- Navigates to `OrderSummaryPage`

### pages/OrderSummaryPage
- Displays seat summary with per-category pricing
- Offer code input field
- Convenience fee and GST breakdown
- Razorpay checkout trigger via `useRazorpayPayment` hook
- Calls `paymentAPI.createOrder()` on mount

### pages/BookingSuccessPage
- Success confirmation with check animation
- Booking ID, movie info, show date/time, screen name
- Seat labels display
- QR code rendering (booking UUID)
- "View Details" and "Back to Home" actions

### pages/BookingFailurePage
- Error state with failure messaging
- Retry button
- Navigation back to seat selection

### pages/Bookings
- Customer booking history list
- Each item: movie poster, title, date/time, hall name, seat labels, refund badge
- Pull-to-refresh or reload

### pages/BookingDetailPage
- Full booking detail with QR code
- Movie poster, title, duration, genre, language
- Cinema hall name, location, map link (lat/lng)
- Seat labels rendered as badges
- Refund status section (if applicable)
- Payment breakdown: amount, convenience fee, GST, discount

### components/SeatCountModal
- Dialog for ticket count selection (1-10)
- Dynamic animated vehicle illustration changes per count:
  - 1: Bicycle
  - 2: Vespa Scooter
  - 3: Auto Rickshaw
  - 4: Beetle Car
  - 5: Premium SUV
  - 6-7: Family Minivan
  - 8-10: Party Bus
- Category availability stats (Premium/Gold/Silver) with status:
  - AVAILABLE (green)
  - FILLING FAST (amber, >70% booked)
  - SOLD OUT (zinc, 0 available)
- "Select N Seats" confirmation button

### hooks/useRazorpayPayment
- Encapsulates Razorpay checkout lifecycle
- `initiatePayment({ show_id, seats, customer, offer_code })` → Promise
- Step 1: `paymentAPI.createOrder()`
- Step 2: `window.Razorpay(options)` modal
- Step 3: `paymentAPI.verifyPayment()` on success
- `useRef` in-flight guard blocks concurrent calls
- Releases guard on dismiss, error, or completion

---

## Admin App Components (`cinema-hall-admin/src/`)

### pages/Bookings
- Admin booking list with data table
- **Stats cards**: Total Bookings, Total Revenue, Convenience Fees, GST
- **Filters panel** (collapsible):
  - From/To date pickers (Calendar popover)
  - Movie search with debounce (400ms)
  - Screen selector dropdown
  - Booking status dropdown
- **Table columns**: Customer (avatar+initials+name+email), Movie, Show (date/time), Screen, Seats (label badges), Amount, Status (color-coded badge), Booking ID (truncated + copy)
- **Export**: CSV export with mapped columns
- **Pagination**: page size selector, page nav
- **Empty state**: icon + message + clear filters action
- **Loading state**: skeleton rows (7 rows)
- Auto-fetches screen list on mount

### pages/BookingDetailPage
- Full booking view for admin
- Customer details with avatar
- Movie info with poster
- Show details (date, time, screen)
- Seat labels list
- Payment breakdown
- Refund info section (status, amount, timestamps)

### pages/PaymentOrders
- Payment order list for admin
- Filters: date range, status, customer search, movie search
- Table: order ID, customer, movie, show, seat labels, amount, status badge, timestamps
- Pagination

### pages/RefundsPage
- Refund management list
- Filters: status, date range
- Table: refund ID, booking ID, customer, cinema, amount, status badge, timestamps, failure reason
- Action: manual settle button for pending refunds
- Pagination

### pages/VerifyTicket
- QR ticket verification interface
- Input field for booking UUID or auto-scanned QR
- Displays booking details after verification:
  - Customer name, email
  - Movie, show, screen
  - Seat labels
  - Booking status
  - Refund status
- Validation UX for invalid/tampered QR codes

---

## Shared API Services

### cinema-hall-users/src/services/api.js
- `bookingAPI`: holdSeats, confirmBooking, releaseSeats, getBookingByPaymentId, getMyBookings, getBookingById
- `paymentAPI`: createOrder, verifyPayment

### cinema-hall-admin/src/services/api.js
- `bookingAPI`: getCinemaHallBookings, verifyBooking, getBookingById
- `paymentAPI`: getOrders
- `refundAPI`: getRefunds, getRefundByBooking, settleRefund
- Uses `hallFetch` wrapper for automatic `X-Hall-Id` injection
