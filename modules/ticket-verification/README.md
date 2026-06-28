# Ticket Verification Module

Validates admission tickets at the cinema entrance via QR code scanning or manual booking ID lookup.

## Overview

The Ticket Verification module provides a dedicated interface for cinema hall staff to verify tickets as patrons enter. It supports three input methods:

- **Live camera QR scan** – real-time QR code capture via the device camera
- **Image upload QR scan** – scan a QR code from an uploaded screenshot or image
- **Manual entry** – type the booking ID directly

Once a ticket is resolved, the full booking summary is displayed, including movie details, screen, show time, seat labels, customer info, payment status, and any refund information.

## Key Files

| Layer | File | Purpose |
|---|---|---|
| Frontend | `VerifyTicket.jsx` | QR scanner + manual entry UI |
| Frontend | `bookingAPI.js` | API client (`verifyBooking`) |
| Backend | `booking.Controller.js` | `verifyBookingById` handler |
| Backend | `booking.Model.js` | Query builder for booking joins |
| Routes | `booking.Routes.js` | Route registration |

## Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/api/booking/admin/verify/:booking_id` | `verifyCinemaAdminAccessToken` + `requireActiveHall` | Returns full booking details for verification |

## Usage Flow

1. Staff opens Verify Ticket page (role-gated to cinema admin).
2. Scans QR / uploads image / types booking ID.
3. UUID validation runs client-side before the call.
4. Backend validates UUID format, loads booking with all joins.
5. On success, booking card renders with all details.
6. On error, appropriate error message is shown.
