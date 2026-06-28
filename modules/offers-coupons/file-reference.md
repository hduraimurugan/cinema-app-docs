# File Reference

## API (cinema-hall-api)

| File | Lines | Description |
|---|---|---|
| `controllers/offers.Controller.js` | 410 | All business logic: CRUD, validation, discount calculation |
| `routes/offers.routes.js` | 31 | Route definitions with middleware |
| `controllers/payment.Controller.js` | 726 | Integration: imports `validateOfferCode`, records redemptions |

## Admin App (cinema-hall-admin)

| File | Lines | Description |
|---|---|---|
| `src/pages/OffersManagement.jsx` | 421 | Offer list with filters, pagination, delete dialog, export |
| `src/pages/OfferFormPage.jsx` | 359 | Create/edit form with conditional fields |
| `src/services/api.js` | lines 810-870 | `offersAPI` object — 6 methods |

## User App (cinema-hall-users)

| File | Lines | Description |
|---|---|---|
| `src/pages/OffersPage.jsx` | 190 | Customer-facing offer cards with copy-to-clipboard |
| `src/services/api.js` | lines 456-475 | `offersAPI` object — 2 methods |

## Database

| Table | Purpose |
|---|---|
| `offers` | Offer definitions (code, discount, scope, eligibility, validity) |
| `offer_redemptions` | One-time-use redemption tracking per customer |
