# Hall Management - File Reference

## Admin App (`cinema-hall-admin`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/HallManagement.jsx` | Main hall CRUD page with table, create/edit sheet, map picker, delete confirmation | hallsAPI, useHall, shadcn/ui (Table, Sheet, AlertDialog, DropdownMenu, Select, Switch, Button, Card, Badge, Skeleton, Input, Textarea, ScrollArea, Label), lucide-react, country-state-city, react-leaflet, leaflet, sonner | `HallsManagement` (default) |
| `src/components/HallSwitcher.jsx` | Navbar dropdown to switch active hall | useHall, shadcn/ui (DropdownMenu, Skeleton, Badge), lucide-react, react-router-dom | `HallSwitcher` |
| `src/routes/HallGuard.jsx` | Route guard requiring at least one hall | useHall, useAuth, react-router-dom (Navigate, useLocation) | `HallGuard` |
| `src/context/HallContext.jsx` | Global hall state provider | hallsAPI, AuthContext, createContext | `HallProvider`, `useHall` |
| `src/services/api.js` | API client (hallsAPI) | fetch | `hallsAPI` |

## Backend API (`cinema-hall-api`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `routes/halls.routes.js` | Hall CRUD route definitions | halls.Controller, verifyCinemaAdminAccessToken | `router` (default) |
| `controllers/halls.Controller.js` | Hall CRUD logic (getMyHalls, createHall, updateHall, deleteHall) | db, logger | 4 controller functions |

## Database

| Object | Type | Schema | Description |
|--------|------|-------|-------------|
| `cinema_hall` | Table | public | Core hall entity with location, contact, and status fields |
| `hall_assignments` | Table | public | Links organization_members to specific halls for staff access |
| `cinema_hall.id` | PK | UUID | Primary identifier |
| `cinema_hall.admin_id` | FK | → cinema_admin_user(id) | Hall creator |
| `cinema_hall.org_id` | FK | → organizations(id) | Owning organization |
| `hall_assignments.hall_id` | FK | → cinema_hall(id) | Assigned hall |
| `hall_assignments.org_member_id` | FK | → organization_members(id) | Assigned member |
