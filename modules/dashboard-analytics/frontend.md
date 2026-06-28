# Frontend — Dashboard & Analytics

## Entry Point

**File:** `src/pages/HomePage.jsx`

This is the main dashboard page and the default landing page for cinema admin users. It is rendered at the `/` route inside the authenticated admin router.

## Data Fetching

All dashboard data is fetched in a **single API call** on component mount via `useEffect`.

```javascript
// services/api.js
export const getStats = () => api.get('/dashboard/stats');
```

The hook flow:

```
useEffect([]) → getStats() → response.data → local state → child props
```

No polling, no WebSocket — data is static after initial load. Manual refresh requires page reload.

## State Shape

```javascript
const [stats, setStats] = useState({
  today: { bookings: 0, revenue: 0, convenience_fee: 0, gst: 0 },
  allTime: { bookings: 0, revenue: 0 },
  customers: 0,
  activeOffers: 0,
  screens: 0,
  revenueTrend: [],          // Array<{ date, revenue, bookings_count }>
  recentBookings: [],        // Array<{ id, total_amount, booking_status, created_at, movie_title, customer_name, seat_labels }>
  todayShows: [],            // Array<{ id, start_time, status, movie_title, screen_name, total_seats, booked_seats }>
});
```

## Rendering Sections

| Section | UI Element | Data Source |
|---------|-----------|-------------|
| Stat Cards | 6 cards in a grid | `today.bookings`, `today.revenue`, `customers`, `activeOffers`, `screens`, `allTime.bookings` |
| Revenue Trend Chart | Recharts `AreaChart` | `revenueTrend[]` (7-day) |
| Recent Bookings | Table rows | `recentBookings[]` (latest 5) |
| Today's Shows | Table with occupancy | `todayShows[]` |

## Chart Details (Recharts)

- **Chart type:** `AreaChart` with `Area` for revenue
- **X-axis:** dates (formatted as short day names or MM/DD)
- **Y-axis:** revenue in currency units
- **Tooltip:** shows exact date and revenue value on hover
- **ResponsiveContainer** wraps the chart for viewport scaling

## State Management

No global state (Redux/Zustand). All dashboard data is managed via local `useState` in `HomePage.jsx`. This is acceptable because:

1. Dashboard data is page-scoped (only needed on `/`)
2. Data is fetched once and does not need cross-component sharing
3. No real-time updates or multi-source mutations

## Error Handling

- `try/catch` around `getStats()` call
- On error: console.error with message (no user-facing error toast currently shown)
- Default state values (zeros, empty arrays) prevent rendering issues even on failure
