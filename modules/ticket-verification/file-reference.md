# File Reference – Ticket Verification

## Source Files

| # | File | Role |
|---|---|---|
| 1 | `cinema-hall-admin/src/pages/VerifyTicket.jsx` | Frontend page: QR scanner, manual input, booking card |
| 2 | `cinema-hall-admin/src/hooks/useBookingApi.js` (or `services/bookingAPI.js`) | API client exposing `verifyBooking(bookingId)` |
| 3 | `backend/src/controllers/booking.Controller.js` | Controller: `verifyBookingById` handler |
| 4 | `backend/src/models/booking.Model.js` | Model: `getBookingForVerification` query builder |
| 5 | `backend/src/routes/booking.Routes.js` | Route registration with middleware chain |

## Frontend Dependency Graph

```
VerifyTicket.jsx
  ├── react / react-router-dom (useParams)
  ├── html5-qrcode (Html5Qrcode, Html5QrcodeScanner)
  ├── lucide-react (17 icons)
  ├── @/hooks/useBookingApi
  │     └── bookingAPI.verifyBooking(bookingId)
  │           └── GET /api/booking/admin/verify/:booking_id
  ├── @/hooks/useToast
  └── @/components/ui/
        ├── Card
        ├── Badge
        ├── Button
        ├── Input
        └── Skeleton
```

## Backend Dependency Graph

```
booking.Routes.js
  └── verifyCinemaAdminAccessToken (middleware)
  └── requireActiveHall (middleware)
  └── bookingController.verifyBookingById
        └── Booking.getBookingForVerification(bookingId, hallId)
              └── SQL JOIN: bookings → shows → movies → screens → customers
              └── LEFT JOIN: refunds (correlated subquery)
```

## API Route Map

```
GET /api/booking/admin/verify/:booking_id
  ├── verifyCinemaAdminAccessToken
  │     └── Extracts & validates JWT from Authorization header
  │     └── Ensures user.role === "cinema_admin"
  │     └── Sets req.user
  │
  ├── requireActiveHall
  │     └── Checks req.user.activeHallId exists
  │     └── Sets req.hallId
  │
  └── bookingController.verifyBookingById
        ├── Validates UUID format
        ├── Calls Booking.getBookingForVerification(bookingId, hallId)
        └── Returns 200 / 400 / 404 / 500
```

## Environment Dependencies

| Dependency | VerifyTicket | Controller | Model |
|---|---|---|---|
| Node.js | ✓ (React build) | ✓ | ✓ |
| PostgreSQL | — | — | ✓ (query) |
| Razorpay | — | — | ✓ (refund_id stored) |
| Camera (browser) | ✓ (getUserMedia) | — | — |
| html5-qrcode | ✓ (2.3.x) | — | — |
