# Backend — User App Experience

## Module Structure

The backend logic lives across route handlers, controllers, and models in the Express API server.

## Routes Handled

| Route Prefix | Controller | Purpose |
|--------------|------------|---------|
| `GET /api/user/movies` | movieController | List movies (all or by location) |
| `GET /api/user/movies/location/:location` | movieController | Movies by city/location |
| `GET /api/user/movies/:movieId` | movieController | Single movie details |
| `GET /api/user/movies/:movieId/theatres` | movieController | Theatres showing movie for a date |
| `GET /api/shows/get/:id` | showController | Show details + full seat layout with status |
| `POST /api/booking/hold` | bookingController | Hold selected seats (temporary lock) |
| `POST /api/booking/confirm` | bookingController | Confirm booking after payment verification |
| `POST /api/booking/release` | bookingController | Release held seats (timeout/cancel) |
| `GET /api/booking/my-bookings` | bookingController | List authenticated user's bookings |
| `GET /api/booking/:booking_id` | bookingController | Single booking detail |
| `POST /api/payment/create-order` | paymentController | Create Razorpay order |
| `POST /api/payment/verify` | paymentController | Verify Razorpay payment signature |
| `GET /api/offers/active` | offerController | List active offers |
| `POST /api/offers/validate` | offerController | Validate an offer code |
| `GET /api/ads/active` | adController | Get ads for a placement |
| `POST /api/ads/click/:id` | adController | Record an ad click |
| `GET /api/settings` | settingController | Get public settings (Razorpay key, etc.) |

## Middleware

| Middleware | Applied To | Purpose |
|------------|------------|---------|
| `authMiddleware` | `/api/booking/*`, `/api/payment/*`, `/api/offers/*` | Verify JWT, attach user to request |
| `validateRequest` | POST endpoints | Validate request body with Joi/Zod schemas |
| `seatLockMiddleware` | `/api/booking/hold` | Check seat availability before holding |

## Seat Locking Logic (Booking Controller)

Seat locking prevents double-booking during the payment window:

1. **Hold** (`POST /api/booking/hold`) — Locks selected seats for a configurable TTL (default 10 minutes). Returns a hold reference.
2. **Confirm** (`POST /api/booking/confirm`) — After successful payment, permanently assigns seats to the user and releases the hold.
3. **Release** (`POST /api/booking/release`) — Explicitly releases held seats (user navigates away, cancels).
4. **TTL Expiry** — A scheduled job or TTL index on MongoDB automatically releases seats after the hold period expires.

## Razorpay Integration (Payment Controller)

1. `createOrder` — Accepts booking details, creates an order via Razorpay Orders API, stores `razorpay_order_id` in the booking record, returns `order_id` to frontend.
2. `verifyPayment` — Accepts `razorpay_order_id`, `razorpay_payment_id`, `razorpay_signature`. Verifies signature using HMAC SHA256 with Razorpay key secret. On success, confirms booking and marks payment completed.

## Key Business Rules

- Seats cannot be held for more than the configured TTL without refreshing
- A user can only hold seats for one active booking session at a time
- Offer codes are validated against expiry date, usage limits, and minimum order value
- Booking confirmation requires valid Razorpay payment verification
- Ad click tracking records IP and timestamp for analytics
