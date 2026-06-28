# Components — Reports & Export

## Frontend Components

### ExportButton

| Attribute | Detail |
|-----------|--------|
| **File** | `cinema-hall-admin/src/components/ExportButton.jsx` |
| **Framework** | React + shadcn/ui |
| **Type** | Dropdown menu button |

**Structure:**

```
┌─────────────────────────────────┐
│  [↓] Export                     │  ← DropdownMenuTrigger (Button)
└─────────────────────────────────┘
         │
         ├── Export as CSV     → exportToCSV(data, filename)
         └── Export as Excel   → exportToExcel(data, filename)
```

**Internal dependencies:**
- `lucide-react`: `Download`, `FileSpreadsheet`, `FileText` icons
- `@/components/ui/button`: shadcn `Button`
- `@/components/ui/dropdown-menu`: shadcn `DropdownMenu`, `DropdownMenuContent`, `DropdownMenuItem`, `DropdownMenuTrigger`
- `@/utils/exportUtils`: `exportToCSV`, `exportToExcel`

**States:**

| State | Behavior |
|-------|----------|
| Normal (data present) | Button is enabled; clicking opens dropdown with both export options |
| Empty data (`data.length === 0`) | Button is disabled |
| `disabled={true}` | Button is disabled (e.g. while data is loading) |

## Backend Controllers

### dashboard.Controller.js

**Exports:** `getDashboardStats`

A single controller function that orchestrates 8 parallel database queries into one unified response. No sub-controllers or helper modules are used; all query logic is self-contained.

### booking.Controller.js

**Exports relevant to reporting:** `getCinemaHallBookings`

The `getCinemaHallBookings` controller runs three sequential queries (data, count, stats) rather than parallel, because the same filter parameters are reused. The `stats` aggregate respects all applied filters, giving admins filtered subtotals.

### refund.Controller.js

**Exports:** `getRefunds`, `getRefundByBooking`, `manuallySettleRefund`

Three standalone functions. `getRefunds` builds dynamic WHERE clauses based on query parameters using parameterized queries to prevent injection.

## Utility Modules

### exportUtils.js

**Exports:** `exportToCSV`, `exportToExcel`

Pure utility functions with no React dependency. Can be used outside of `ExportButton` (e.g. from custom page-level export triggers).

### Middleware

All backend report endpoints share two middleware functions from `cinema-hall-api/middleware/verifyCinemaAdmin.js`:

- `verifyCinemaAdminAccessToken` — validates JWT, attaches `req.admin`
- `requireActiveHall` — validates active hall is selected, attaches `req.currentHallId`
