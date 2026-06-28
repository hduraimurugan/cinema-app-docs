# API – Ticket Verification

## GET /api/booking/admin/verify/:booking_id

### Full Specification

**Description:** Looks up a booking by its public UUID and returns a complete verification summary.

**Authentication:** `verifyCinemaAdminAccessToken` (bearer token in `Authorization` header)

**Context:** `requireActiveHall` (hall ID extracted from session/JWT)

### Request

| Parameter | Type | Location | Required | Description |
|---|---|---|---|---|
| `booking_id` | `string` (UUID v4) | Path | Yes | Public booking identifier |
| `Authorization` | `string` | Header | Yes | `Bearer <token>` |

### Response: 200 OK

```json
{
  "booking": {
    "id": 42,
    "booking_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "total_amount": 750.00,
    "payment_status": "paid",
    "paid_at": "2026-06-27T18:30:00.000Z",
    "cancelled_at": null,
    "created_at": "2026-06-20T10:15:00.000Z",
    "show_id": 15,
    "show_date": "2026-06-28",
    "start_time": "19:00:00",
    "movie_title": "Interstellar",
    "screen_name": "Screen 1",
    "customer_name": "John Doe",
    "customer_email": "john@example.com",
    "seat_labels": "A1, A2, A3",
    "refund_id": null,
    "refund_status": null,
    "razorpay_refund_id": null,
    "refund_amount": null
  }
}
```

### Response: 400 Bad Request

```json
{
  "error": "Invalid booking ID format"
}
```

Triggered when `booking_id` does not match the UUID v4 regex.

### Response: 404 Not Found

```json
{
  "error": "Booking not found"
}
```

Triggered when no booking exists with the given UUID under the current hall.

### Response: 500 Internal Server Error

```json
{
  "error": "Failed to fetch booking details"
}
```

Triggered on unexpected database or server errors.

### Frontend Integration

```js
// bookingAPI.js (simplified)
const verifyBooking = async (bookingId) => {
  const response = await apiClient.get(
    `/booking/admin/verify/${bookingId}`
  );
  return response.data.booking;
};
```
