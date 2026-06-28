# API — Reports & Export

## Endpoint Summary

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `GET` | `/api/dashboard/stats` | Admin + Active Hall | Aggregated dashboard report |
| `GET` | `/api/booking/admin/all` | Admin + Active Hall | Filtered/paginated booking list with revenue stats |
| `GET` | `/api/booking/admin/verify/:booking_id` | Admin + Active Hall | Single booking lookup (QR scan) |
| `GET` | `/api/refunds` | Admin + Active Hall | Filtered/paginated refund list |
| `GET` | `/api/refunds/booking/:booking_id` | Admin + Active Hall | Refund record for a specific booking |
| `POST` | `/api/refunds/:refund_id/settle` | Admin + Active Hall | Manually mark refund as settled |

## Authentication

All endpoints require two middleware functions:

1. **`verifyCinemaAdminAccessToken`** — validates the admin JWT access token and attaches `req.admin`.
2. **`requireActiveHall`** — ensures the admin has an active cinema hall selected and attaches `req.currentHallId`.

## Common Response Patterns

- Success: `200` with JSON body.
- Auth failure: `401` or `403`.
- Not found: `404` with `{ "error": "..." }`.
- Server error: `500` with `{ "error": "..." }`.

## GET /api/dashboard/stats

Returns all data needed for the admin dashboard home page in a single request.

**Response fields:**

| Field | Type | Description |
|-------|------|-------------|
| `today.bookings` | `number` | Booking count for today |
| `today.revenue` | `number` | Total revenue for today |
| `today.convenience_fee` | `number` | Convenience fees for today |
| `today.gst` | `number` | GST amount for today |
| `allTime.bookings` | `number` | All-time booking count |
| `allTime.revenue` | `number` | All-time total revenue |
| `customers` | `number` | Total registered customers |
| `activeOffers` | `number` | Count of currently active offers |
| `screens` | `number` | Number of screens in the hall |
| `revenueTrend` | `Array` | 7-day revenue array `[{date, revenue, bookings_count}]` |
| `recentBookings` | `Array` | Last 5 bookings with movie/customer/seat data |
| `todayShows` | `Array` | Today's shows with total/booked seat counts |

## GET /api/booking/admin/all

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_date` | `string` (date) | No | Lower bound for show date |
| `to_date` | `string` (date) | No | Upper bound for show date |
| `search` | `string` | No | Partial movie title match (case-insensitive) |
| `status` | `string` | No | Exact `booking_status` value |
| `screen_id` | `string` (UUID) | No | Filter by screen |
| `page` | `integer` | No | Page number (default 1) |
| `limit` | `integer` | No | Items per page (default 10, max 100) |

**Response fields:**

| Field | Type | Description |
|-------|------|-------------|
| `bookings` | `Array` | Booking rows with joined movie/screen/customer/seat data |
| `total` | `number` | Total matching booking count (for pagination) |
| `page` | `number` | Current page number |
| `stats.total_revenue` | `number` | Sum of `total_amount` for filtered results |
| `stats.total_convenience_fee` | `number` | Sum of `convenience_fee` for filtered results |
| `stats.total_gst` | `number` | Sum of `gst_amount` for filtered results |

## GET /api/refunds

**Query parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `status` | `string` | No | Filter by `refund_status`; pass `"all"` to skip filter |
| `from_date` | `string` (date) | No | Lower bound for `initiated_at` |
| `to_date` | `string` (date) | No | Upper bound for `initiated_at` |
| `page` | `integer` | No | Page number (default 1) |
| `limit` | `integer` | No | Items per page (default 10, max 100) |

**Response fields:**

| Field | Type | Description |
|-------|------|-------------|
| `refunds` | `Array` | Refund rows with joined booking/movie/screen/customer data and seat labels |
| `total` | `number` | Total matching refund count |

## GET /api/refunds/booking/:booking_id

Returns the refund record for a single booking. Returns 404 if no refund exists for that booking.

## POST /api/refunds/:refund_id/settle

**Request:** No body required.

Manually marks a refund as settled. Validates ownership via cinema hall. Returns 400 if already settled.
