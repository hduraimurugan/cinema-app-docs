# User App Experience Module

## Overview

The User App Experience module powers the customer-facing application (`cinema-hall-users`). It handles the entire customer journey — browsing movies and theatres, selecting seats, placing orders, processing payments, and viewing booking history.

## Scope

| Area | Description |
|------|-------------|
| **Movies** | Catalog browsing, filtering by genre/language, location-based discovery |
| **Theatres** | Cinema hall showtimes, hall information, location-based theatre discovery |
| **Seat Selection** | Interactive seat maps with pricing tiers (Premium/Gold/Silver), availability tracking |
| **Orders** | Booking flow (hold → confirm), Razorpay payment integration, success/failure handling, offers/discounts |

## Module Architecture

```
cinema-hall-users/           # User-facing React application
├── src/
│   ├── pages/               # Page-level components (one per route)
│   ├── components/          # Shared UI components
│   ├── hooks/               # Custom React hooks (Razorpay, etc.)
│   ├── services/            # API service layer
│   └── utils/               # Helper utilities

cinema-hall-api/             # Backend API
├── routes/                  # Express route handlers
├── controllers/             # Business logic
├── models/                  # MongoDB/Mongoose data models
└── middleware/               # Auth, validation, error handling
```

## Key User Flow

1. **Browse** — Homepage shows now-playing movies; user can filter by genre/language or search
2. **Select Movie** — Movie details page displays showtimes grouped by cinema hall for the chosen date and location
3. **Select Show** — Show selection leads to seat map with interactive layout
4. **Choose Seats** — Seat count modal, then pick individual seats from the map
5. **Review Order** — Order summary with pricing, offer code input, total calculation
6. **Pay** — Razorpay checkout (handled by `useRazorpayPayment` hook)
7. **Confirmation** — Success page with QR code; failure page with retry option

## Module Files

| Doc File | Content |
|----------|---------|
| [frontend.md](frontend.md) | Pages, components, hooks, services, utilities |
| [backend.md](backend.md) | Route handlers, controllers, middleware |
| [database.md](database.md) | MongoDB schemas and indexes |
| [api.md](api.md) | Full API contract (endpoints, request/response shapes) |
| [components.md](components.md) | Component API, props, states |
| [workflows.md](workflows.md) | Detailed flow diagrams and step-by-step logic |
| [file-reference.md](file-reference.md) | Every file with purpose and key exports |

## Related Modules

- **Auth Module** — Login/signup modal, token management, session handling
- **Admin Module** — Movie, show, hall management (creates data consumed by this module)
- **Notification Module** — Booking confirmations, promotional notifications
