# Components — Show Management

## Shared Components

### `MovieSearchDropdown`
Search-as-you-type dropdown for selecting a movie.

**Used in:**
- `AddShowPage`
- `AddMultipleShowsPage`
- `EditShowPage`

**Props:**
- `value` — Currently selected movie object `{ id, title, poster_url }`
- `onChange` — Callback when a movie is selected
- `placeholder` — Placeholder text (default: "Search movies...")

**Behavior:**
- Fetches movies from the API as user types
- Debounced search input
- Displays movie poster thumbnail + title in dropdown
- Clears selection when input is cleared

---

## Page-Specific UI Patterns

### Status Badges
Color-coded status indicators used across `ShowsManagement` and `ShowPage`.

| Status | Color | Hex |
|--------|-------|-----|
| `scheduled` | Gray | `#6b7280` |
| `booking_started` | Green | `#10b981` |
| `in_progress` | Blue | `#3b82f6` |
| `show_ended` | Dark | `#1f2937` |
| `cancelled` | Red | `#ef4444` |

### Seat Map (ShowPage)
Interactive seat layout rendered from screen layout JSON.

**Seat Color Coding:**
- `available` — Light green / clickable
- `in_booking` — Yellow (locked by another user, expires)
- `booked` — Red (sold)
- `blocked` — Gray striped (HELD / administrative block)

### Bulk Action Toolbar
Appears in `ShowsManagement` when shows are selected.

**Actions:**
- **Cancel Selected** — Confirmation dialog → bulk cancel
- **Open Booking Selected** — One-click `scheduled → booking_started`
- **Restore Selected** — One-click `cancelled → scheduled`
- **Delete Selected** — Confirmation dialog → hard delete

### Preview Table (AddMultipleShowsPage)
Data grid showing all combinations before submission.

**Columns:** Screen, Date, Start Time, End Time
**Purpose:** Allows admin to verify the cross-product before committing; shows total show count.
