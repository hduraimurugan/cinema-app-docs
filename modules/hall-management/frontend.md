# Hall Management - Frontend

## Admin App (`cinema-hall-admin`)

### Pages

#### `HallManagement.jsx`
- **Path**: `src/pages/HallManagement.jsx`
- **Purpose**: Main hall management page with table listing, create/edit side sheet, and delete confirmation
- **State**: `form` (name, location, district, state, phone, description, lat/lng, is_active), `sheetOpen`, `deleteTarget`, `editTarget`, `saving`, `deleting`, `mapCenter`, `markerPos`, `mapSearch`, `cities[]` (derived from selected state)
- **API Usage**: `hallsAPI.getMyHalls()`, `hallsAPI.createHall()`, `hallsAPI.updateHall()`, `hallsAPI.deleteHall()`
- **Context Usage**: `useHall()` — reads `halls`, `activeHall`, `setActiveHall`, `refetchHalls`, `hallsLoading`
- **Data Flow**: On mount, reads halls from HallContext. Create/Edit/Delete all call `refetchHalls()` on success to synchronize global state. Creating a hall automatically sets it as the active hall. Uses `country-state-city` for state/district dropdowns and Leaflet for the map picker.
- **Key Functions**:
  - `handleSave` — Validates required fields (name, location, district, state), creates or updates hall
  - `handleDelete` — Deletes hall with cascading warning about screens/shows/bookings
  - `handleToggleActive` — Quick active/inactive toggle from the table row
  - `openCreate` / `openEdit` — Prepares form state for create vs edit modes
  - `handleLocationPick` — Sets lat/lng from map click or marker drag
  - `handleMapSearch` — Geocodes address via Nominatim OpenStreetMap API

### Components

#### `HallSwitcher.jsx`
- **Path**: `src/components/HallSwitcher.jsx`
- **Purpose**: Dropdown in the navbar to switch the active hall
- **State**: Reads `halls`, `activeHall`, `setActiveHall`, `hallsLoading` from `useHall()`
- **Data Flow**: Loading state shows skeleton. Zero halls shows "Add your first hall" button linking to `/onboarding`. Selection updates `activeHall` in HallContext (persists to `localStorage`) and re-renders current route to refresh scoped data.
- **Key Functions**:
  - `handleSelect(hall)` — Sets active hall, navigates to current path with `hallSwitched` state to trigger data refresh

#### `HallGuard.jsx`
- **Path**: `src/routes/HallGuard.jsx`
- **Purpose**: Route-level guard ensuring admin has at least one hall
- **Exempt Paths**: `/halls`, `/profile`, `/settings`, `/unauthorized`
- **Data Flow**: Staff role bypasses the guard. Exempt paths always pass through. While halls are loading, shows a spinner. No halls → redirects to `/onboarding`.
- **Props**: `children` — wrapped route content

### Context

#### `HallContext.jsx`
- **Path**: `src/context/HallContext.jsx`
- **Properties**:
  - `halls[]` — Array of hall objects
  - `activeHall` — Currently selected hall object
  - `hallsLoading` — Boolean loading state
  - `hallKey` — Incrementing counter to trigger re-fetches on switch
  - `refetchHalls` — Re-fetches hall list (used after create/update/delete)
- **Methods**: `setActiveHall(hall)` — Sets active hall and persists `activeHallId` to `localStorage`
- **Data Flow**: Waits for AuthContext to finish session check before fetching halls (prevents race between JWT verification and hall fetch). On user login, loads halls via `hallsAPI.getMyHalls()`. Restores previously active hall from `localStorage` if available; otherwise selects the first hall. `refetchHalls` handles the edge case where the active hall was deleted — falls back to the first available hall.

### Services

#### `api.js` (hallsAPI section)
- **Path**: `src/services/api.js`

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `getMyHalls()` | GET `/api/halls` | List all halls for admin |
| `createHall(data)` | POST `/api/halls` | Create new hall |
| `updateHall(id, data)` | PUT `/api/halls/:id` | Update hall fields |
| `deleteHall(id)` | DELETE `/api/halls/:id` | Delete hall (cascading) |
