# Components — Screen Management

## Frontend Components

### `CinemaScreens` (Page)

**Path:** `src/pages/CinemaScreens.jsx`

The admin screen list page. Serves as the CRUD hub for all screens in the active hall.

**Internal state machine:**
- `list` mode — showing the screen table
- `creating` mode — showing the create form
- `editing` mode — showing the edit form (with a specific screen)

**Sub-components (inline or imported):**

| Sub-component       | Purpose                                           |
| ------------------- | ------------------------------------------------- |
| `ScreenTable`       | Renders the list of screens in a table            |
| `ScreenRow`         | Single row with name, seat counts, prices, actions |
| `CreateScreenForm`  | Form to input all screen fields + layout           |
| `EditScreenForm`    | Pre-filled form for updating an existing screen    |
| `ScreenActions`     | Edit, Delete, Designer action buttons per row      |

**Data flow:**
1. On mount → `getMyScreens()` → populates `screens` state
2. Create/update success → refetch → switch back to list mode
3. Delete success → refetch
4. "Designer" → navigate to `/admin/screens/designer/:screenId`

---

### `ScreenDesignerPage` (Page)

**Path:** `src/pages/ScreenDesignerPage.jsx`

A visual seat layout designer with drag-and-drop capabilities.

**Internal state:**

| State          | Type     | Description                            |
| -------------- | -------- | -------------------------------------- |
| `layout`       | Object   | Current seat layout (`{ seats: [] }`)  |
| `selectedSeat` | Object   | Currently selected seat or null        |
| `seatCounts`   | Object   | Computed `{ premium, gold, silver }`   |
| `gridSize`     | Object   | `{ rows, columns }` for the canvas     |

**Sub-components:**

| Sub-component         | Purpose                                    |
| --------------------- | ------------------------------------------ |
| `Canvas`              | The main grid where seats are rendered     |
| `SeatCell`            | Individual seat or passage on the grid     |
| `PropertiesPanel`     | Edit properties of the selected seat       |
| `Toolbar`             | Tools: add seat, add passage, block/delete |
| `SaveBar`             | Save/Cancel actions at the bottom          |
| `CategoryLegend`      | Color legend for premium/gold/silver using the seat tier tokens (`bg-seat-premium`, `bg-seat-gold`, `bg-seat-silver`) |

**Interactions:**
- **Click seat** → select it, show properties panel
- **Click empty cell** → add seat (if in "add" mode) or passage (if in "passage" mode)
- **Drag seat** → reposition (row/column swap)
- **Properties panel** → change row letter, column number, type, price category, blocked state
- **Toolbar** → switch between add/passage/select/delete modes
- **Save** → navigates back to `CinemaScreens` with updated layout

---

## Backend "Components"

The controller (`screens.Controller.js`) acts as a single service component:

```
ScreenController
  ├── createScreen()
  ├── editScreen()
  ├── deleteScreen()
  └── getMyScreens()
```

Each function is self-contained and stateless. Shared concerns:
- **Hall ownership** — verified via `req.currentHallId` (middleware-injected)
- **JSON serialization** — layout is `JSON.stringify()`-ed before DB write
- **Dynamic queries** — `editScreen` builds SET clause from provided fields

## Middleware Components

| Middleware                  | Role                                      |
| -------------------------- | ----------------------------------------- |
| `verifyCinemaAdminAccessToken` | JWT verification, sets `req.admin`       |
| `requireActiveHall`        | Validates active hall, sets `req.currentHallId` |
