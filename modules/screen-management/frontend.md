# Frontend — Screen Management

## Pages

### CinemaScreens (`src/pages/CinemaScreens.jsx`)

The main list page for managing all screens in the currently active cinema hall.

**Features:**
- Lists all screens for the active hall, ordered by creation date descending
- Displays screen name, total seats, premium/gold/silver seat counts and prices
- Seat-stat cards use the seat tier theme tokens (`a63f978`): premium (violet `--seat-premium`), gold (amber `--seat-gold`), silver (cool gray `--seat-silver`) — each with a tinted `bg-seat-*/10` panel, `border-seat-*/30` border, and `text-seat-*` count/price
- "Add Screen" button opens a create form (inline or modal)
- Each row has Edit and Delete actions
- "Designer" button navigates to the visual layout designer
- Screen "View" dialog (`24047bb`) renders the seat map inside an auditorium `<Card>` — the screen indicator and the seating grid share one solid, guaranteed-opaque surface (`p-6 sm:p-8 gap-0`); the grid scrolls independently (`overflow-x-auto`, `min-w-max mx-auto`) so the screen indicator and legend never get pushed off-center. Dialog is sized `w-[95vw] sm:max-w-[1600px] max-h-[90vh] overflow-y-auto` with a thin scrollbar. Seats are 3D-styled (rounded top corners, thicker bottom border) with the seat tier tokens; screen position top/bottom is honored with a primary-colored glow cone; row labels use `text-foreground` and column numbers `text-muted-foreground`, with aisle spacers between blocks

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
- Each seat is color-coded by price category via seat tier tokens (`a63f978`): premium `bg-seat-premium/90`, gold `bg-seat-gold/90`, silver `bg-seat-silver/90`, with matching `border`/`text` foregrounds; blocked seats use `bg-destructive`/`border-destructive`; selected seats use `border-primary` + `ring-primary/30` + `bg-primary/15`
- Aisles/passages can be marked between seat blocks (rendered with `primary`-based colors)
- Individual seats can be blocked (reserved for structural reasons)
- Properties panel for selected seat: row letter, column number, type, price category, blocked state
- Generates the `layout` JSON object submitted with screen create/update
- Screen preview (live and print) shows a curved screen panel with a primary-colored glow; the tools palette and seat summary counts are token-colored (`text-seat-premium`, `text-seat-gold`, `text-seat-silver`, `text-destructive`, `text-primary`)
- Pan tool (`24047bb`): a `Hand` toolbar button (and an `H` keyboard shortcut, guarded against inputs) toggles `isPanMode`. Dragging the canvas then pans the scroll container via pointer events (`handlePanPointerDown/Move/Up` with pointer capture, adjusting `gridContainerRef.scrollLeft/scrollTop`), showing `cursor-grab active:cursor-grabbing select-none`. While active, seat/row/column clicks are suppressed and the keyboard-shortcuts legend lists `Pan tool → H`. Canvas centering was refined in `8f97915`: the container drops `flex justify-center` and the scaled canvas becomes `block w-max mx-auto` so the whole grid stays centered and pans without edge clipping

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
