# API — Screen Management

Base URL: `/api/screens`

All endpoints require two headers:
- `Authorization: Bearer <token>` — cinema admin JWT
- `X-Hall-Id: <hallId>` — active cinema hall UUID

---

## GET /api/screens

List all screens for the active hall.

**Response `200`:**
```json
[
  {
    "id": "uuid",
    "cinema_hall_id": "uuid",
    "name": "Screen 1",
    "total_seats": 120,
    "premium_seats": 20,
    "gold_seats": 40,
    "silver_seats": 60,
    "premium_price": "25.00",
    "gold_price": "18.00",
    "silver_price": "12.00",
    "rows": 10,
    "columns": 12,
    "screen_position": 1,
    "layout": { "seats": [...] },
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
]
```

---

## POST /api/screens/create

Create a new screen.

**Request Body:**
```json
{
  "name": "Screen 2",
  "total_seats": 100,
  "premium_seats": 10,
  "gold_seats": 30,
  "silver_seats": 60,
  "premium_price": 30.00,
  "gold_price": 20.00,
  "silver_price": 10.00,
  "rows": 8,
  "columns": 14,
  "screen_position": 2,
  "layout": {
    "seats": [
      { "id": "a1", "row": "A", "column": 1, "type": "seat", "isBlocked": false, "priceCategory": "premium" }
    ]
  }
}
```

**Response `201`:** The created screen object.

---

## PUT /api/screens/update/:screenId

Update an existing screen. All fields are optional — only provided fields are updated.

**Request Body:** Same shape as POST (partial allowed).

**Response `200`:** The updated screen object.

**Response `403`:** If screen does not belong to the active hall.

---

## DELETE /api/screens/delete/:screenId

Delete a screen.

**Response `200`:**
```json
{ "message": "Screen deleted successfully" }
```

**Response `403`:** If screen does not belong to the active hall.

**Response `404`:** If screen ID does not exist.

---

## Error Responses (all endpoints)

**`401 Unauthorized`:**
```json
{ "error": "Access denied. No token provided." }
```

**`400 Bad Request`:**
```json
{ "error": "Active hall not selected." }
```

**`403 Forbidden`:**
```json
{ "error": "You do not have permission to modify this screen." }
```
