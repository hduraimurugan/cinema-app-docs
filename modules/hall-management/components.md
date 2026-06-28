# Hall Management - Components

## Admin App Component Hierarchy

```
HallProvider (context wrapper)
 └── HallGuard (route guard)
     └── HallManagement (page)
          ├── Hall header (Building2 icon, title, hall count badge, "Add Hall" button)
          ├── Hall table (shadcn Table)
          │    ├── Hall row → name + description, location, district/state, phone,
          │    │               status badge (active/inactive toggle), selected badge,
          │    │               actions dropdown (Edit, Delete)
          │    └── Empty state → Building2 icon, "No halls yet" message, CTA button
          ├── Sheet (create/edit)
          │    ├── Hall Name input
          │    ├── Phone input
          │    ├── Location / Address input
          │    ├── State dropdown (from country-state-city)
          │    ├── District dropdown (derived from selected state)
          │    ├── Description textarea
          │    ├── Active toggle switch (edit only)
          │    ├── Map Picker
          │    │    ├── Map search bar (Nominatim geocoding)
          │    │    └── Leaflet MapContainer
          │    │         ├── TileLayer (OpenStreetMap)
          │    │         ├── MapClickHandler (set lat/lng on click)
          │    │         └── DraggableMarker (drag to adjust lat/lng)
          │    └── Footer (Cancel + Save/Create buttons)
          └── AlertDialog (delete confirmation)
               └── Warning about cascaded deletion of screens/shows/bookings

HallSwitcher (navbar component)
 └── Loading state → Skeleton
 └── Zero halls → "Add your first hall" link to /onboarding
 └── DropdownMenu
      ├── Active hall display → icon, name, location, chevron
      ├── Hall list items → icon, name, location, checkmark (active)
      └── "Manage halls" → navigates to /halls
```

## Component Catalog

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `HallManagement` | `pages/HallManagement.jsx` | - | form, sheetOpen, deleteTarget, editTarget, saving, deleting, mapCenter, markerPos, mapSearch, cities[], allStates | Routes/Layout | shadcn Table, Sheet, AlertDialog, MapContainer |
| `HallSwitcher` | `components/HallSwitcher.jsx` | - | (reads from useHall) | Navbar/Layout | shadcn DropdownMenu, Skeleton |
| `HallGuard` | `routes/HallGuard.jsx` | children | (reads from useHall, useAuth) | Route wrapper | Navigate, spinner div |
| `MapClickHandler` | `pages/HallManagement.jsx` | onLocationPick | - | MapContainer | (internal — useMapEvents) |
| `DraggableMarker` | `pages/HallManagement.jsx` | position, onDrag | - | MapContainer | Marker |
| `FormField` | `pages/HallManagement.jsx` | label, required, children | - | Sheet content | Label + children |
