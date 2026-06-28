# Booking Management & Payment / Refunds Module

Combined module handling the full lifecycle of cinema seat booking, payment processing via Razorpay, and refund management. Covers both Customer-facing (seat selection, checkout, booking history) and Admin-facing (booking oversight, payment order tracking, refund management, QR ticket verification) workflows.

## Architecture Overview

```
Customer App (React)                       Admin App (React)
  SeatSelectionPage                          Bookings page
  OrderSummaryPage                           BookingDetailPage
  BookingSuccessPage                         PaymentOrders page
  BookingFailurePage                         RefundsPage
  Bookings (history)                         VerifyTicket (QR scan)
  BookingDetailPage
```

```
API Layer (Express)
  booking.Controller.js        payment.Controller.js        refund.Controller.js
  booking.routes.js            payment.routes.js            refund.routes.js
```

```
Database
  show_booked_seats    bookings    payment_orders    refunds
  webhook_events       offer_redemptions
```

```
External
  Razorpay (order creation, checkout, webhooks)
```

## Core Flow

| Step | Action | Key Concern |
|------|--------|-------------|
| 1 | Hold Seats | Row-level `FOR UPDATE` locking, 5-min expiry, all-or-nothing |
| 2 | Create Order | Server-side pricing, idempotency check, offer validation |
| 3 | Razorpay Checkout | Frontend modal via `useRazorpayPayment` hook |
| 4 | Verify Payment | HMAC signature, idempotent booking insert, `ON CONFLICT` safety |
| 5 | Webhook Fallback | `payment.captured` / `order.paid` as backup confirmation path |

## Key Design Properties

- **Idempotency at every layer**: duplicate `createOrder`, `verifyPayment`, and webhook deliveries all safely return existing results without side effects.
- **Atomic seat transitions**: `FOR UPDATE` row locking ensures no two customers can hold the same seat concurrently.
- **Webhook as fallback**: if the customer's browser closes right after Razorpay success, the webhook completes the booking.
- **Server-side pricing**: seat prices, convenience fees, GST, and offer discounts are all calculated on the backend — never trusted from the client.
- **QR ticket verification**: admin scans the booking UUID at cinema entrance; uses regex validation and hall-scoped lookup.

## Module Boundaries

| Concern | Controller |
|---------|-----------|
| Seat holding, confirming, releasing | `booking.Controller.js` |
| Payment order creation, verification, webhooks | `payment.Controller.js` |
| Refund listing, per-booking lookup, manual settlement | `refund.Controller.js` |

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `RAZORPAY_KEY_ID` | Razorpay API key (public) |
| `RAZORPAY_KEY_SECRET` | Razorpay secret for order creation & HMAC |
| `RAZORPAY_WEBHOOK_SECRET` | Shared secret for webhook HMAC verification |
| `VITE_API_BASE_URL` | Frontend API base URL |
