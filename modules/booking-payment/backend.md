# Backend

## booking.Controller.js

Path: `cinema-hall-api/controllers/booking.Controller.js`

### `holdSeats`
- **POST** `/api/booking/hold` — Customer auth
- **Body**: `{ show_id, seats: ["A1", "A2"] }`
- Uses `FOR UPDATE` row-level locking per seat
- Inserts seat as `HELD` if not yet in `show_booked_seats` table
- Renews expired `HELD` rows
- **All-or-nothing**: if any seat fails (already booked by another), ROLLBACK all
- `HOLD_DURATION = 5 minutes`
- Returns `hold_expires_at` timestamp

### `confirmBooking`
- **POST** `/api/booking/confirm` — Customer auth
- **Body**: `{ show_id, seats, total_amount }`
- Verifies every seat is `HELD` by this customer and not expired
- Updates `show_booked_seats` → `BOOKED`, inserts `bookings` record

### `releaseSeats`
- **POST** `/api/booking/release` — Customer auth
- **Body**: `{ show_id, seats }`
- Deletes `HELD` rows for this customer only

### `getBookingByPaymentId`
- **GET** `/api/booking/by-payment/:payment_id` — Customer auth
- Returns booking with movie title, show date, start time, seat labels

### `getMyBookings`
- **GET** `/api/booking/my-bookings` — Customer auth
- All customer bookings with movie, show, screen, hall, seat labels
- `LEFT JOIN refunds` for refund status

### `getCinemaHallBookings`
- **GET** `/api/booking/admin/all` — Admin+hall auth
- **Query**: `from_date, to_date, search, status, screen_id, page, limit`
- Returns bookings array + total count + stats object (`total_revenue`, `total_convenience_fee`, `total_gst`)

### `verifyBookingById`
- **GET** `/api/booking/admin/verify/:booking_id` — Admin+hall auth
- UUID regex validation on `booking_id` (v4 UUID pattern)
- Returns full booking with customer info, seat labels, refund info

### `getBookingDetails`
- **GET** `/api/booking/:booking_id` — Customer auth
- Single booking with movie poster, duration, genre, hall location (lat/lng), refund details

### `cleanupExpiredHolds`
- Background job, call every 30-60s
- Deletes `HELD` rows where `hold_expires_at < NOW()`
- Handles transient DB errors gracefully

---

## payment.Controller.js

Path: `cinema-hall-api/controllers/payment.Controller.js`

### `createOrder`
- **POST** `/api/payment/create-order` — Customer auth
- **Body**: `{ show_id, seats, offer_code? }`
- **Idempotency**: returns existing `created` order within 10 min for same customer+show
- **Seat verification**: confirms all seats are still HELD by this customer
- **Server-side pricing**:
  - Seat total from `layout.pricing` or `price_override`
  - Convenience fee from `organization_settings.payment.convenience_fee.amount` (default ₹15)
  - GST from `organization_settings.payment.gst_percentage` (default 18%)
  - Offer discount via `validateOfferCode()`
- Creates Razorpay order, persists to `payment_orders`

### `verifyPayment`
- **POST** `/api/payment/verify` — Customer auth
- **Body**: `{ razorpay_order_id, razorpay_payment_id, razorpay_signature }`
- **HMAC SHA-256** signature verification against `RAZORPAY_KEY_SECRET`
- **Idempotency**: if order status is already `paid`, returns existing booking
- **Atomic**: updates seats → BOOKED, inserts booking (`ON CONFLICT payment_id DO NOTHING`), updates payment_order → `paid`
- Records `offer_redemptions` if offer was applied

### `handleWebhook`
- **POST** `/api/payment/webhook` — NO customer auth (HMAC verified)
- Route uses `express.raw({ type: "*/*" })` — body is Buffer for accurate signature verification
- **Deduplication**: `webhook_events` table with `INSERT ON CONFLICT (event_id) DO NOTHING`
- **Events handled**:
  - `payment.captured` → `handlePaymentCaptured()`
  - `payment.failed` → `handlePaymentFailed()`
  - `order.paid` → backup path, delegates to `handlePaymentCaptured()`
  - `refund.processed` → update refund status to `settled`
  - `refund.failed` → update refund status to `failed` with reason
- Returns 200 for duplicates (stops Razorpay retries)

### `handlePaymentCaptured` (internal)
- `SELECT FOR UPDATE` on `payment_orders` for serialization
- If already `paid`, skip (idempotent)
- Creates booking if not exists, updates order status

### `handlePaymentFailed` (internal)
- Atomically releases HELD seats for failed payment orders
- Single atomic DELETE (not SELECT-then-DELETE, prevents TOCTOU race)

### `getPaymentOrders`
- **GET** `/api/payment/admin/orders` — Admin+hall auth
- Paginated, filtered (date, status, customer name/email, movie title)
- Includes seat labels resolved from screen layout

---

## refund.Controller.js

Path: `cinema-hall-api/controllers/refund.Controller.js`

### `getRefunds`
- **GET** `/api/refunds` — Admin+hall auth
- **Query**: `status, from_date, to_date, page, limit`
- Returns refunds with booking details, movie info, customer info, seat labels

### `getRefundByBooking`
- **GET** `/api/refunds/booking/:booking_id` — Admin+hall auth
- Single refund record for a booking

### `manuallySettleRefund`
- **POST** `/api/refunds/:refund_id/settle` — Admin+hall auth
- Verifies refund belongs to admin's cinema hall
- Prevents double-settle
- Manually marks refund as `settled` with `settled_at = NOW()`
- Fallback for missed Razorpay webhooks or offline scenarios

---

## Routes

### booking.routes.js

```
POST   /api/booking/hold                (verifyCustomer)
POST   /api/booking/confirm             (verifyCustomer)
POST   /api/booking/release             (verifyCustomer)
GET    /api/booking/by-payment/:payment_id  (verifyCustomer)
GET    /api/booking/my-bookings         (verifyCustomer)
GET    /api/booking/admin/all           (verifyCinemaAdminAccessToken, requireActiveHall)
GET    /api/booking/admin/verify/:booking_id  (verifyCinemaAdminAccessToken, requireActiveHall)
GET    /api/booking/:booking_id         (verifyCustomer) — must be last
```

### payment.routes.js

```
POST   /api/payment/create-order        (verifyCustomer)
POST   /api/payment/verify              (verifyCustomer)
POST   /api/payment/webhook             express.raw({ type: "*/*" }) → handleWebhook (no auth)
GET    /api/payment/admin/orders        (verifyCinemaAdminAccessToken, requireActiveHall)
```

### refund.routes.js

```
GET    /api/refunds                     (verifyCinemaAdminAccessToken, requireActiveHall)
GET    /api/refunds/booking/:booking_id (verifyCinemaAdminAccessToken, requireActiveHall)
POST   /api/refunds/:refund_id/settle   (verifyCinemaAdminAccessToken, requireActiveHall)
```
