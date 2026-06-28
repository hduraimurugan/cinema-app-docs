# Workflows – Ticket Verification

## Primary Flow: Verify a Ticket

```
[Patron arrives at entrance]
        │
        ▼
[Staff opens Verify Ticket page]
        │
        ├── Camera QR Scan
        │     ├── Click "Start Scan" → camera permission prompt
        │     ├── Camera activates → video preview
        │     ├── Patron shows QR code on phone
        │     ├── QR decoded → booking_id extracted
        │     └── handleBookingId(booking_id) called
        │
        ├── Image Upload QR Scan
        │     ├── Click "Upload QR Image" → file picker
        │     ├── Select screenshot containing QR code
        │     ├── Html5QrcodeScanner decodes image
        │     └── handleBookingId(booking_id) called
        │
        └── Manual Entry
              ├── Type booking ID into text field
              ├── Click "Search" button
              ├── UUID regex validates format
              └── handleBookingId(booking_id) called
                      │
                      ▼
        ┌─────────────────────────────┐
        │  UUID valid?                │
        │  /^[0-9a-f-]{36}$/i         │
        └────────┬────────────────────┘
                 │
        ┌────────┴────────┐
        │ YES             │ NO
        │                 ▼
        │         Show error:
        │         "Invalid booking ID"
        │
        ▼
[API: GET /api/booking/admin/verify/:booking_id]
        │
        ▼
┌─────────────────────────────┐
│ Backend:                    │
│ 1. verifyCinemaAdminAccess  │
│ 2. requireActiveHall        │
│ 3. UUID regex validation    │
│ 4. Query DB with joins      │
│ 5. Hall-scoped filter       │
└────────┬────────────────────┘
         │
    ┌────┴────┐
    │ Found   │ Not Found
    │         ▼
    ▼    404: "Booking not found"
[Render Booking Card]
         │
         ▼
[Staff visually confirms:
  - Movie matches showing
  - Date & time match current show
  - Seats match patron's tickets
  - Payment status is paid]
         │
    ┌────┴────┐
    │ Match   │ Mismatch
    │         ▼
    ▼    Deny entry
[Allow entry]   │
    │            └─ Escalate to management
    │
    └── Staff clicks "Verify Another" to reset
```

## Error Flow

```
handleBookingId(booking_id)
  │
  ├─ UUID regex fails             → setFetchError("Invalid booking ID format")
  │                                  return
  │
  ├─ API returns 400              → setFetchError("Invalid booking ID format")
  │
  ├─ API returns 404              → setFetchError("Booking not found")
  │
  ├─ API returns 500              → setFetchError("Failed to fetch booking details")
  │
  ├─ Network error                → setFetchError("Network error. Please try again.")
  │
  ├─ QR scan fails                → setScanError("Could not read QR code. Try again.")
  │
  └─ Camera permission denied     → setScanError("Camera permission denied.
                                      Enable camera access in browser settings.")
```

## Retry Flow

```
[Error displayed or ticket verified]
        │
        ▼
[Staff clicks "Verify Another" / "Retry"]
        │
        ▼
resetState():
  - bookingResult = null
  - scanError = null
  - fetchError = null
  - manualInput = ""
  - loading = false
  - scannerActive = false
  - imageScanning = false
  - idCopied = false
  - stop camera scanner if active
        │
        ▼
[Ready for next ticket verification]
```
