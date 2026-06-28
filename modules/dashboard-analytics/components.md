# Components — Dashboard & Analytics

## Architecture

The dashboard is a single-page component (`HomePage.jsx`) that renders all sub-sections directly. No nested component tree — each section is a JSX block within the same file.

```
HomePage.jsx
├── Page Header ("Dashboard")
├── Stat Cards Grid
│   ├── Today's Bookings
│   ├── Today's Revenue
│   ├── Customers (total)
│   ├── Active Offers
│   ├── Screens
│   └── All-Time Bookings
├── Revenue Trend Chart (Recharts AreaChart)
├── Recent Bookings Table
└── Today's Shows Table (with occupancy)
```

## Component Breakdown

### HomePage (root component)

| Aspect | Detail |
|--------|--------|
| State | `stats` object (initialized with defaults), `loading` boolean |
| Data Fetch | `useEffect([], async () => { const res = await getStats(); setStats(res.data); })` |
| Loading State | Check `loading` flag; renders nothing or spinner while true |
| Error State | `try/catch` catches errors; stats remain at defaults |

### Stat Cards

Rendered as a CSS grid (3 columns, 2 rows).

| Card | Icon | Value Source | Formatting |
|------|------|-------------|------------|
| Today's Bookings | ticket icon | `stats.today.bookings` | Integer |
| Today's Revenue | currency icon | `stats.today.revenue` | Currency (₹ symbol, 2 decimals) |
| Customers | people icon | `stats.customers` | Integer |
| Active Offers | tag icon | `stats.activeOffers` | Integer |
| Screens | monitor icon | `stats.screens` | Integer |
| All-Time Bookings | calendar icon | `stats.allTime.bookings` | Integer |

### Revenue Trend Chart

| Aspect | Detail |
|--------|--------|
| Library | Recharts |
| Chart Type | `AreaChart` |
| Data | `stats.revenueTrend[]` |
| X-Axis | Date (formatted short) |
| Y-Axis | Revenue |
| Area Fill | Gradient or solid brand color |
| Tooltip | Hover shows exact date + revenue |
| Responsive | Wrapped in `<ResponsiveContainer width="100%" height={300}>` |

### Recent Bookings Table

| Column | Data Field |
|--------|-----------|
| ID | `id` |
| Movie | `movie_title` |
| Customer | `customer_name` |
| Seats | `seat_labels` |
| Amount | `total_amount` |
| Status | `booking_status` |
| Date | `created_at` (formatted) |

Max 5 rows (server-limited).

### Today's Shows Table

| Column | Data Field |
|--------|-----------|
| Time | `start_time` |
| Movie | `movie_title` |
| Screen | `screen_name` |
| Status | `status` |
| Seats | `booked_seats` / `total_seats` |
| Occupancy | Percentage bar (`booked_seats / total_seats * 100`) |

Occupancy is computed client-side.

## Props

No child components receive props — all rendering happens inline in `HomePage.jsx`. If this file is ever refactored into smaller components, the following props would apply:

| Component | Props |
|-----------|-------|
| `<StatCard icon title value />` | `icon: string`, `title: string`, `value: string\|number` |
| `<RevenueChart data />` | `data: Array<{date, revenue}>` |
| `<RecentBookingsTable bookings />` | `bookings: Array<{id, movie_title, ...}>` |
| `<TodayShowsTable shows />` | `shows: Array<{id, start_time, ...}>` |

## Styling

- CSS modules or inline classes (project-specific CSS conventions)
- Stat cards use a card-like container with shadow/border
- Tables use standard table styling
- Chart uses Recharts default theming with project brand colors
