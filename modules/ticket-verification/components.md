# Components – Ticket Verification

## Page Component

### VerifyTicket (Page)

**Path:** `src/pages/VerifyTicket.jsx`

The root page component. Contains all scan modes and the result card inline. No sub-components are extracted — the entire verification UI lives in a single file.

**Internal sections:**

| Section | Lines (approx) | Description |
|---|---|---|
| Header | 1–20 | Page title with `ScanQrCode` icon |
| Camera Scanner | 21–60 | `Html5Qrcode` instance, start/stop controls, video preview container |
| Image Upload | 61–80 | Hidden file input + styled upload button, `Html5QrcodeScanner` for decoding |
| Divider | 81–85 | "or" separator |
| Manual Input | 86–120 | Text input + search button, form submit handler |
| Status Area | 121–140 | Loading skeleton / fetch error / scan error |
| Booking Card | 141–250 | Full booking details when result is available |
| Retry Button | 251–260 | Reset & retry after successful scan |

## Booking Card (Inline)

Renders after a successful verification. Structure:

```
BookingCard
├── Header Row
│   ├── Booking ID (copyable)
│   └── Payment Status Badge
│       ├── paid       → bg-green-500
│       ├── refunded   → bg-yellow-500
│       ├── pending    → bg-red-500
│       ├── failed     → bg-red-500
│       └── cancelled  → bg-gray-500
│
├── Movie Info Row
│   ├── Movie Title (movie_title)
│   ├── Show Date (show_date)
│   └── Start Time (start_time)
│
├── Screen & Seats Row
│   ├── Screen Name (screen_name)
│   └── Seat Labels (seat_labels)
│
├── Customer Row
│   ├── Customer Name (customer_name)
│   └── Customer Email (customer_email)
│
├── Payment Row
│   ├── Total Amount (total_amount)
│   └── Paid At (paid_at)
│
└── Refund Section (conditionally rendered)
    ├── Refund ID (refund_id)
    ├── Refund Status (refund_status)
    ├── Razorpay Refund ID (razorpay_refund_id)
    └── Refund Amount (refund_amount)
```

## Shared UI Components Used

| Component | Source | Usage |
|---|---|---|
| `Card` | `@/components/ui/card` | Booking summary container |
| `Badge` | `@/components/ui/badge` | Payment status indicator |
| `Button` | `@/components/ui/button` | Scan / Search / Retry / Copy actions |
| `Input` | `@/components/ui/input` | Manual booking ID entry field |
| `Skeleton` | `@/components/ui/skeleton` | Loading placeholder |
