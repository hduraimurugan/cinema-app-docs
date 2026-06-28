# Dashboard & Analytics Module

## Overview

The Dashboard & Analytics module provides cinema hall administrators with a centralized view of operational metrics, revenue trends, and real-time show/booking data. It serves as the default landing page after login for cinema admin users.

The module is built around a single aggregated API endpoint (`GET /api/dashboard/stats`) that returns all dashboard data in one response, generated from 8 parallel database queries.

## Key Capabilities

- **Today's Metrics** — real-time booking count, revenue, convenience fees, and GST for the current date
- **All-Time Totals** — lifetime booking count and revenue for the cinema hall
- **Customer Count** — total registered customers in the system
- **Active Offers** — count of currently valid, active offers (hall-scoped or global)
- **Screens** — total configured screens for the hall
- **Revenue Trend** — daily revenue and booking count for the last 7 days
- **Recent Bookings** — last 5 bookings with movie, customer, and seat details
- **Today's Shows** — today's show schedule with occupancy percentages derived from seat layout data

## File Structure

| File | Purpose |
|------|---------|
| `frontend.md` | React component tree, state management, chart integration |
| `backend.md` | Controller logic, query breakdown, error handling |
| `database.md` | SQL queries, table relationships, indexes |
| `api.md` | API endpoint reference, request/response schemas |
| `components.md` | UI component hierarchy and props |
| `workflows.md` | User interaction flows and data refresh patterns |
| `file-reference.md` | Complete file listing with locations and roles |

## Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React (Admin App), Recharts |
| Backend | Node.js, Express |
| Database | PostgreSQL (raw SQL, JSONB for seat layout) |
| Auth | JWT token verification + hall activation middleware |
