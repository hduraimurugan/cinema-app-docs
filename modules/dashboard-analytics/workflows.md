# Workflows — Dashboard & Analytics

## 1. Page Load (Default Flow)

```
User logs in
  → Redirected to "/" (HomePage)
  → useEffect triggers getStats()
  → GET /api/dashboard/stats
  → 8 parallel queries execute
  → Response returned
  → State updated
  → Stat cards, chart, and tables render
```

**Trigger:** Page mount (manual navigation or login redirect).

**Frequency:** Once per page load. No auto-refresh, no polling.

## 2. View Today's Performance

```
User lands on dashboard
  → Scans 6 stat cards at top
    - Today's Bookings (count)
    - Today's Revenue (in ₹)
    - Total Customers (global)
    - Active Offers
    - Screens count
    - All-Time Bookings
  → Gets immediate summary of business health
```

**Purpose:** Quick pulse check on current day's performance.

## 3. Analyze Revenue Trend

```
User sees Revenue Trend chart
  → 7-day area chart shows daily revenue
  → Hover over a data point → tooltip shows exact date + amount
  → Identifies high/low days at a glance
  → No drill-down or date range selection available
```

**Limitations:** Fixed 7-day window. No date range picker, no comparison with previous periods.

## 4. Review Recent Bookings

```
User scrolls to Recent Bookings table
  → Sees last 5 bookings with movie, customer, seats, amount, status
  → Clicks or taps a booking row → navigates to booking details page
  → Verifies recent transactions without leaving dashboard
```

**Purpose:** Spot-check recent activity to confirm bookings are processing correctly.

## 5. Monitor Today's Shows & Occupancy

```
User views Today's Shows table
  → Sees show schedule sorted by start time
  → For each show: movie, screen, status, booked/total seats, occupancy %
  → Low-occupancy shows are visible at a glance
  → Can take actions: promote low-fill shows, check status issues
```

**Actionability:** If a show has 0 booked seats and starts in 30 minutes, admin can investigate or promote.

## 6. Cross-Navigation

```
Dashboard (/) → View Recent Booking → Navigate to Booking Detail (/bookings/:id)
Dashboard (/) → View Today's Show → Navigate to Show Detail (/shows/:id)
Dashboard (/) → Click Active Offers count → Navigate to Offers (/offers)
Dashboard (/) → Click Screens count → Navigate to Screens (/screens)
```

Navigation links are embedded in stat cards and table rows.

## 7. Data Freshness & Refetch

| Workflow | Refresh Behavior |
|----------|-----------------|
| Initial page load | Full fetch |
| Browser refresh (F5) | Full fetch (new request) |
| Navigation away + back | Full fetch (component remounts) |
| Auto-refresh | **Not implemented** |
| WebSocket push | **Not implemented** |
| Manual refresh button | **Not implemented** |

**Recommendation:** Consider adding a periodic refresh (30s interval) or a manual "Refresh" button for live environments.

## 8. Error Recovery

```
Dashboard load fails (500 error)
  → stats remain at default values (0s, empty arrays)
  → UI renders with empty/zero state
  → No error toast or visual indicator shown
  → User must refresh the page to retry
```

**Recommendation:** Add an inline error banner with a "Retry" button for better UX.
