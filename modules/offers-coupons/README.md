# Offers & Coupons Module

The Offers & Coupons module powers discount promotions across the Cinema Hall platform. SuperAdmins can create offers with flexible scoping (global or hall-specific), discount types (percentage or fixed), and user eligibility rules. Customers view active offers, validate them against bookings, and redeem them during payment.

## Key Features

- **Offer Management (SuperAdmin)** — CRUD operations with filtering, search, and pagination
- **Discount Types** — Percentage-based (with optional max cap) or fixed flat amount
- **Scoping** — Global (all halls) or hall-specific
- **User Eligibility** — Available to all users or restricted to users who joined after a date
- **Redemption Tracking** — One-time use per customer (enforced by unique constraint)
- **Validation Pipeline** — 8-step server-side validation before any discount is applied
- **Payment Integration** — Offer validation + redemption recording inside order creation and payment verification

## Architecture

```
Admin App (cinema-hall-admin)
  └─ OffersManagement.jsx       → List/Filter/Delete
  └─ OfferFormPage.jsx          → Create/Edit
  └─ services/api.js            → offersAPI calls

API (cinema-hall-api)
  └─ offers.routes.js           → Route definitions
  └─ offers.Controller.js       → Business logic + validateOfferCode()
  └─ payment.Controller.js      → Imports validateOfferCode, records offer_redemptions

User App (cinema-hall-users)
  └─ OffersPage.jsx             → Browse active offers
  └─ services/api.js            → offersAPI calls
```

## Database Tables

- **offers** — Stores offer definitions (code, discount, scope, eligibility, validity)
- **offer_redemptions** — Records each customer's use of an offer (UNIQUE per customer per offer)
