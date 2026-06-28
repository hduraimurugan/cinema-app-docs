# Workflows

## 1. Complete Booking Flow (Happy Path)

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Customer   │     │  User App    │     │   Backend    │     │  Razorpay    │     │   Database   │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │                    │                    │
       │  Select seats      │                    │                    │                    │
       │───────────────────▶│                    │                    │                    │
       │                    │  POST /booking/hold│                    │                    │
       │                    │───────────────────▶│                    │                    │
       │                    │                    │ FOR UPDATE lock     │                    │
       │                    │                    │─────────────────────│──────────────────▶│
       │                    │                    │ INSERT/UPDATE HELD  │                    │
       │                    │                    │◀────────────────────│────────────────────│
       │                    │  { seats held }    │                    │                    │
       │                    │◀───────────────────│                    │                    │
       │                    │                    │                    │                    │
       │  Show order summary│                    │                    │                    │
       │◀───────────────────│                    │                    │                    │
       │                    │                    │                    │                    │
       │  Request payment   │                    │                    │                    │
       │───────────────────▶│  POST /payment     │                    │                    │
       │                    │  /create-order     │                    │                    │
       │                    │───────────────────▶│                    │                    │
       │                    │                    │ Verify HELD seats  │                    │
       │                    │                    │ Calc pricing (srv) │                    │
       │                    │                    │ Validate offer     │                    │
       │                    │                    │───────────────────▶│ Razorpay order     │
       │                    │                    │◀───────────────────│ create              │
       │                    │                    │ INSERT payment_orders                   │
       │                    │                    │─────────────────────│──────────────────▶│
       │                    │  { order_id, key } │                    │                    │
       │                    │◀───────────────────│                    │                    │
       │                    │                    │                    │                    │
       │  Razorpay Checkout │                    │                    │                    │
       │◀──────────────────▶│                    │                    │                    │
       │  (modal)           │                    │                    │                    │
       │                    │                    │                    │                    │
       │  Payment success   │                    │                    │                    │
       │───────────────────▶│  POST /payment     │                    │                    │
       │                    │  /verify           │                    │                    │
       │                    │───────────────────▶│                    │                    │
       │                    │                    │ HMAC verification  │                    │
       │                    │                    │ Idempotency check  │                    │
       │                    │                    │ UPDATE seats BOOKED│                    │
       │                    │                    │ INSERT booking     │                    │
       │                    │                    │ UPDATE order→paid  │                    │
       │                    │                    │─────────────────────│──────────────────▶│
       │  Booking confirmed │                    │                    │                    │
       │◀───────────────────│◀───────────────────│                    │                    │
```

---

## 2. Seat Hold Lifecycle

```
        holdSeats()                         confirmBooking() / Webhook
              │                                     │
              ▼                                     ▼
         ┌────────┐   5 min expiry          ┌──────────┐
         │  HELD  │ ────────────────────▶   │ BOOKED   │
         └────────┘   cleanupExpiredHolds   └──────────┘
              │
              │ releaseSeats()
              ▼
         ┌───────────┐
         │ AVAILABLE │  (row deleted)
         └───────────┘
```

- **Held seats are locked with `FOR UPDATE`** — prevents concurrent holds
- **Expired holds are cleaned** every 30-60s by background job
- **Voluntary release** deletes the HELD row
- **Booking confirmation** transitions to BOOKED

---

## 3. Payment Webhook Flow (Fallback)

If the customer's browser closes right after Razorpay success but before `/verify` returns:

```
Razorpay                    Backend
   │                          │
   │  POST /webhook           │
   │  (payment.captured)      │
   │─────────────────────────▶│
   │                          │ HMAC verification
   │                          │ Dedup: INSERT webhook_events
   │                          │ SELECT FOR UPDATE payment_orders
   │                          │ (if already 'paid', skip)
   │                          │ UPDATE seats → BOOKED
   │                          │ INSERT booking (ON CONFLICT)
   │                          │ UPDATE order → 'paid'
   │                          │ INSERT offer_redemption
   │◀─────────────────────────│ 200 OK
```

The webhook is also triggered if the customer's network drops between Razorpay success and the `/verify` call. In that case:
1. The frontend's retry at `/verify` finds the order already `paid` → returns existing booking (idempotent)
2. OR the frontend shows an error, but the webhook has already created the booking — customer can check "My Bookings"

---

## 4. Idempotency Protection Layers

```
Operation            Layer 1 (App)              Layer 2 (DB)
─────────────────────────────────────────────────────────────────
createOrder          10-min window check        N/A (no conflict)
                      existing 'created' order
                      for same customer+show

verifyPayment        Pre-check: order.status    bookings.INSERT
                     == 'paid' → return         ON CONFLICT (payment_id)
                     existing booking           DO NOTHING
                                                UNIQUE(payment_id)

Webhook              webhook_events.INSERT      payment_orders
                     ON CONFLICT (event_id)     SELECT FOR UPDATE
                     DO NOTHING                 (serializes concurrent
                                                delivery of same event)
```

---

## 5. Payment Failed Flow

```
Razorpay                    Backend
   │                          │
   │  POST /webhook           │
   │  (payment.failed)        │
   │─────────────────────────▶│
   │                          │ SELECT FOR UPDATE payment_orders
   │                          │ UPDATE order → 'failed'
   │                          │ DELETE FROM show_booked_seats
   │                          │   WHERE status = 'HELD'
   │                          │   (atomically releases seats)
   │◀─────────────────────────│ 200 OK
```

Seats are released atomically — only seats still in `HELD` state are deleted. If a concurrent webhook already booked some seats, those remain BOOKED.

---

## 6. Cancel Show / Refund Flow

```
Admin
   │
   │  Cancel show
   │─────────────────────────▶ Backend
   │                          │
   │                          │ UPDATE bookings → cancelled
   │                          │ INSERT refunds (for each paid booking)
   │                          │ Initiate Razorpay refund
   │                          │
   │                          │ Webhook: refund.processed
   │                          │ UPDATE refunds → settled
   │                          │
   │                          │ (OR admin manually settles via
   │                          │  POST /refunds/:id/settle)
```

---

## 7. QR Ticket Verification Flow

```
Customer arrives at cinema
         │
         │ Shows QR (booking UUID)
         ▼
Admin scans QR via VerifyTicket page
         │
         │ GET /booking/admin/verify/:booking_id
         ▼
Backend validates UUID format (v4 regex)
         │
         │ Scoped to admin's cinema hall
         ▼
Returns full booking details
         │
         │ Display: customer name, movie, seats, status
         ▼
Admin checks ID vs booking → grants entry
```

---

## 8. Cleaning Up Expired Holds (Background Job)

```
cron/interval (every 30-60s)
         │
         │ cleanupExpiredHolds()
         ▼
DELETE FROM show_booked_seats
WHERE status = 'HELD'
  AND hold_expires_at < NOW()
         │
         ▼
Logs count of cleaned-up rows
Handles transient DB errors gracefully
```
