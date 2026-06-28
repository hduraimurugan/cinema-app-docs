# File Reference — Reports & Export

## Backend

### cinema-hall-api/controllers/dashboard.Controller.js

| Line | Symbol | Kind | Description |
|------|--------|------|-------------|
| 9 | `getDashboardStats` | `async (req, res)` | Main handler for `GET /api/dashboard/stats`. Runs 8 parallel queries returning aggregated dashboard data. |
| 26-37 | Query a | `client.query` | Today's bookings, revenue, convenience_fee, gst filtered by `cinema_hall_id` and `CURRENT_DATE`. |
| 40-48 | Query b | `client.query` | All-time total bookings and revenue. |
| 51 | Query c | `client.query` | Total customer count (`SELECT COUNT(*) FROM customers`). |
| 54-60 | Query d | `client.query` | Active offers count (hall-specific or global, `is_active = true`, `valid_until >= NOW()`). |
| 63-65 | Query e | `client.query` | Screen count for the hall. |
| 68-83 | Query f | `client.query` | 7-day revenue trend via `generate_series` with LEFT JOIN on shows/bookings. |
| 86-107 | Query g | `client.query` | 5 most recent bookings with movie, customer, and computed seat labels. |
| 110-133 | Query h | `client.query` | Today's shows with total seat count and booked seat count per show. |
| 139-163 | Response | `res.status(200).json(...)` | Assembles `{ today, allTime, customers, activeOffers, screens, revenueTrend, recentBookings, todayShows }`. |

### cinema-hall-api/controllers/booking.Controller.js

| Line | Symbol | Kind | Description |
|------|--------|------|-------------|
| 328 | `getCinemaHallBookings` | `async (req, res)` | Main handler for `GET /api/booking/admin/all`. |
| 331 | Param parsing | `const { from_date, to_date, search, status, screen_id, page, limit }` | Destructures query params with defaults. |
| 336-363 | Data query | `db.query(...)` | Paginated booking list with filters. Uses parameterized NULL-coalescing for optional filters. |
| 365-377 | Count query | `db.query(...)` | Same filters as data query, returns `COUNT(*)`. |
| 379-394 | Stats query | `db.query(...)` | Same filters, returns `SUM(total_amount)`, `SUM(convenience_fee)`, `SUM(gst_amount)`. |
| 397-406 | Response | `res.status(200).json(...)` | Returns `{ bookings, total, page, stats }`. |

### cinema-hall-api/controllers/refund.Controller.js

| Line | Symbol | Kind | Description |
|------|--------|------|-------------|
| 9 | `getRefunds` | `async (req, res)` | GET /api/refunds — builds dynamic WHERE clause with parameterized filters. |
| 10-14 | Param parsing | `const { status, from_date, to_date, page, limit }` | Defaults: page=1, limit=10, capped at 100. |
| 16-34 | WHERE builder | imperative | Constructs `conditions[]` array and `params[]` array incrementally. |
| 38-83 | Parallel queries | `Promise.all([db.query(...), db.query(...)])` | Data query with LIMIT/OFFSET + count query with same WHERE. |
| 85-92 | Response | `res.status(200).json(...)` | Returns `{ refunds, total }`. |
| 99 | `getRefundByBooking` | `async (req, res)` | GET /api/refunds/booking/:booking_id — single refund lookup. |
| 130 | `manuallySettleRefund` | `async (req, res)` | POST /api/refunds/:refund_id/settle — updates refund_status to 'settled'. |

### cinema-hall-api/routes/ (route definitions)

| File | Routes |
|------|--------|
| `dashboard.routes.js` | `GET /stats` → `getDashboardStats` |
| `booking.routes.js` | `GET /admin/all` → `getCinemaHallBookings`, `GET /admin/verify/:booking_id` → `verifyBookingById` |
| `refund.routes.js` | `GET /` → `getRefunds`, `GET /booking/:booking_id` → `getRefundByBooking`, `POST /:refund_id/settle` → `manuallySettleRefund` |

All routes are mounted under their resource prefix (e.g. `/api/dashboard`, `/api/booking`, `/api/refunds`) in the main Express app.

## Frontend

### cinema-hall-admin/src/components/ExportButton.jsx

| Line | Symbol | Kind | Description |
|------|--------|------|-------------|
| 1-9 | Imports | `import` | `lucide-react` icons, shadcn/ui button/dropdown, `exportUtils`. |
| 18 | `ExportButton` | `function` (named export) | Accepts `{ data, filename, disabled }` props. |
| 19 | `isEmpty` | `const` | `!data || data.length === 0`. |
| 22-44 | JSX | render | `DropdownMenu > DropdownMenuTrigger(Button) > DropdownMenuContent > 2x DropdownMenuItem`. |
| 35 | CSV click | `onClick` | Calls `exportToCSV(data, filename)`. |
| 39 | Excel click | `onClick` | Calls `exportToExcel(data, filename)`. |

### cinema-hall-admin/src/utils/exportUtils.js

| Line | Symbol | Kind | Description |
|------|--------|------|-------------|
| 1 | `import * as XLSX` | `import` | `xlsx` npm package for XLSX generation. |
| 8 | `exportToCSV` | `function` (named export) | Converts data array to CSV and triggers browser download. |
| 11 | `headers` | `const` | `Object.keys(data[0])`. |
| 12-22 | CSV builder | imperative | Maps each row to a CSV line with proper escaping. |
| 24-33 | Download trigger | imperative | Blob → objectURL → hidden `<a>` click → cleanup. |
| 41 | `exportToExcel` | `function` (named export) | Converts data array to XLSX and triggers browser download. |
| 44 | `json_to_sheet` | `XLSX.utils` | Creates worksheet from JSON array. |
| 45-46 | Workbook build | `XLSX.utils` | Creates book and appends sheet. |
| 47 | Write & download | `XLSX.writeFile` | Triggers download of `.xlsx` file. |
