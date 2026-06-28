# File Reference

## Backend (cinema-hall-api)

| File | Path | Description |
|------|------|-------------|
| booking.Controller.js | `controllers/booking.Controller.js` | Seat hold, confirm, release, booking queries, admin listing, verification, cleanup |
| payment.Controller.js | `controllers/payment.Controller.js` | Razorpay order creation, payment verification, webhook handling, admin payment orders |
| refund.Controller.js | `controllers/refund.Controller.js` | Refund listing, per-booking lookup, manual settlement |
| booking.routes.js | `routes/booking.routes.js` | Route definitions for all booking endpoints |
| payment.routes.js | `routes/payment.routes.js` | Route definitions for all payment endpoints (including raw body for webhook) |
| refund.routes.js | `routes/refund.routes.js` | Route definitions for refund endpoints |

## Frontend — Admin App (cinema-hall-admin)

| File | Path | Description |
|------|------|-------------|
| Bookings.jsx | `src/pages/Bookings.jsx` | Admin booking list with filters, stats, export, pagination |
| BookingDetailPage.jsx | `src/pages/BookingDetailPage.jsx` | Single booking detail view for admin |
| PaymentOrders.jsx | `src/pages/PaymentOrders.jsx` | Payment order list with filters |
| RefundsPage.jsx | `src/pages/RefundsPage.jsx` | Refund management list with manual settle |
| VerifyTicket.jsx | `src/pages/VerifyTicket.jsx` | QR ticket verification at cinema entrance |
| api.js | `src/services/api.js` | Admin API services: bookingAPI, paymentAPI, refundAPI, hallFetch |

## Frontend — User App (cinema-hall-users)

| File | Path | Description |
|------|------|-------------|
| Bookings.jsx | `src/pages/Bookings.jsx` | Customer booking history |
| BookingDetailPage.jsx | `src/pages/BookingDetailPage.jsx` | Customer single booking detail with QR |
| BookingSuccessPage.jsx | `src/pages/BookingSuccessPage.jsx` | Post-payment success confirmation |
| BookingFailurePage.jsx | `src/pages/BookingFailurePage.jsx` | Post-payment failure page |
| OrderSummaryPage.jsx | `src/pages/OrderSummaryPage.jsx` | Pre-payment order summary |
| SeatSelectionPage.jsx | `src/pages/SeatSelectionPage.jsx` | Interactive seat map selection |
| SeatCountModal.jsx | `src/components/SeatCountModal.jsx` | Seat count picker dialog with vehicle illustrations |
| useRazorpayPayment.js | `src/hooks/useRazorpayPayment.js` | Razorpay checkout integration hook |
| api.js | `src/services/api.js` | User API services: bookingAPI, paymentAPI |

## Database Tables

| Table | Description |
|-------|-------------|
| `bookings` | Confirmed booking records |
| `payment_orders` | Razorpay payment orders (created/paid/failed) |
| `show_booked_seats` | Per-seat state per show (AVAILABLE/HELD/BOOKED) |
| `refunds` | Refund records from cancelled shows |
| `webhook_events` | Deduplication log for Razorpay webhooks |
| `offer_redemptions` | Offer usage tracking per customer |

## Configuration

| File | Path | Description |
|------|------|-------------|
| `.env` (root) | `cinema-hall-api/.env` | RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET, RAZORPAY_WEBHOOK_SECRET |
| `.env` (admin) | `cinema-hall-admin/.env` | VITE_API_BASE_URL |
| `.env` (user) | `cinema-hall-users/.env` | VITE_API_BASE_URL |

## Environment Variables

| Variable | Where Set | Purpose |
|----------|-----------|---------|
| `RAZORPAY_KEY_ID` | Backend .env | Razorpay API key ID |
| `RAZORPAY_KEY_SECRET` | Backend .env | Razorpay secret (HMAC + order create) |
| `RAZORPAY_WEBHOOK_SECRET` | Backend .env | Webhook HMAC verification |
| `VITE_API_BASE_URL` | Admin/User .env | API base URL for frontend fetch calls |

## Key Constants

| Constant | File | Value |
|----------|------|-------|
| `HOLD_DURATION_MINUTES` | `booking.Controller.js` | 5 |
| `UUID_REGEX` | `booking.Controller.js` | v4 UUID pattern `/^[0-9a-f]{8}-...$/i` |
| Convenience fee default | `payment.Controller.js` | ₹15/ticket |
| GST default | `payment.Controller.js` | 18% |
| Create order idempotency window | `payment.Controller.js` | 10 minutes |
| Admin list max limit | `payment.Controller.js`, `booking.Controller.js` | 100 |
| Frontend search debounce | `Bookings.jsx` (admin) | 400ms |
