# API Reference

Base path: `/api/offers`

## Admin Endpoints (RBAC — `offers.*`, creator-scoped since `6e0705a`)

All admin routes now use `verifyCinemaAdminAccessToken` + `requirePermission('offers.*')` (`routes/offers.routes.js:27`). SuperAdmin bypasses ownership checks; org members are scoped to their own `offers.created_by` and their `org_id` halls via `resolveOrgId`.

### GET /api/offers/cinema-halls — `requirePermission('offers.create')` (`routes/offers.routes.js:27`, `controllers/offers.Controller.js:110`, `6e0705a`)

Halls the caller may assign an offer to. SuperAdmin → `SELECT id, name FROM cinema_hall ORDER BY name`. Org member → `resolveOrgId(req.admin.id)` then `WHERE org_id = $1`; `403 No organization found` if none.

**Response:**
```json
{
  "halls": [{ "id": "uuid", "name": "PVR Cinemas" }]
}
```

### GET /api/offers — `requirePermission('offers.read')` (`controllers/offers.Controller.js:134`, `6e0705a`)

Paginated offer list with filtering. SuperAdmin sees all; others `AND created_by = req.admin.id`.

**Query params:** `scope` (global|hall), `is_active` (true|false), `search` (matches code or title), `page` (default 1, limit 50)

**Response (joined `created_by_*` since `6e0705a`):**
```json
{
  "offers": [{ "...offer": "...", "cinema_hall_name": "PVR", "created_by_name": "Alice", "created_by_email": "a@org.com", "created_by_role": "owner | admin | Super Admin" }],
  "total": 42,
  "page": 1
}
```
Creator role is resolved via `LATERAL` join over `organization_members` + `roles` ordered by hall existence / owner / `created_at`.

**Errors:** none beyond auth; empty `halls`/`offers` is `200` with empty arrays.

### POST /api/offers/create — `requirePermission('offers.create')` (`controllers/offers.Controller.js:221`, `6e0705a`)

Create a new offer. Access: `scope=global` requires `req.admin.role === 'superAdmin'` else `403 Only Super Admin can create global offers.`; `scope=hall` for non-SuperAdmin requires `cinema_hall_id` and `SELECT org_id FROM cinema_hall WHERE id=$1` matches `resolveOrgId(req.admin.id)` else `403 You can only create offers for your own cinema hall.` / `403 No organization found`.

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
| `cinema_hall_id` | uuid | if scope=hall (and required for non-SuperAdmin hall offers) |
| `user_eligibility` | "all" | "joined_after" | no (default "all") |
| `user_joined_after` | ISO date | if user_eligibility=joined_after |

### GET /api/offers/:id — `requirePermission('offers.read')` (`controllers/offers.Controller.js:280`, `6e0705a`)

Single offer by ID. Joins `cinema_hall` + `cinema_admin_user` for `cinema_hall_name` / `created_by_name`. Non-SuperAdmin may only view own offers: `403 You can only view offers you created.` if `created_by !== req.admin.id`. `404 Offer not found.` if missing.

### PUT /api/offers/update/:id — `requirePermission('offers.update')` (`controllers/offers.Controller.js:308`, `6e0705a`)

Full update (same body as create). Code cannot be changed (frontend disables it). Same creator/ownership and global/hall scope checks as create (fetches existing `created_by` first; `404` if missing, `403 You can only edit offers you created.` for non-owners). `409` on code conflict.

### DELETE /api/offers/delete/:id — `requirePermission('offers.delete')` (`controllers/offers.Controller.js:395`, `6e0705a`)

Hard delete. Checks `created_by` ownership (`403 You can only delete offers you created.` for non-SuperAdmin non-owners, `404 Offer not found.`). **Response:** `{ "message": "Offer deleted." }`

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
