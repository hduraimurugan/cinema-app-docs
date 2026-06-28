# Workflows — User App Experience

## 1. Movie Browsing Flow

```
User opens app
    → HomePage loads
        → GET /api/user/movies?status=now-showing (or location-filtered)
        → GET /api/ads/active?placement=homepage
        → Display movie grid + ad banner
    → User taps search or filter
        → MoviesPage with genre/language params
        → GET /api/user/movies with query filters
        → Update movie grid
    → User taps a movie card
        → Navigate to /movies/:id
        → MovieDetailsPage loads
        → GET /api/user/movies/:movieId/theatres?date=...&location=...
        → Group shows by hall, render showtime grid
```

## 2. Seat Selection Flow

```
User taps a showtime on MovieDetailsPage
    → Navigate to /booking/select-seats?show_id=...
    → SeatSelectionPage mounts
    → GET /api/shows/get/:id (fetch show with seat layout)
        → Loading state: skeleton grid
        → Error state: retry button
        → Success: render seat map
    → Step 1: SeatCountModal opens
        → User selects number of seats (1-10)
        → Modal closes, seat map activates
    → Step 2: User taps seats on map
        → Toggle seat selection (max = chosen count)
        → Visual: selected seats highlighted in green
        → Visual: booked/held seats greyed out
        → Visual: premium/gold/silver color-coded
    → Step 3: User taps "Proceed"
        → Validate: exactly N seats selected
        → Call POST /api/booking/hold { show_id, seats }
            → API checks seat availability
            → If conflict (409): show alert "Seat no longer available"
            → If success: store booking_id, navigate to order summary
        → Navigate to /booking/order-summary?booking_id=...
```

## 3. Payment Flow

```
OrderSummaryPage mounts
    → Load booking details from state or API
    → Display:
        - Movie title, hall name, date, time
        - Selected seats with labels and prices
        - Subtotal (sum of seat prices)
        - Discount (if offer applied)
        - Total amount
    → User enters offer code:
        → POST /api/offers/validate { code, amount }
        → If valid: show discount, update total
        → If invalid: show error toast
    → User taps "Pay Now"
        → useRazorpayPayment.initiatePayment() called
        → POST /api/payment/create-order { booking_id, amount }
            → Backend creates Razorpay order, returns order_id
        → Load Razorpay checkout script (if not loaded)
        → Open Razorpay modal with:
            - key (from settings)
            - order_id
            - amount (in paise)
            - prefill: name, email, phone (from user profile)
            - theme color (brand primary)
    → Payment success:
        → Razorpay calls success callback
        → POST /api/payment/verify {
            order_id,
            payment_id,
            razorpay_signature
          }
        → Backend verifies HMAC signature
        → If valid: booking confirmed, seats locked
        → Navigate to /booking/success?booking_id=...
    → Payment failure:
        → Razorpay calls failure callback
        → Navigate to /booking/failure
            → Show error details from Razorpay
            → "Retry" button → re-initiate payment
            → "Cancel" → POST /api/booking/release { booking_id }
```

## 4. Seat Hold Lifecycle

```
POST /api/booking/hold
    → Validate seats are available
    → Create booking record with status "hold"
    → Set hold_expires_at = now + TTL (10 mins)
    → Mark seats as "held" in show's seat_layout
    → Return booking_id and hold expiry

├── User completes payment
│   → POST /api/booking/confirm
│       → Verify Razorpay signature
│       → Update booking: status → "confirmed", payment_status → "paid"
│       → Mark seats as "booked" in seat_layout
│       → Remove hold TTL
│       → Generate QR code
│
├── User cancels / navigates away
│   → POST /api/booking/release
│       → Update booking: status → "released"
│       → Mark seats as "available" in seat_layout
│
└── TTL expires (background job / TTL index)
    → MongoDB TTL index triggers deletion or update
    → Mark seats as "available" in seat_layout
    → Update booking: status → "released"
```

## 5. Booking History Flow

```
User navigates to /bookings
    → Bookings page mounts
    → GET /api/booking/my-bookings?page=1&limit=10
    → Display paginated list
    → Tabs: "Upcoming" (future shows) | "Past" (past shows)
    
User taps a booking card
    → Navigate to /bookings/:id
    → BookingDetailPage mounts
    → GET /api/booking/:booking_id
    → Display full details + QR code
    → QR code can be scanned at venue for entry
```

## 6. Offer Validation Flow

```
User navigates to /offers
    → OffersPage mounts
    → GET /api/offers/active
    → Display offer cards

User applies offer during checkout
    → User types code in OrderSummaryPage
    → POST /api/offers/validate { code, amount }
    → Backend validates:
        1. Code exists and status = "active"
        2. Current date between valid_from and valid_until
        3. used_count < usage_limit
        4. order amount >= min_order_value
    → If valid: return discount_amount and final_amount
    → If invalid: return specific error message
```

## 7. Ad Display Flow

```
Page loads (HomePage, MovieDetailsPage, etc.)
    → GET /api/ads/active?placement=homepage
    → If ad found: render AdBanner with image and link
    → If no ad: render nothing (empty state)

User clicks ad
    → POST /api/ads/click/:id (increment counter)
    → Open link_url in new tab
```
