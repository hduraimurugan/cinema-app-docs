# Backend — `offers.Controller.js`

## `validateOfferCode()` — Shared Validation Helper

Exported function used by the offers controller (`validateOffer`) and the payment controller (`createOrder`).

**Signature:**
```js
validateOfferCode({ offer_code, show_id, total_amount, customer_id })
// Returns { offer, discountAmount }
// Throws Error with .status code on failure
```

**Validation pipeline (in order):**

| Step | Check | Error |
|---|---|---|
| 1 | Offer exists by code (case-insensitive `UPPER()`) | "Invalid offer code." (400) |
| 2 | `is_active` flag is true | "This offer is no longer active." (400) |
| 3 | `valid_until` is in the future | "This offer has expired." (400) |
| 4 | `total_amount >= min_booking_amount` | "Minimum booking amount of ₹X required." (400) |
| 5 | If `scope = 'hall'`, show's `cinema_hall_id` matches offer's | "This offer is not valid for this cinema hall." (400) |
| 6 | If `user_eligibility = 'joined_after'`, customer's `created_at > user_joined_after` | "Only available to users who joined after a specific date." (400) |
| 7 | No prior row in `offer_redemptions` for this offer + customer | "You have already used this offer." (400) |
| 8 | Calculate discount (see below) | — |

**Discount calculation:**

```
fixed:     discountAmount = offer.discount_value
percentage: raw = total * (discount_value / 100)
            discountAmount = min(raw, max_discount_amount)  // if max_discount_amount set
cap:       discountAmount = min(discountAmount, total_amount)  // never exceed booking total
```

## Controller Functions

### Admin (SuperAdmin)

| Function | Route | Description |
|---|---|---|
| `getAllCinemaHalls` | `GET /cinema-halls` | Returns `{ id, name }` for all halls |
| `getAllOffers` | `GET /` | Paginated list with filters (scope, is_active, search) |
| `createOffer` | `POST /create` | Inserts with code uppercased; returns full offer row |
| `getOfferById` | `GET /:id` | Single offer with `cinema_hall_name` join |
| `updateOffer` | `PUT /update/:id` | Full update; 404 if missing; 409 on code conflict |
| `deleteOffer` | `DELETE /delete/:id` | Hard delete; 404 if missing |

### Customer

| Function | Route | Description |
|---|---|---|
| `getActiveOffers` | `GET /active` | Active offers filtered by customer eligibility, sorted unredeemed-first |
| `validateOffer` | `POST /validate` | Validates offer against customer + show, returns discount preview |

## Routes — `offers.routes.js`

```js
// Customer (must precede /:id to avoid param capture)
GET    /api/offers/active       → verifyCustomer → getActiveOffers
POST   /api/offers/validate     → verifyCustomer → validateOffer

// Admin
GET    /api/offers/cinema-halls → verifySuperAdmin → getAllCinemaHalls
GET    /api/offers              → verifySuperAdmin → getAllOffers
GET    /api/offers/:id          → verifySuperAdmin → getOfferById
POST   /api/offers/create       → verifySuperAdmin → createOffer
PUT    /api/offers/update/:id   → verifySuperAdmin → updateOffer
DELETE /api/offers/delete/:id   → verifySuperAdmin → deleteOffer
```

## Integration — `payment.Controller.js`

### `createOrder` (line ~137-153)

When an `offer_code` is provided in the request body:
1. Calls `validateOfferCode()` to validate and compute discount
2. Uses `grandTotal - discountAmount` as the Razorpay order amount
3. Stores `offer_code` and `discount_amount` in `payment_orders` table

### `verifyPayment` (line ~314-327)

After payment verification succeeds:
1. Looks up the offer ID from `offer_code`
2. Inserts into `offer_redemptions` (offer_id, customer_id, booking_id, discount_applied)
3. Uses `ON CONFLICT (offer_id, customer_id) DO NOTHING` for idempotency

### `handlePaymentCaptured` webhook (line ~550-562)

Same redemption recording logic, duplicated for the webhook fallback path:
1. Queries offer ID from `order.offer_code`
2. Inserts into `offer_redemptions` with `ON CONFLICT DO NOTHING`
3. Applied when `verifyPayment` may not have been called (Razorpay webhook delivery)

## Error Handling

- All admin functions use try/catch with structured logging via `logger.error()`
- Validation errors carry `error.status` (400 or 404) for proper HTTP responses
- Duplicate code violations (PostgreSQL error `23505`) return `409 Conflict`
- Customer-facing endpoints return `error.message` from validation errors
