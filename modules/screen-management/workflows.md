# Workflows — Screen Management

## Workflow 1: Create a Screen

```
Admin clicks "Add Screen"
        │
        ▼
Opens CreateScreenForm
  - Enters: name, seat counts, prices, rows, columns
  - Optionally opens ScreenDesignerPage to build seat layout
        │
        ▼
Form submitted
        │
        ▼
Frontend: screensAPI.createScreen(data)
  → hallFetch.post("/screens/create", data)
  → X-Hall-Id header injected automatically
        │
        ▼
Backend: verifyCinemaAdminAccessToken → requireActiveHall → createScreen
  - req.body validated
  - INSERT INTO screens (...) VALUES (...)
  - Returns created screen
        │
        ▼
Frontend: receives response, refetch list
  - New screen appears in table
```

---

## Workflow 2: Edit a Screen

```
Admin clicks "Edit" on a screen row
        │
        ▼
Opens EditScreenForm pre-filled with current data
  - Admin modifies fields
  - Layout can be redesigned via ScreenDesignerPage
        │
        ▼
Form submitted
        │
        ▼
Frontend: screensAPI.updateScreen(screenId, data)
  → hallFetch.put("/screens/update/${screenId}", data)
        │
        ▼
Backend: verifyCinemaAdminAccessToken → requireActiveHall → editScreen
  - Verifies screen.cinema_hall_id === req.currentHallId
  - Builds dynamic UPDATE with only provided fields
  - Serializes layout to JSON if provided
  - Updates row
        │
        ▼
Frontend: refetch list, updated values shown
```

---

## Workflow 3: Delete a Screen

```
Admin clicks "Delete" on a screen row
        │
        ▼
Confirmation dialog: "Are you sure?"
        │
[Cancel]       [Confirm]
  │               │
stop              ▼
          Frontend: screensAPI.deleteScreen(screenId)
            → hallFetch.delete("/screens/delete/${screenId}")
                    │
                    ▼
          Backend: verifyCinemaAdminAccessToken → requireActiveHall → deleteScreen
            - Verifies ownership
            - DELETE FROM screens WHERE id=$1 AND cinema_hall_id=$2
                    │
                    ▼
          Frontend: refetch list, screen removed
```

---

## Workflow 4: Design Seat Layout (Visual Designer)

```
Admin clicks "Designer" on a screen (or during create)
        │
        ▼
ScreenDesignerPage loads
  - If existing screen: layout loaded from screen data
  - If new: empty grid of specified rows x columns
        │
        ▼
Admin uses toolbar to:
  1. Add seats → click cells to place seats
  2. Mark passages → click cells to create aisles
  3. Select seats → change properties (price category, row, column)
  4. Block seats → mark structurally unavailable seats
        │
        ▼
Admin clicks "Save"
        │
        ▼
Layout JSON generated, synced to form
  - Premium/gold/silver counts computed from layout
  - Validation: at least one seat, no overlaps
        │
        ▼
Navigates back to create/edit form with layout data
```

---

## Workflow 5: Cross-Hall Security (Error Path)

```
Admin with Hall A active tries to modify Screen belonging to Hall B
        │
        ▼
GET /api/screens/update/:screenId-of-Hall-B
        │
        ▼
requireActiveHall sets req.currentHallId = Hall-A
        │
        ▼
editScreen queries screen by screenId
  - Finds screen with cinema_hall_id = Hall-B
  - Compares: Hall-B !== Hall-A
        │
        ▼
Response 403 Forbidden
  { error: "You do not have permission to modify this screen." }
```

---

## Ownership Validation Summary

All CUD operations follow the same security pattern:

```
1. req.currentHallId injected by requireActiveHall middleware
2. Controller fetches target screen from DB
3. Compares screen.cinema_hall_id with req.currentHallId
4. If mismatch → 403 Forbidden
5. If match → proceed with operation
```

This prevents screen leakage between halls even if an admin has valid JWT tokens for multiple halls.
