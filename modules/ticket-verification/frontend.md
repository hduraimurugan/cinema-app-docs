# Frontend – Ticket Verification

## VerifyTicket.jsx

**Path:** `cinema-hall-admin/src/pages/VerifyTicket.jsx`

### Purpose

Entry-point page for cinema staff to validate tickets at the hall entrance. Supports three scan modes and renders a complete booking summary on success.

### Dependencies

| Dependency | Version | Usage |
|---|---|---|
| `react` | ^18 | Component, hooks (`useState`, `useCallback`, `useRef`) |
| `react-router-dom` | ^6 | `useParams` for optional booking ID from URL |
| `html5-qrcode` | ^2.3 | QR scanning via `Html5Qrcode` (camera) and `Html5QrcodeScanner` (file upload) |
| `lucide-react` | ^0.x | Icons (`ScanQrCode`, `Camera`, `Upload`, `Search`, `Ticket`, `Calendar`, `Clock`, `Monitor`, `MapPin`, `User`, `CreditCard`, `RotateCcw`, `Copy`, `CheckCircle2`, `XCircle`, `RefreshCw`) |
| `@/hooks/useBookingApi` | local | `bookingAPI.verifyBooking()` |
| `@/hooks/useToast` | local | Toast notifications for errors / success |
| `@/components/ui/*` | shadcn | Card, Badge, Button, Input, Skeleton |

### State

| Variable | Type | Default | Description |
|---|---|---|---|
| `manualInput` | `string` | `""` | Manual booking ID input value |
| `bookingResult` | `object \| null` | `null` | Full booking data returned from API |
| `scanError` | `string \| null` | `null` | QR scan error message |
| `fetchError` | `string \| null` | `null` | API fetch error message |
| `loading` | `boolean` | `false` | Loading state during API call |
| `scannerActive` | `boolean` | `false` | Whether camera scanner is active |
| `imageScanning` | `boolean` | `false` | Whether image upload scan is processing |
| `idCopied` | `boolean` | `false` | Whether booking ID was copied to clipboard |

### Key Behaviour

1. **Camera QR Scan** – starts `Html5Qrcode` with camera, on decode calls `handleBookingId`.
2. **Image Upload QR Scan** – uses `Html5QrcodeScanner` file-based scanning, on decode calls `handleBookingId`.
3. **Manual Entry** – on form submit, runs UUID regex validation, then calls `handleBookingId`.
4. **handleBookingId(bookingId)** – UUID-validates, sets loading, calls `bookingAPI.verifyBooking(bookingId)`, sets result or error, stops camera.
5. **Retry** – resets all state, restarts scanner.
6. **Copy ID** – `navigator.clipboard.writeText`.
7. **Payment Status tags**:
   - `paid` → green badge
   - `refunded` → yellow badge
   - `pending` / `failed` → red badge
   - `cancelled` → gray badge

### UI Layout

```
┌─────────────────────────────────────┐
│  📷 Ticket Verification              │
│  ┌─────────────────────────────────┐ │
│  │  Camera Scanner (video stream)   │ │
│  │  [Start Scan]                    │ │
│  └─────────────────────────────────┘ │
│  [📁 Upload QR Image]               │
│  ─── or ───                         │
│  [manual input] [Search]            │
│  ┌─────────────────────────────────┐ │
│  │  Booking Summary Card           │ │
│  │  🎬 Movie Title                 │ │
│  │  📅 Date  ⏰ Time               │ │
│  │  🖥 Screen  📍 Seats            │ │
│  │  👤 Customer  📧 Email          │ │
│  │  💳 Payment: PAID ✅            │ │
│  │  ↩️ Refund: initiated (₹X)      │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```
