# Reports & Export Module

The Reports & Export module provides admin-facing reporting data and frontend utilities for exporting tabular data to CSV and XLSX formats. It is split across the backend API (Express, PostgreSQL) and the admin frontend (React).

## Module Overview

| Layer | Functionality | Key Files |
|-------|--------------|-----------|
| **Backend** | Dashboard stats, booking listing with revenue aggregation, refund analytics | `dashboard.Controller.js`, `booking.Controller.js`, `refund.Controller.js` |
| **Frontend** | CSV/Excel export button component, export utility functions | `ExportButton.jsx`, `exportUtils.js` |

## Architecture

The backend serves three groups of report-oriented API endpoints consumed by the admin dashboard:

1. **Dashboard Stats** (`GET /api/dashboard/stats`) — single aggregated payload with today's metrics, all-time totals, 7-day revenue trend, recent bookings, and today's show occupancy.
2. **Admin Booking List** (`GET /api/booking/admin/all`) — paginated, filterable booking list with computed revenue aggregates (total_revenue, convenience_fee, gst).
3. **Refund Analytics** (`GET /api/refunds`) — paginated refund list with filters by status and date range.

The frontend provides a reusable `ExportButton` dropdown component and `exportUtils` functions that convert flat data arrays into downloadable CSV or XLSX files on the client side.

## Data Flow

```
    Admin Dashboard (React)
           │
           ├── GET /api/dashboard/stats ──► dashboard.Controller ──► PostgreSQL
           ├── GET /api/booking/admin/all ──► booking.Controller ──► PostgreSQL
           ├── GET /api/refunds ─────────────► refund.Controller ──► PostgreSQL
           │
           └── ExportButton (ExportButton.jsx)
                   ├── exportToCSV(data, filename)  ──► downloads .csv
                   └── exportToExcel(data, filename) ──► downloads .xlsx (via xlsx library)
```

## File Map

| File | Layer | Purpose |
|------|-------|---------|
| `dashboard.Controller.js` | Backend | Aggregates all dashboard reporting metrics in a single endpoint |
| `booking.Controller.js` | Backend | `getCinemaHallBookings` — filtered/paginated booking list with revenue stats |
| `refund.Controller.js` | Backend | `getRefunds`, `getRefundByBooking`, `manuallySettleRefund` |
| `ExportButton.jsx` | Frontend | Dropdown button offering CSV/Excel export |
| `exportUtils.js` | Frontend | Client-side CSV/XLSX generation and download |
