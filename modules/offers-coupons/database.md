# Database Schema

## `offers` Table

Stores all offer/coupon definitions created by SuperAdmins.

| Column | Type | Default | Description |
|---|---|---|---|
| `id` | UUID PK | | Primary key |
| `code` | VARCHAR UNIQUE | | Offer code (stored uppercase) |
| `title` | VARCHAR | | Display title |
| `description` | TEXT | NULL | Optional description shown to customers |
| `discount_type` | VARCHAR | | `percentage` or `fixed` |
| `discount_value` | DECIMAL | | Value: percentage (e.g. 10 = 10%) or fixed amount (e.g. 100 = ₹100) |
| `max_discount_amount` | DECIMAL | NULL | Cap for percentage discounts (NULL = unlimited) |
| `min_booking_amount` | DECIMAL | 0 | Minimum booking total required to apply |
| `is_active` | BOOLEAN | | Whether the offer is currently active |
| `valid_until` | TIMESTAMPTZ | | Expiry date/time |
| `scope` | VARCHAR | | `global` or `hall` |
| `cinema_hall_id` | UUID FK → cinema_hall | NULL | Required if scope = `hall` |
| `user_eligibility` | VARCHAR | `all` | `all` or `joined_after` |
| `user_joined_after` | DATE | NULL | Required if user_eligibility = `joined_after` |
| `created_by` | UUID | NULL | Admin who created the offer |
| `created_at` | TIMESTAMPTZ | NOW() | |
| `updated_at` | TIMESTAMPTZ | NOW() | |

## `offer_redemptions` Table

Records each successful application of an offer to a booking.

| Column | Type | Default | Description |
|---|---|---|---|
| `id` | UUID PK | | Primary key |
| `offer_id` | UUID FK → offers | | The redeemed offer |
| `customer_id` | UUID FK → customers | | The customer who used it |
| `booking_id` | UUID FK → bookings | | The booking where it was applied |
| `discount_applied` | DECIMAL | | Actual discount amount credited |
| `created_at` | TIMESTAMPTZ | NOW() | |

**Unique constraint:** `UNIQUE(offer_id, customer_id)` — each offer can only be used once per customer.

## Key Indexes

- `offers.code` — UNIQUE index (case-insensitive lookups via `UPPER()`)
- `offer_redemptions` — UNIQUE on `(offer_id, customer_id)`
- `offer_redemptions.customer_id` — For querying a customer's redeemed offers
- `offers.is_active` + `offers.valid_until` — For filtering active offers

## Relationships

```
offers.cinema_hall_id → cinema_hall.id           (hall-scoped offers)
offers.created_by     → admins.id                 (creator)
offer_redemptions.offer_id    → offers.id         (redeemed offer)
offer_redemptions.customer_id → customers.id      (redeeming customer)
offer_redemptions.booking_id  → bookings.id       (associated booking)
```
