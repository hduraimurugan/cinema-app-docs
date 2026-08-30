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

### Admin (RBAC + creator/org-scoped since `6e0705a` — `controllers/offers.Controller.js:1` imports `resolveOrgId`)

| Function | Route | Description |
|---|---|---|
| `getAllCinemaHalls` | `GET /cinema-halls` | `requirePermission('offers.create')`. SuperAdmin → all `{id,name}`; org member → `resolveOrgId` then `WHERE org_id=$1`; `403 No organization found` if none |
| `getAllOffers` | `GET /` | `requirePermission('offers.read')`. Paginated filters + `AND created_by=$4` for non-SuperAdmin; joins `cinema_admin_user` + `LATERAL creator_role` for `created_by_name/email/role` (`Super Admin` fallback); `LIMIT 50 OFFSET $5` |
| `createOffer` | `POST /create` | `requirePermission('offers.create')`. Global requires SuperAdmin (`403`); hall for non-SuperAdmin validates `cinema_hall_id` belongs to `resolveOrgId` org (`403 You can only create offers for your own cinema hall.`) |
| `getOfferById` | `GET /:id` | `requirePermission('offers.read')`. Joins `cinema_hall_name` + `created_by_name`; creator ownership `403 You can only view offers you created.` |
| `updateOffer` | `PUT /update/:id` | `requirePermission('offers.update')`. Fetch existing `created_by`; ownership + global/hall scope checks mirror create; `404`/`403`/`409` |
| `deleteOffer` | `DELETE /delete/:id` | `requirePermission('offers.delete')`. Ownership check `403 You can only delete offers you created.`; `404` if missing |

### Customer

| Function | Route | Description |
|---|---|---|
| `getActiveOffers` | `GET /active` | Active offers filtered by customer eligibility, sorted unredeemed-first |
| `validateOffer` | `POST /validate` | Validates offer against customer + show, returns discount preview |

## Routes — `offers.routes.js` (`routes/offers.routes.js:27`, `6e0705a`)

```js
// Customer (must precede /:id to avoid param capture)
GET    /api/offers/active       → verifyCustomer → getActiveOffers
POST   /api/offers/validate     → verifyCustomer → validateOffer

// Admin — hall-scoped permission, not platform superAdmin (comment at line 25)
GET    /api/offers/cinema-halls → verifyCinemaAdminAccessToken + requirePermission('offers.create') → getAllCinemaHalls
GET    /api/offers              → verifyCinemaAdminAccessToken + requirePermission('offers.read')   → getAllOffers
GET    /api/offers/:id          → verifyCinemaAdminAccessToken + requirePermission('offers.read')   → getOfferById
POST   /api/offers/create       → verifyCinemaAdminAccessToken + requirePermission('offers.create') → createOffer
PUT    /api/offers/update/:id   → verifyCinemaAdminAccessToken + requirePermission('offers.update') → updateOffer
DELETE /api/offers/delete/:id   → verifyCinemaAdminAccessToken + requirePermission('offers.delete') → deleteOffer
POST   /api/offers/:id/announce → verifyCinemaAdminAccessToken + requirePermission('offers.update') → announceOfferById (99c1870)
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
