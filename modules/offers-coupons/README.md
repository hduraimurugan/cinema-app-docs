# Offers & Coupons Module

The Offers & Coupons module powers discount promotions across the Cinema Hall platform. Any admin with `offers.*` permissions can manage offers, scoped by creator and organization: SuperAdmin sees and edits all offers and halls, org members see/create/edit/delete only their own offers and only their `org_id` halls (`6e0705a`, `a79e555`). Global offers remain SuperAdmin-only. Customers view active offers, validate them against bookings, and redeem them during payment.

## Key Features

- **Offer Management (RBAC + creator-scoped)** — CRUD gated by `offers.read` / `offers.create` / `offers.update` / `offers.delete`; SuperAdmin sees all, others `WHERE created_by = req.admin.id` (`controllers/offers.Controller.js:134`, `6e0705a`)
- **Discount Types** — Percentage-based (with optional max cap) or fixed flat amount
- **Scoping** — Global (all halls, SuperAdmin-only since `6e0705a`) or hall-specific (org members limited to `WHERE org_id = resolveOrgId(req.admin.id)` halls)
- **User Eligibility** — Available to all users or restricted to users who joined after a date
- **Redemption Tracking** — One-time use per customer (enforced by unique constraint)
- **Validation Pipeline** — 8-step server-side validation before any discount is applied
- **Payment Integration** — Offer validation + redemption recording inside order creation and payment verification
- **Creator Attribution** — `offers.created_by` joined to `cinema_admin_user` + `LATERAL creator_role` surfaces `created_by_name/email/role` in list/detail responses (`6e0705a`); admin table shows avatar initials + role pill (`OffersManagement.jsx:40`, `a79e555`)

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
