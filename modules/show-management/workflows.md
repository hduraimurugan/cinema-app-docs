# Workflows — Show Management

## 1. Create Single Show

```
Admin → ShowsManagement → "Add Show" button → AddShowPage
```

1. Select a movie using `MovieSearchDropdown`
2. Pick a screen from the dropdown
3. Choose a date
4. Set start time and end time
5. Enter language version (defaults to "Original")
6. Optionally enter a price override
7. Click "Create Show"
8. On success, redirect to `ShowsManagement` with the new date selected

## 2. Bulk Create Shows

```
Admin → ShowsManagement → "Add Multiple Shows" button → AddMultipleShowsPage
```

1. Select a movie using `MovieSearchDropdown`
2. Check one or more screens
3. Pick a date range (start date → end date)
4. Add one or more time slot rows (start_time + end_time per slot)
5. Preview the generated cross-product in a table
6. Click "Create All"
7. Results show counts of `created` vs `skipped` (duplicates)

**Generation Logic:**
```
For each screen in selected_screens:
  For each date in date_range:
    For each time_slot in slots:
      Create show(screen, date, time_slot)
```

## 3. Edit Show

```
Admin → ShowsManagement → Edit icon on show → EditShowPage
```

1. Form pre-populated with current show data
2. Modify any fields (movie, screen, date, time, language, price)
3. Click "Save"
4. If date moved to future, status auto-resets to `scheduled`
5. Redirect to `ShowsManagement`

## 4. Cancel Show with Refunds

```
Admin → ShowsManagement → Cancel icon on show → Confirm dialog
```

1. System checks `getShowBookingCount` — shows how many bookings will be affected
2. Confirmation dialog: "Cancel show X? This will cancel Y bookings and issue refunds."
3. On confirm:
   a. Show status set to `cancelled`
   b. All `booked` seats marked cancelled
   c. Refund records created (status: `initiated`)
   d. Razorpay refunds initiated (outside DB transaction)
4. Page refreshes to reflect cancellation

## 5. Bulk Cancel Shows

```
Admin → ShowsManagement → Select shows → "Cancel Selected" → Confirm dialog
```

1. Select multiple shows via checkboxes
2. Click "Cancel Selected"
3. For each show, individual cancel logic runs with per-show DB transaction
4. Razorpay refunds initiated for each

## 6. Open / Close / Restore Booking

**Open Booking:**
```
Show with status "scheduled" → "Open Booking" action
→ Status changes to "booking_started" → Seats become selectable by users
```

**Revert Booking:**
```
Show with status "booking_started" → "Close Booking" action
→ Status reverts to "scheduled" (only if NO confirmed bookings exist)
→ Prevents accidental data loss
```

**Restore Show:**
```
Show with status "cancelled" → "Restore" action
→ Status changes to "scheduled" → Show is available again
```

## 7. Automatic Status Transitions (Background Job)

Runs periodically via cron/background worker.

```
Current Time (IST) check:
│
├─ Show is booking_started AND start_time < now()
│  → status = in_progress
│
├─ Show is in_progress AND end_time < now()
│  → status = show_ended
│
└─ Handles midnight-crossing shows:
    If show started yesterday and end_time is after midnight IST,
    end_time comparison accounts for date boundary
```

## 8. Seat Booking Flow (User-Facing)

```
User → Show detail page (public) → Seat map → Select seat → Confirm
```

1. User opens `GET /api/shows/get/:id` (public)
2. Seat layout rendered with color-coded availability
3. User clicks an available seat
4. `POST /api/shows/book/:showId` creates `in_booking` record (10 min lock)
5. User completes payment flow → seat status changes to `booked`
6. If payment not completed within 10 minutes, lock expires → seat becomes `available` again
