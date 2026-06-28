# Database Schema

## bookings

Stores confirmed booking records.

| Column | Type | Details |
|--------|------|---------|
| `id` | UUID | Primary Key |
| `show_id` | UUID | FK → shows.id |
| `customer_id` | UUID | FK → customers.id |
| `user_email` | VARCHAR | Customer email at time of booking |
| `seats` | JSONB | Array of seat IDs |
| `total_amount` | DECIMAL | Total charged amount |
| `convenience_fee` | DECIMAL | Convenience fee collected |
| `gst_amount` | DECIMAL | GST on convenience fee |
| `offer_code` | VARCHAR | Applied offer code (nullable) |
| `discount_amount` | DECIMAL | Discount from offer |
| `payment_status` | VARCHAR | e.g. 'completed' |
| `payment_id` | VARCHAR | Razorpay payment ID (UNIQUE) |
| `booking_status` | VARCHAR | Default 'booked' |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

**Unique constraint**: `payment_id` — prevents duplicate bookings for the same Razorpay payment.

## payment_orders

Stores Razorpay orders created before payment.

| Column | Type | Details |
|--------|------|---------|
| `id` | UUID | Primary Key |
| `order_id` | VARCHAR | Razorpay order ID |
| `show_id` | UUID | FK → shows.id |
| `customer_id` | UUID | FK → customers.id |
| `seats` | JSONB | Array of seat IDs |
| `amount` | DECIMAL | Total amount (in rupees) |
| `convenience_fee` | DECIMAL | Convenience fee |
| `gst_amount` | DECIMAL | GST on convenience fee |
| `offer_code` | VARCHAR | Applied offer code (nullable) |
| `discount_amount` | DECIMAL | Discount from offer |
| `status` | VARCHAR | 'created', 'paid', 'failed' |
| `payment_id` | VARCHAR | Razorpay payment ID (filled on success) |
| `payment_signature` | VARCHAR | Razorpay HMAC signature |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |

## show_booked_seats

Tracks per-seat booking state for each show. Row-level locking target.

| Column | Type | Details |
|--------|------|---------|
| `show_id` | UUID | FK → shows.id |
| `seat_id` | VARCHAR | e.g. "A1" |
| `seat_label` | VARCHAR | Display label |
| `row_label` | VARCHAR | Row identifier |
| `column_number` | INTEGER | Column index |
| `status` | VARCHAR | 'AVAILABLE', 'HELD', 'BOOKED' |
| `held_by` | UUID | FK → customers.id (nullable) |
| `hold_expires_at` | TIMESTAMP | Null for BOOKED seats |
| `booked_at` | TIMESTAMP | When seat was confirmed |

**Unique constraint**: `(show_id, seat_id)`

## refunds

Tracks refund requests initiated from cancelled shows or bookings.

| Column | Type | Details |
|--------|------|---------|
| `id` | UUID | Primary Key |
| `booking_id` | UUID | FK → bookings.id |
| `payment_id` | VARCHAR | Razorpay payment ID |
| `amount` | DECIMAL | Refund amount |
| `refund_status` | VARCHAR | 'pending', 'settled', 'failed' |
| `razorpay_refund_id` | VARCHAR | Razorpay refund ID |
| `failure_reason` | TEXT | Reason if refund failed |
| `initiated_at` | TIMESTAMPTZ | When refund was initiated |
| `settled_at` | TIMESTAMPTZ | When refund was settled |
| `created_at` | TIMESTAMP | |

## webhook_events

Deduplication table for Razorpay webhooks.

| Column | Type | Details |
|--------|------|---------|
| `event_id` | VARCHAR | UNIQUE — X-Razorpay-Event-Id header or SHA-256 fallback |
| `event_type` | VARCHAR | e.g. 'payment.captured' |
| `payload_hash` | VARCHAR | SHA-256 of raw body |
| `created_at` | TIMESTAMP | |

**Unique constraint**: `event_id`

## offer_redemptions

Tracks offer usage per customer to enforce per-customer limits.

| Column | Type | Details |
|--------|------|---------|
| `id` | UUID | Primary Key |
| `offer_id` | UUID | FK → offers.id |
| `customer_id` | UUID | FK → customers.id |
| `booking_id` | UUID | FK → bookings.id |
| `discount_applied` | DECIMAL | Discount amount |
| `created_at` | TIMESTAMP | |

**Unique constraint**: `(offer_id, customer_id)` — each customer can redeem each offer once.

## Key Relationships

```
shows → payment_orders (show_id)
shows → show_booked_seats (show_id)
shows → bookings (show_id)
bookings → refunds (booking_id)
bookings → payment_orders (payment_id ↔ order_id)
bookings → offer_redemptions (booking_id)
customers → bookings (customer_id)
customers → payment_orders (customer_id)
offers → offer_redemptions (offer_id)
```

## Seat Lifecycle States

```
AVAILABLE  ──hold──▶  HELD  ──confirm──▶  BOOKED
                        │                    │
                        │ (5 min expiry)      │ (cancel show)
                        ▼                    ▼
                    AVAILABLE           refunds (pending→settled/failed)
```
