# API Reference

Base path: `/api/offers`

## Admin Endpoints (SuperAdmin)

All admin routes require `verifySuperAdmin` middleware.

### GET /api/offers/cinema-halls

Returns all cinema halls for form dropdowns.

**Response:**
```json
{
  "halls": [{ "id": "uuid", "name": "PVR Cinemas" }]
}
```

### GET /api/offers

Paginated offer list with filtering.

**Query params:** `scope` (global|hall), `is_active` (true|false), `search` (matches code or title), `page` (default 1, limit 50)

**Response:**
```json
{
  "offers": [{ ...offer with cinema_hall_name }],
  "total": 42,
  "page": 1
}
```

### POST /api/offers/create

Create a new offer.

**Body:**
| Field | Type | Required |
|---|---|---|
| `code` | string | yes |
| `title` | string | yes |
| `description` | string | no |
| `discount_type` | "percentage" | "fixed" | yes |
| `discount_value` | number | yes |
| `max_discount_amount` | number | no |
| `min_booking_amount` | number | no |
| `is_active` | boolean | no (default true) |
| `valid_until` | ISO date | yes |
| `scope` | "global" | "hall" | no (default "global") |
| `cinema_hall_id` | uuid | if scope=hall |
| `user_eligibility` | "all" | "joined_after" | no (default "all") |
| `user_joined_after` | ISO date | if user_eligibility=joined_after |

### GET /api/offers/:id

Single offer by ID.

### PUT /api/offers/update/:id

Full update (same body as create). Code cannot be changed (frontend disables it).

### DELETE /api/offers/delete/:id

Hard delete. **Response:** `{ "message": "Offer deleted." }`

---

## Customer Endpoints

Both require `verifyCustomer` middleware.

### GET /api/offers/active

Returns offers eligible for the authenticated customer.

**Logic:**
1. Loads customer's `created_at` for eligibility check
2. Loads customer's previously redeemed offer IDs
3. Fetches all active, non-expired offers
4. Filters by `user_eligibility` (joined_after check)
5. Marks each offer with `is_redeemed: true/false`
6. Sorts: unredeemed offers first

**Response:**
```json
{
  "offers": [{ ...offer with is_redeemed, cinema_hall_name }]
}
```

### POST /api/offers/validate

Server-side offer validation and discount preview.

**Body:** `{ "offer_code": "SAVE50", "show_id": "uuid", "total_amount": 500 }`

**Response:**
```json
{
  "offer_id": "uuid",
  "offer_code": "SAVE50",
  "offer_title": "Save ₹50",
  "discount_amount": 50,
  "final_amount": 450
}
```

**Error codes:**
- `400` — Invalid code, expired, inactive, min amount not met, wrong hall, eligibility fail, already redeemed
- `404` — Show not found / Customer not found
