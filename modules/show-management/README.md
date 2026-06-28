# Show Management Module

Manages cinema show schedules, seat bookings, and lifecycle statuses across screens and dates.

## Purpose

The Show Management module is the core scheduling engine of the cinema hall system. It handles creation (single and bulk), editing, deletion, cancellation, and status transitions of movie shows, along with seat-level booking locking.

## Architecture Overview

```
Admin Frontend (React)
    │
    ├── ShowsManagement.jsx     (Calendar view / CRUD)
    ├── ShowPage.jsx            (Seat map + booking info)
    ├── AddShowPage.jsx         (Single show form)
    ├── AddMultipleShowsPage.jsx (Bulk creation form)
    ├── EditShowPage.jsx        (Edit form)
    │
    └── showsAPI (services/api.js)
            │
            ▼
    Express API Routes
    shows.routes.js
            │
            ▼
    shows.Controller.js
            │
            ▼
    PostgreSQL ── shows table
              └── show_booked_seats table
```

## Key Concepts

| Concept | Description |
|---------|-------------|
| Show | A single screening of a movie in a specific screen at a specific date/time |
| Status Lifecycle | `scheduled → booking_started → in_progress → show_ended` |
| Cancellation | Can happen from any pre-`show_ended` status; cascades to bookings & refunds |
| Seat Locking | 10-minute `in_booking` hold during seat selection; expires automatically |
| Bulk Creation | Cross-product of screens × dates × time slots generates multiple shows |

## Files

| File | Description |
|------|-------------|
| `backend.md` | Controller logic, routes, service layer |
| `frontend.md` | Admin pages, services, component integration |
| `database.md` | Table schemas, indexes, constraints |
| `api.md` | Full API endpoint reference |
| `components.md` | Shared UI components used by show pages |
| `workflows.md` | End-to-end user workflows |
| `file-reference.md` | Full function/method reference |
