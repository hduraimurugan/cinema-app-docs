# Frontend — Screen Management

## Pages

### CinemaScreens (`src/pages/CinemaScreens.jsx`)

The main list page for managing all screens in the currently active cinema hall.

**Features:**
- Lists all screens for the active hall, ordered by creation date descending
- Displays screen name, total seats, premium/gold/silver seat counts and prices
- "Add Screen" button opens a create form (inline or modal)
- Each row has Edit and Delete actions
- "Designer" button navigates to the visual layout designer

**State:**
- `screens[]` — fetched from `getMyScreens()` on mount
- `loading` / `error` — standard async UI states
- `editingScreen` — the screen object currently being edited (or `null`)
- `showCreateForm` — toggles the create form

**Key behaviors:**
- Uses `hallFetch` from `services/api.js` which adds the `X-Hall-Id` header automatically
- Refetches screen list after every CUD operation
- Confirms before delete

### ScreenDesignerPage (`src/pages/ScreenDesignerPage.jsx`)

A drag-and-drop visual seat layout editor.

**Features:**
- Grid-based canvas where seats can be placed, moved, and resized
- Each seat is color-coded by price category (premium / gold / silver)
- Aisles/passages can be marked between seat blocks
- Individual seats can be blocked (reserved for structural reasons)
- Properties panel for selected seat: row letter, column number, type, price category, blocked state
- Generates the `layout` JSON object submitted with screen create/update

**State:**
- `layout` — the JSONB seat map being edited
- `selectedSeat` — currently selected seat object (or `null`)
- `seatCounts` — computed premium/gold/silver counts (syncs with form fields)

**Key behaviors:**
- Row letters auto-increment (A, B, C, ...)
- Column numbers auto-increment (1, 2, 3, ...)
- Changing price category in the designer updates the corresponding seat count totals
- Layout is validated before save (at least one seat, no overlapping seats)

## API Service Layer

In `services/api.js`, the screen endpoints are wrapped as:

```javascript
// All use hallFetch() which injects X-Hall-Id from activeHall context
export const screensAPI = {
  createScreen: (data) => hallFetch.post("/screens/create", data),
  getMyScreens: () => hallFetch.get("/screens"),
  updateScreen: (screenId, data) =>
    hallFetch.put(`/screens/update/${screenId}`, data),
  deleteScreen: (screenId) =>
    hallFetch.delete(`/screens/delete/${screenId}`),
};
```

## Component Tree

```
App
└── CinemaScreens (route: /admin/screens)
    ├── ScreenList (table)
    │   ├── ScreenRow (per-screen)
    │   └── ActionButtons (Edit, Delete, Designer)
    ├── CreateScreenForm
    └── EditScreenForm

App
└── ScreenDesignerPage (route: /admin/screens/designer/:screenId?)
    ├── Canvas (grid of SeatCell components)
    ├── PropertiesPanel
    ├── Toolbar (add seat, add passage, block, delete)
    └── SaveBar
```
