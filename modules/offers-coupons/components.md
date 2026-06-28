# Components & UI

## Admin Components

### OffersManagement

```
Props: none (standalone page)

Internal state:
  offers[]        — fetched offer rows
  total            — total count for pagination
  page             — current page (1-indexed)
  loading          — loading indicator
  error            — error message string or null
  searchInput      — raw search input value
  search           — debounced search value
  scopeFilter      — "all" | "global" | "hall"
  statusFilter     — "all" | "active" | "inactive"
  deleteTarget     — offer object or null (for confirmation dialog)
  deleting         — deletion in progress
```

**UI components used:**
- `Card`, `CardContent`, `CardHeader`, `CardTitle` (shadcn/ui)
- `Input`, `Button`, `Select` (with items)
- `Table`, `TableBody`, `TableCell`, `TableHead`, `TableHeader`, `TableRow`
- `Skeleton` (loading state)
- `AlertDialog` (delete confirmation)
- `ExportButton` (custom CSV export)
- Icons: `Tag`, `Plus`, `Search`, `ChevronLeft`, `ChevronRight`, `SlidersHorizontal`, `X`, `Pencil`, `Trash2`, `RefreshCw`, `AlertCircle`, `BadgePercent`, `Ticket`

### OfferFormPage

```
Props: none (reads route params via useParams())

Internal state:
  form                      — object matching EMPTY_FORM shape
  halls[]                   — cinema halls for selector
  saving                    — submission in progress
  loadingOffer              — loading edit data
  validUntilPickerOpen      — date picker popover state
  joinedAfterPickerOpen     — date picker popover state
```

**UI components used:**
- `Card`, `CardContent`, `CardHeader`, `CardTitle`
- `Input`, `Button`, `Textarea`, `Label`, `Switch`
- `Select`, `SelectContent`, `SelectItem`, `SelectTrigger`, `SelectValue`
- `Popover`, `PopoverContent`, `PopoverTrigger`
- `Calendar` (date picker)
- `Skeleton` (loading state)
- Icons: `ArrowLeft`, `CalendarIcon`, `Tag`

## User Components

### OffersPage

```
Props: none (reads customer from context)

Internal state:
  offers[]       — fetched eligible offers
  loading        — loading indicator
  copiedCode     — currently copied offer code (for checkmark feedback)
```

**UI components used:**
- Icons: `Tag`, `Copy`, `Check`, `CalendarDays`, `IndianRupee`, `Users`, `Clock`
- Custom card layout (no shadcn Card — uses styled divs)

**Variants:**
- **Unredeemed card:** Gradient top bar (violet→purple), clickable code button, hover shadow
- **Redeemed card:** Muted top bar, 60% opacity, line-through code, "Already used" badge
- **Ending soon card:** Amber "Ending soon" badge when ≤3 days remain

## Shared UI Patterns

- **Badge styles** (scope, status, redeemed, ending-soon): rounded-full with `border` + `bg-*/15 text-*` using Tailwind opacity pattern
- **Loading:** `<div className="animate-pulse">` skeleton placeholders matching card/table layout
- **Empty state:** Centered icon + text message + optional action button
- **Error state:** Destructive icon + error message + retry button
