# API Reference

Base URL: `http://localhost:5000` (configurable via `VITE_API_BASE_URL`)

---

## Booking APIs

### POST /api/booking/hold

Hold seats with 5-minute expiry. All-or-nothing — if any seat is unavailable, none are held.

**Auth**: Customer required (`verifyCustomer`)  
**Body**:
```json
{ "show_id": "uuid", "seats": ["A1", "A2", "A3"] }
```
**Response 200**:
```json
{ "success": true, "message": "3 seat(s) held successfully", "hold_expires_at": "2026-06-28T10:20:00Z", "results": [{ "seat_id": "A1", "status": "held", "expires_at": "..." }] }
```
**Response 409** (seat conflict):
```json
{ "success": false, "message": "1 seat(s) are unavailable", "results": [{ "seat_id": "A2", "status": "unavailable", "held_by": "uuid" }] }
```

### POST /api/booking/confirm

Convert HELD seats to BOOKED. Verifies all seats are HELD by this customer and not expired.

**Auth**: Customer required  
**Body**:
```json
{ "show_id": "uuid", "seats": ["A1"], "total_amount": 450 }
```
**Response 200**:
```json
{ "success": true, "message": "Booking confirmed!", "booking": { ... } }
```

### POST /api/booking/release

Voluntarily release HELD seats.

**Auth**: Customer required  
**Body**:
```json
{ "show_id": "uuid", "seats": ["A1"] }
```
**Response 200**:
```json
{ "success": true, "released": ["A1"] }
```

### GET /api/booking/by-payment/:payment_id

Get booking by Razorpay payment ID.

**Auth**: Customer required  
**Response 200**:
```json
{ "booking": { "id": "uuid", "movie_title": "...", "show_date": "...", "start_time": "...", "seat_labels": ["A1"] } }
```

### GET /api/booking/my-bookings

List all bookings for the authenticated customer.

**Auth**: Customer required  
**Response 200**:
```json
{ "bookings": [{ "id": "uuid", "movie_title": "...", "show_date": "...", "start_time": "...", "screen_name": "...", "cinema_hall_name": "...", "seat_labels": [...], "refund_status": null }] }
```

### GET /api/booking/admin/all

List all bookings for the admin's cinema hall with filters and stats.

**Auth**: Admin+hall required  
**Query**: `from_date`, `to_date`, `search` (movie title), `status`, `screen_id`, `page`, `limit`  
**Response 200**:
```json
{ "bookings": [...], "total": 42, "page": 1, "stats": { "total_revenue": 18900, "total_convenience_fee": 630, "total_gst": 113.4 } }
```

### GET /api/booking/admin/verify/:booking_id

Verify a booking by UUID (for QR ticket scanning at entrance).

**Auth**: Admin+hall required  
**UUID validation**: v4 UUID regex on `booking_id`  
**Response 200**:
```json
{ "booking": { "id": "uuid", "customer_name": "...", "customer_email": "...", "movie_title": "...", "seat_labels": [...], "refund_status": null, "refund_amount": null } }
```

### GET /api/booking/:booking_id

Get single booking details (customer view). Must be last route to avoid shadowing.

**Auth**: Customer required (owner only)  
**Response 200**:
```json
{ "booking": { "id": "uuid", "movie_title": "...", "poster_url": "...", "duration_mins": 148, "genre": "...", "screen_name": "...", "cinema_hall_name": "...", "cinema_hall_latitude": 13.0, "cinema_hall_longitude": 80.0, "seat_labels": [...], "refund_status": null } }
```

---

## Payment APIs

### POST /api/payment/create-order

Create Razorpay order. Server-side pricing; idempotent within 10 min window.

**Auth**: Customer required  
**Body**:
```json
{ "show_id": "uuid", "seats": ["A1"], "offer_code": "FLAT100" }
```
**Response 200**:
```json
{ "order_id": "order_xyz", "amount": 45000, "currency": "INR", "key_id": "rzp_live_xxx" }
```
- `amount` is in **paise** (as Razorpay expects)
- If idempotent hit: `_idempotent: true`

### POST /api/payment/verify

Verify Razorpay payment after successful checkout. Idempotent.

**Auth**: Customer required  
**Body**:
```json
{ "razorpay_order_id": "order_xyz", "razorpay_payment_id": "pay_xyz", "razorpay_signature": "hmac_hex_string" }
```
**Response 200**:
```json
{ "success": true, "message": "Payment verified and booking confirmed!", "booking": { ... } }
```

### POST /api/payment/webhook

Razorpay webhook endpoint. No customer auth — HMAC verified. Raw body (Buffer) required.

**Headers**: `X-Razorpay-Signature`, `X-Razorpay-Event-Id`  
**Events**: `payment.captured`, `payment.failed`, `order.paid`, `refund.processed`, `refund.failed`  
**Response 200**:
```json
{ "received": true }
```
**Response for duplicate**: `{ "received": true, "_duplicate": true }`

### GET /api/payment/admin/orders

List payment orders with filters for admin.

**Auth**: Admin+hall required  
**Query**: `from_date`, `to_date`, `status`, `customer`, `movie`, `page`, `limit`  
**Response 200**:
```json
{ "orders": [...], "total": 50, "page": 1 }
```

---

## Refund APIs

### GET /api/refunds

List refunds for the cinema hall with filters.

**Auth**: Admin+hall required  
**Query**: `status`, `from_date`, `to_date`, `page`, `limit`  
**Response 200**:
```json
{ "refunds": [{ "refund_id": "uuid", "booking_id": "uuid", "amount": 450, "refund_status": "settled", "razorpay_refund_id": "rfnd_xyz", "customer_name": "...", "seat_labels": ["A1"] }], "total": 5 }
```

### GET /api/refunds/booking/:booking_id

Get refund record for a specific booking.

**Auth**: Admin+hall required  
**Response 200**:
```json
{ "refund": { ... } }
```

### POST /api/refunds/:refund_id/settle

Manually mark a refund as settled (fallback for missed webhooks).

**Auth**: Admin+hall required  
**Response 200**:
```json
{ "message": "Refund marked as settled" }
```
