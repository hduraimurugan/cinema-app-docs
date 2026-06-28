# API — User App Experience

## Movies

### GET /api/user/movies

List all movies.

**Query Params:** `?status=now-showing&genre=Action&language=Tamil`

**Response `200`:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "664a...",
      "title": "Movie Title",
      "poster_url": "...",
      "genre": ["Action", "Thriller"],
      "language": ["Tamil"],
      "duration_minutes": 148,
      "rating": "U/A",
      "status": "now-showing"
    }
  ],
  "pagination": { "page": 1, "limit": 20, "total": 50 }
}
```

### GET /api/user/movies/location/:location

Movies available in a city.

**Params:** `:location` — city name (e.g. `Chennai`)

**Response:** Same shape as above, filtered by halls in that city.

### GET /api/user/movies/:movieId

Single movie details.

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "title": "...",
    "poster_url": "...",
    "backdrop_url": "...",
    "genre": ["..."],
    "language": ["..."],
    "duration_minutes": 148,
    "release_date": "2026-06-01T00:00:00Z",
    "rating": "U/A",
    "synopsis": "...",
    "cast": [{ "name": "...", "role": "...", "image_url": "..." }],
    "status": "now-showing"
  }
}
```

### GET /api/user/movies/:movieId/theatres

Theatres showing movie with showtimes for a date.

**Query Params:** `?date=2026-06-28&location=Chennai`

**Response `200`:**
```json
{
  "success": true,
  "data": [
    {
      "hall_id": "...",
      "name": "PVR Velachery",
      "location": { "city": "Chennai", "state": "Tamil Nadu" },
      "amenities": ["Dolby Atmos", "Recliner"],
      "shows": [
        {
          "show_id": "...",
          "start_time": "2026-06-28T10:30:00Z",
          "end_time": "2026-06-28T13:18:00Z",
          "has_offer": true,
          "seat_pricing": { "premium": 40000, "gold": 30000, "silver": 20000 }
        }
      ]
    }
  ]
}
```

## Shows

### GET /api/shows/get/:id

Show details with full seat layout.

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "hall_id": { "_id": "...", "name": "..." },
    "movie_id": { "_id": "...", "title": "...", "poster_url": "..." },
    "show_date": "2026-06-28T00:00:00Z",
    "start_time": "2026-06-28T10:30:00Z",
    "end_time": "2026-06-28T13:18:00Z",
    "seat_pricing": { "premium": 40000, "gold": 30000, "silver": 20000 },
    "seat_layout": [
      [
        { "row": 1, "col": 1, "category": "premium", "status": "available", "label": "P1" },
        { "row": 1, "col": 2, "category": "premium", "status": "booked", "label": "P2" },
        { "row": 1, "col": 3, "category": "premium", "status": "held", "label": "P3" }
      ]
    ],
    "status": "scheduled"
  }
}
```

**Seat status values:** `available`, `booked`, `held`, `unavailable`

## Booking

All booking endpoints require `Authorization: Bearer <token>` header.

### POST /api/booking/hold

Hold seats temporarily.

**Request:**
```json
{
  "show_id": "...",
  "seats": [
    { "row": 1, "col": 3 },
    { "row": 1, "col": 4 }
  ]
}
```

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "booking_id": "...",
    "hold_expires_at": "2026-06-28T10:25:00Z",
    "total_amount": 60000,
    "seats": [
      { "row": 1, "col": 3, "category": "gold", "label": "G3", "price": 30000 },
      { "row": 1, "col": 4, "category": "gold", "label": "G4", "price": 30000 }
    ]
  }
}
```

**Error `409`:**
```json
{ "success": false, "message": "One or more seats are no longer available" }
```

### POST /api/booking/confirm

Confirm booking after payment.

**Request:**
```json
{
  "booking_id": "...",
  "payment_id": "pay_...",
  "order_id": "order_...",
  "signature": "..." 
}
```

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "booking_id": "...",
    "booking_status": "confirmed",
    "confirmed_at": "2026-06-28T10:20:00Z",
    "qr_code": "BK-664a...",
    "total_amount": 60000,
    "seats": [
      { "row": 1, "col": 3, "category": "gold", "label": "G3" },
      { "row": 1, "col": 4, "category": "gold", "label": "G4" }
    ]
  }
}
```

### POST /api/booking/release

Release held seats (user cancels or navigates away).

**Request:**
```json
{ "booking_id": "..." }
```

**Response `200`:**
```json
{ "success": true, "message": "Seats released" }
```

### GET /api/booking/my-bookings

List authenticated user's bookings.

**Query Params:** `?status=confirmed&page=1&limit=10`

**Response `200`:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "show_id": { "start_time": "...", "end_time": "..." },
      "movie_id": { "title": "...", "poster_url": "..." },
      "hall_id": { "name": "...", "location": { "city": "..." } },
      "seats": [...],
      "total_amount": 60000,
      "booking_status": "confirmed",
      "confirmed_at": "..."
    }
  ],
  "pagination": { "page": 1, "limit": 10, "total": 3 }
}
```

### GET /api/booking/:booking_id

Single booking detail.

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "show_id": { "start_time": "...", "end_time": "..." },
    "movie_id": { "title": "...", "poster_url": "..." },
    "hall_id": { "name": "...", "location": { "city": "..." } },
    "seats": [...],
    "total_amount": 60000,
    "discount_amount": 5000,
    "offer_code": "WELCOME50",
    "payment_status": "paid",
    "booking_status": "confirmed",
    "confirmed_at": "...",
    "qr_code": "..."
  }
}
```

## Payment

### POST /api/payment/create-order

Create a Razorpay order.

**Request:**
```json
{
  "booking_id": "...",
  "amount": 60000,
  "currency": "INR"
}
```

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "order_id": "order_...",
    "amount": 60000,
    "currency": "INR",
    "razorpay_key_id": "rzp_..."
  }
}
```

### POST /api/payment/verify

Verify Razorpay payment signature.

**Request:**
```json
{
  "order_id": "order_...",
  "payment_id": "pay_...",
  "razorpay_signature": "..."
}
```

**Response `200`:**
```json
{ "success": true, "data": { "booking_id": "..." } }
```

**Error `400`:**
```json
{ "success": false, "message": "Payment verification failed" }
```

## Offers

### GET /api/offers/active

List currently active offers.

**Response `200`:**
```json
{
  "success": true,
  "data": [
    {
      "_id": "...",
      "code": "WELCOME50",
      "description": "50% off on your first booking (max ₹150)",
      "discount_type": "percentage",
      "discount_value": 50,
      "max_discount": 15000,
      "min_order_value": 10000,
      "valid_until": "2026-07-31T00:00:00Z"
    }
  ]
}
```

### POST /api/offers/validate

Validate and apply an offer code.

**Request:**
```json
{
  "code": "WELCOME50",
  "amount": 60000
}
```

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "valid": true,
    "discount_amount": 15000,
    "final_amount": 45000
  }
}
```

**Error `400`:**
```json
{ "success": false, "message": "Offer has expired / usage limit reached / min order not met" }
```

## Ads

### GET /api/ads/active?placement=homepage

Get active ad for a placement.

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "_id": "...",
    "title": "New Movie Trailer",
    "image_url": "...",
    "link_url": "...",
    "placement": "homepage"
  }
}
```

### POST /api/ads/click/:id

Record ad click (increments counter).

**Response `200`:**
```json
{ "success": true, "message": "Click recorded" }
```

## Settings (Public)

### GET /api/settings

Get public settings.

**Response `200`:**
```json
{
  "success": true,
  "data": {
    "razorpay_key_id": "rzp_live_...",
    "seat_hold_ttl_minutes": 10,
    "max_seats_per_booking": 10
  }
}
```
