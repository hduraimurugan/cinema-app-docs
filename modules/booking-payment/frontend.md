# Frontend — User App

Path: `cinema-hall-users/src/`

## Pages

### SeatSelectionPage
Interactive seat map. User picks seat count via `SeatCountModal`, then clicks individual seats on a layout rendered from `showData.screen.layout`. Calls `bookingAPI.holdSeats()` to lock selection. Navigates to `OrderSummaryPage` on success.

### SeatCountModal (components/SeatCountModal.jsx)
Dialog picker for number of tickets (1-10). Shows category availability stats (Premium/Gold/Silver) with status badges (AVAILABLE / FILLING FAST / SOLD OUT). Animated vehicle illustration changes based on count (bicycle for 1, bus for 10+).

### OrderSummaryPage
Displays selected seats, per-ticket prices, convenience fee, GST, and offer input. Calls `paymentAPI.createOrder()` on mount. User can apply an offer code. Proceeds to Razorpay checkout via `useRazorpayPayment` hook.

### BookingSuccessPage
Shown after successful `verifyPayment` response. Displays booking ID, movie info, seat labels, and a QR code (booking UUID). Option to view full booking detail.

### BookingFailurePage
Shown if payment fails or is cancelled. Offers retry and navigation back to seat selection.

### Bookings (src/pages/Bookings.jsx)
Customer booking history. Lists all past bookings with movie title, show date/time, screen, hall name, seat labels, refund status via `bookingAPI.getMyBookings()`.

### BookingDetailPage (src/pages/BookingDetailPage.jsx)
Single booking detail with QR code, movie poster, seat labels, cinema hall location (with lat/lng), refund info if applicable. Uses `bookingAPI.getBookingById()`.

## Services (`src/services/api.js`)

### bookingAPI
- `holdSeats(show_id, seats)` — POST `/api/booking/hold`
- `confirmBooking(show_id, seats, total_amount)` — POST `/api/booking/confirm`
- `releaseSeats(show_id, seats)` — POST `/api/booking/release`
- `getBookingByPaymentId(paymentId)` — GET `/api/booking/by-payment/:payment_id`
- `getMyBookings()` — GET `/api/booking/my-bookings`
- `getBookingById(bookingId)` — GET `/api/booking/:booking_id`

### paymentAPI
- `createOrder(show_id, seats, offer_code?)` — POST `/api/payment/create-order`
- `verifyPayment({ razorpay_order_id, razorpay_payment_id, razorpay_signature })` — POST `/api/payment/verify`

## Hooks

### useRazorpayPayment (`src/hooks/useRazorpayPayment.js`)
Encapsulates Razorpay checkout lifecycle:
1. Calls `paymentAPI.createOrder()` (idempotent on backend)
2. Opens Razorpay checkout modal with returned `order_id`
3. On success, calls `paymentAPI.verifyPayment()`
4. Returns `initiatePayment({ show_id, seats, customer, offer_code })`

Uses `useRef` in-flight guard to prevent duplicate Razorpay modal opens. Releases guard on modal dismiss, error, or completion.

---

# Frontend — Admin App

Path: `cinema-hall-admin/src/`

## Pages

### Bookings (src/pages/Bookings.jsx)
Admin booking list with:
- **Stats cards**: Total Bookings, Total Revenue, Convenience Fees Collected, GST Collected
- **Filters**: from/to date, movie search, screen selector, booking status
- **Table**: customer avatar+name+email, movie title, show date/time, screen, seat labels, amount, status badge, truncated booking ID with copy button
- **Export**: CSV export button
- **Pagination**: page size selector, page nav

Uses `bookingAPI.getCinemaHallBookings()`.

### BookingDetailPage (src/pages/BookingDetailPage.jsx)
Full booking detail view for admin. Shows customer info, movie details, seat labels, payment breakdown, refund information. Uses `bookingAPI.getBookingById()`.

### PaymentOrders (src/pages/PaymentOrders.jsx)
Lists all payment orders with filters (date range, status, customer name/email, movie title). Table shows order ID, customer, movie, amount, status, timestamps. Uses `paymentAPI.getOrders()`.

### RefundsPage (src/pages/RefundsPage.jsx)
Refund management list with filters (status, date range). Shows refund ID, booking ID, customer, amount, status badge, timestamps, failure reason. Allows manual settle via `refundAPI.settleRefund()`.

### VerifyTicket (src/pages/VerifyTicket.jsx)
QR ticket verification page. Admin scans or enters booking UUID. Calls `bookingAPI.verifyBooking()` and displays booking details with customer info, seat labels, refund status. Used at cinema entrance.

## Services (`src/services/api.js`)

### bookingAPI
- `getCinemaHallBookings({ from_date, to_date, search, status, screen_id, page, limit })` — GET `/api/booking/admin/all`
- `verifyBooking(bookingId)` — GET `/api/booking/admin/verify/:booking_id`
- `getBookingById(bookingId)` — GET `/api/booking/admin/verify/:booking_id`

### paymentAPI
- `getOrders({ from_date, to_date, status, customer, movie, page, limit })` — GET `/api/payment/admin/orders`

### refundAPI
- `getRefunds({ status, from_date, to_date, page, limit })` — GET `/api/refunds`
- `getRefundByBooking(bookingId)` — GET `/api/refunds/booking/:booking_id`
- `settleRefund(refundId)` — POST `/api/refunds/:refund_id/settle`

### hallFetch
Custom fetch wrapper that automatically injects `X-Hall-Id` header from `localStorage("activeHallId")` for hall-scoped admin routes.
