# Admin Panel Documentation

## Overview

The Cinema Hall Admin Panel is a **React-based web application** built for cinema administrators to manage their theaters. It provides comprehensive tools for movie management (SuperAdmin only), screen configuration with interactive seat layout design, show scheduling, and booking oversight.

**Tech Stack:**

- **Framework**: React 18 with Vite
- **Routing**: React Router v6
- **UI Library**: shadcn/ui (Radix UI primitives)
- **Styling**: Tailwind CSS
- **State Management**: React Context API
- **HTTP Client**: Fetch API
- **Image Upload**: Cloudinary
- **Authentication**: JWT with HttpOnly cookies
- **Charts**: recharts (BarChart for dashboard revenue trend)

---

## Application Architecture

### Route Structure

```mermaid
graph TD
    A[App.jsx] --> B{User Logged In?}
    B -->|No| C[/login]
    B -->|Yes| D[CinemaLayout]

    D --> E[Protected Routes]
    E --> F[/ - HomePage]
    E --> G[/movie/:id - MoviePage]
    E --> H[/screens - CinemaScreens list]
    E --> H2[/screens/new - ScreenDesignerPage add]
    E --> H3[/screens/:id/edit - ScreenDesignerPage edit]
    E --> I[/shows - ShowsManagement]
    E --> I2[/shows/new - AddShowPage]
    E --> I3[/shows/bulk - AddMultipleShowsPage]
    E --> I4[/shows/:id/edit - EditShowPage]
    E --> J[/show/:id - ShowPage]
    E --> K[/bookings - Bookings]
    E --> K2[/bookings/:id - BookingDetailPage]
    E --> K3[/verify-ticket - VerifyTicket]
    E --> L[/profile - ProfilePage]
    E --> M[/settings - SettingsPage]

    D --> N[SuperAdmin Routes]
    N --> O[/movies - MovieManagement]
    N --> O2[/ads - AdsManagement]
    N --> O3[/offers - OffersManagement]
    N --> O4[/offers/new - OfferFormPage create]
    N --> O5[/offers/:id/edit - OfferFormPage edit]
    N --> O6[/customers - UsersPage]
    N --> O7[/admins - AdminsPage]

    C --> P[/register - RegisterPage]
```

### Component Hierarchy

```mermaid
graph TD
    A[App] --> B[AuthContext Provider]
    B --> C[Router]
    C --> D[CinemaLayout]
    D --> E[AppSidebar]
    D --> F[Main Content Area]
    F --> G[Page Components]

    E --> H[Navigation Items]
    E --> I[User Profile]
    E --> J[Theme Toggle]

    G --> K[MovieManagement]
    G --> L[CinemaScreenDesigner - list]
    G --> L2[ScreenDesignerPage - add/edit]
    G --> M[ShowsManagement - list]
    G --> M2[AddShowPage - /shows/new]
    G --> M3[AddMultipleShowsPage - /shows/bulk]
    G --> M4[EditShowPage - /shows/:id/edit]
    G --> N[Other Pages]
```

---

## Authentication System

### Authentication Flow

```mermaid
sequenceDiagram
    participant User
    participant LoginPage
    participant AuthContext
    participant API
    participant LocalStorage

    User->>LoginPage: Enter credentials
    LoginPage->>API: POST /api/auth/login
    API-->>LoginPage: {admin, hall, tokens}
    LoginPage->>AuthContext: setAdmin(admin)
    AuthContext->>LocalStorage: Save admin data
    AuthContext-->>LoginPage: isLoggedIn = true
    LoginPage->>User: Redirect to /
```

### AuthContext State Management

**Location**: `src/context/AuthContext.jsx`

**State Variables:**

```javascript
{
  admin: {
    id: "uuid",
    name: "John Doe",
    email: "admin@cinema.com",
    role: "admin" | "superadmin",
    phone: "+1234567890"
  },
  hall: {
    id: "uuid",
    name: "Grand Cinema",
    location: "Downtown Plaza",
    district: "Mumbai",
    state: "Maharashtra"
  },
  isLoggedIn: boolean,
  loading: boolean
}
```

**Key Functions:**

- `login(email, password)` - Authenticate admin
- `logout()` - Clear session and redirect
- `checkAuth()` - Verify token on mount
- `refreshToken()` - Auto-refresh access token

### Protected Routes

**ProtectedRoute** - Requires authentication

```jsx
<ProtectedRoute>
  <CinemaLayout />
</ProtectedRoute>
```

**AdminProtectedRoute** - Requires SuperAdmin role

```jsx
<AdminProtectedRoute>
  <MovieManagement />
</AdminProtectedRoute>
```

---

## Features Documentation

### 0. Dashboard (All Admins)

**Route**: `/`
**Component**: `HomePage.jsx`
**Access**: All authenticated cinema admins
**API**: `dashboardAPI.getStats()` → `GET /api/dashboard/stats`

The dashboard loads all metrics in a single API call and renders four sections:

#### KPI Cards

| Card | Value | Sub-text |
|------|-------|----------|
| Today's Revenue | Sum of `total_amount` for today's shows | Count of today's bookings |
| Today's Bookings | Count of bookings for today's shows | All-time booking count |
| Total Customers | Count of all platform customers | Screen count |
| Active Offers | Count of non-expired active offers (hall + global) | All-time revenue |

#### Revenue Trend Chart

- `recharts` `BarChart` with `ResponsiveContainer` — fills full card width
- X-axis: 7 day labels (Mon–Sun) via `dayjs(date).format('ddd')`
- Y-axis: ₹ amounts (abbreviated to `₹2k`, `₹10k`, etc.)
- Custom `Tooltip`: shows `₹revenue` + `bookings_count` on hover
- Bar fill: `#10b981` (emerald) — CSS variables are not supported in SVG/recharts

#### Today's Shows

List of all shows scheduled for today, ordered by `start_time`. Each row shows movie title, start time, screen name, and seat occupancy (`booked/total`).

Occupancy color-coding:
- `< 50%` → emerald (green)
- `50–79%` → amber (yellow)
- `≥ 80%` → red

#### Recent Bookings

Last 5 bookings across the cinema hall, ordered by `created_at DESC`. Each row shows customer name, movie title, amount, and booking status badge (same color scheme as `Bookings.jsx`). Rows are clickable and navigate to `/bookings/:id`.

---

### 1. Offers Management (SuperAdmin Only)

**Routes**:
- `/offers` — `OffersManagement.jsx` (list, filters, delete)
- `/offers/new` — `OfferFormPage.jsx` (create form)
- `/offers/:id/edit` — `OfferFormPage.jsx` (edit form, fetches offer by ID)

**Access**: SuperAdmin role required
**API**: `offersAPI` in `src/services/api.js`

#### Feature Overview

```mermaid
flowchart TD
    A[/offers - OffersManagement] --> B[Filter Card]
    A --> C[Offers Table]

    B --> B1[Search by code / title]
    B --> B2[Scope filter: Global / Hall]
    B --> B3[Status filter: Active / Inactive]

    C --> D[Create Offer button → navigates to /offers/new]
    C --> E[Edit button → navigates to /offers/:id/edit]
    C --> F[Delete button → AlertDialog confirmation]

    D --> G[/offers/new - OfferFormPage]
    E --> H[/offers/:id/edit - OfferFormPage]

    G --> F1[Code - uppercase monospace]
    G --> F2[Title + Description]
    G --> F3[Discount Type: Percentage or Fixed]
    G --> F4[Discount Value + Max Cap for %]
    G --> F5[Min Booking Amount]
    G --> F6[Scope: Global or Hall-Specific]
    G --> F7[Cinema Hall selector when scope=hall]
    G --> F8[User Eligibility: All or Joined After]
    G --> F9[Joined After Date picker - Popover + Calendar]
    G --> F10[Valid Until date picker - Popover + Calendar]
    G --> F11[Is Active toggle]

    H --> F1
```

#### Table Columns

| Column | Description |
|--------|-------------|
| **Code** | Monospace badge (uppercase) — e.g. `SAVE50` |
| **Title** | Display name + truncated description |
| **Discount** | e.g. `10% off · max ₹150` or `₹50 flat`, with min amount |
| **Scope** | `Global` (violet) or `Hall` (sky) badge + hall name |
| **Eligibility** | `All users` or `Joined after DD MMM YYYY` |
| **Valid Until** | Date in red if already expired |
| **Status** | `Active` (emerald) or `Inactive` (zinc) badge |
| **Actions** | Edit (pencil) → navigates to `/offers/:id/edit` / Delete (trash) → AlertDialog |

#### Offer Form Fields

| Field | Type | Notes |
|-------|------|-------|
| Offer Code | Text | Stored uppercase; must be unique. **Read-only on edit page** |
| Title | Text | Display name shown to users |
| Description | Textarea | Optional short description on offers page |
| Discount Type | Select | `Percentage` or `Fixed Amount` |
| Discount Value | Number | Percentage (e.g. `10`) or rupee amount (e.g. `50`) |
| Max Discount Cap | Number | Only shown for percentage type; `null` = no cap |
| Min Booking Amount | Number | Grand total must be ≥ this to apply (0 = none) |
| Scope | Select | `Global` or `Hall-Specific` |
| Cinema Hall | Select | Shown only when scope = Hall (fetches all halls) |
| Applicable To | Select | `All Users` or `Users who joined after a date` |
| Joined After | Date | Shown only when eligibility = `joined_after` |
| Valid Until | Date | Offer expires after midnight of this date |
| Is Active | Switch | Toggle to disable without deleting |

#### Date Picker Implementation Note

The **Valid Until** and **Joined After** date pickers use the standard shadcn `Popover + Calendar` pattern. Because the form is on a standalone page (not inside a Radix `Dialog`), there is no `pointer-events: none` conflict.

**Pattern used (`OfferFormPage.jsx`):**
```jsx
<Popover open={validUntilPickerOpen} onOpenChange={setValidUntilPickerOpen}>
    <PopoverTrigger asChild>
        <Button variant="outline" className="w-full justify-start text-left font-normal text-sm h-9">
            <CalendarIcon className="mr-2 w-4 h-4" />
            {form.valid_until ? dayjs(form.valid_until).format("DD MMM YYYY") : "Pick expiry date"}
        </Button>
    </PopoverTrigger>
    <PopoverContent className="w-auto p-0" align="start">
        <Calendar mode="single" selected={form.valid_until}
            onSelect={d => { setField("valid_until", d); setValidUntilPickerOpen(false) }}
            initialFocus />
    </PopoverContent>
</Popover>
```

> **Historical note:** When the form was inside a Radix `Dialog`, a `createPortal`-based workaround was used because `Dialog` sets `body.style.pointerEvents = "none"`, blocking nested `Popover` content. Moving to a route-based page eliminated the conflict entirely.

#### Sidebar Navigation

"Offers" (Tag icon) is added under the **Operations** section of `AppSidebar.jsx`, visible only to SuperAdmin (same pattern as Movies/Ads).

---

### 2. Ads Management (SuperAdmin Only)

**Route**: `/ads`
**Component**: `AdsManagement.jsx`
**Access**: SuperAdmin role required
**API**: `adsAPI` in `src/services/api.js`

#### Feature Overview

```mermaid
flowchart TD
    A[Ads Management] --> T1[Ads Tab - Card Grid]
    A[Ads Management] --> T2[Analytics Tab - Table]

    T1 --> B[Create Ad]
    T1 --> C[Edit Ad]
    T1 --> D[Delete Ad]
    T1 --> E[View Click-throughs]

    T2 --> F[All Details in Table]
    T2 --> G[Metrics: Clicks, Active Count, Total]
    T2 --> H[Same Edit / Delete / Click-through Actions]

    B --> I[Set Title + Image URL]
    B --> J[Set Placement: Banner or Side]
    B --> K[Set Date Range + Active Toggle]

    E --> L[Customer Name / Email / Phone]
    E --> M[Click Timestamp]
    E --> N[Anonymous if not logged in]
```

#### Tabs

The page is split into two tabs (shadcn/ui `Tabs` component):

| Tab | Icon | Content |
|-----|------|---------|
| **Ads** | `LayoutGrid` | Card grid view — same as before |
| **Analytics** | `TableProperties` | Full table view with all columns + metrics footer |

Both tabs share all modal state — edit, delete, and click-through modals work identically from either tab.

#### Ad Placements

| Placement | Where it renders | Component |
|-----------|-----------------|-----------|
| `banner`  | `/movies` page — full-width carousel | `AdBanner.jsx` |
| `side`    | `/movie/:id` page — sticky right sidebar (md+ screens) | `MovieInfoPage.jsx` |

#### Ads Tab (Card Grid)

Each ad card shows:
- Image thumbnail preview
- Title
- Placement badge (blue = Banner, purple = Side)
- Active / Inactive badge
- Date range
- Click-through URL (linked)
- Total click count (clickable — opens click details modal)
- Edit / Delete buttons

#### Analytics Tab (Table)

Full-width scrollable table with the following columns:

| Column | Description |
|--------|-------------|
| **Title** | Ad name with a small image thumbnail |
| **Image URL** | Full URL as a truncated external link |
| **Click-through URL** | Destination URL as a truncated external link, or `—` |
| **Placement** | Badge (Banner / Side) |
| **Status** | Badge (Active / Inactive) |
| **Start Date** | Formatted with `en-IN` locale |
| **End Date** | Formatted with `en-IN` locale |
| **Clicks** | Count; click to open the per-user click details modal |
| **Actions** | Edit and Delete buttons |

Table footer row displays summary metrics: total ads · active ads · total clicks across all ads.

#### Create/Edit Form Fields

| Field        | Type     | Required | Description                          |
| ------------ | -------- | -------- | ------------------------------------ |
| Title        | Text     | Yes      | Admin reference name                 |
| Image URL    | Text     | Yes      | URL of the ad image (live preview)   |
| Click URL    | Text     | No       | Opens in new tab when ad is clicked  |
| Placement    | Select   | Yes      | `Banner` or `Side`                   |
| Start Date   | Date     | Yes      | First day the ad is served           |
| End Date     | Date     | Yes      | Last day the ad is served            |
| Active       | Toggle   | No       | Manual on/off (default on)           |

#### Click-through Details Modal

Opened by clicking the **click count** in either the Ads card or the Analytics table row. Shows a table of all recorded clicks for the selected ad:

| Column      | Source                        |
| ----------- | ----------------------------- |
| Customer    | `customers.name` or Anonymous |
| Email       | `customers.email`             |
| Phone       | `customers.phone`             |
| Clicked At  | `ad_clicks.clicked_at`        |

---

### 2. Movie Management (SuperAdmin Only)

**Route**: `/movies`  
**Component**: `MovieManagement.jsx`  
**Access**: SuperAdmin role required

#### Feature Overview

```mermaid
flowchart TD
    A[Movie Management] --> B[My Movies Tab]
    A --> C[Browse Movies Tab]

    B --> D[Add Movie]
    B --> E[Edit Movie]
    B --> F[Delete Movie]
    B --> G[Filter Movies]

    D --> H[Upload Poster to Cloudinary]
    D --> I[Set Genres & Languages]
    D --> J[Set Release Date & Status]
    D --> K[Add Cast Members]
    D --> L[Set Vote Average & Count]

    E --> M[Sync from TMDB]
    M --> N[Auto-fill empty fields from TMDB]

    C --> O[Browse Popular / Now Playing / Upcoming / Top Rated / In Theatres]
    C --> P[Search TMDB Movies]
    C --> Q[Import Movie from TMDB]
    Q --> R[Maps title, poster, trailer, cast, votes, runtime]

    G --> S[Filter by Genre / Language / Status]
```

#### Layout Behavior

The `/movies` route uses a **fixed-height tab layout** to avoid double-scrollbars:

- The page occupies the full viewport height minus the global header (`h-[calc(100vh-4rem)]`)  
- The tab bar (`My Movies` / `Browse Movies`) is fixed at the top (`shrink-0`)
- The **filter sidebar** (left) and **movie grid** (right) sit inside a `flex-1 min-h-0` row — the sidebar is `overflow-y-auto` and the grid is `overflow-y-auto`, keeping each independently scrollable
- The outer `CinemaLayout` scroll container hides its scrollbar on `/movies` (`scrollbarWidth: none`) so only the inner movie grid scrolls
- The "Movie Management" heading is **hidden on small screens** (`hidden sm:block`)

#### Movie Form Fields

| Field          | Type         | Required | Description                              |
| -------------- | ------------ | -------- | ---------------------------------------- |
| Title          | Text         | Yes      | Movie title                              |
| Description    | Textarea     | Yes      | Movie synopsis                           |
| Poster URL     | File Upload  | Yes      | Uploaded to Cloudinary                   |
| Trailer URL    | URL          | No       | YouTube/video link                       |
| Duration       | Number       | Yes      | Duration in minutes                      |
| Genres         | Multi-select | Yes      | Array of genres                          |
| Languages      | Multi-select | Yes      | Array of languages                       |
| Release Date   | Date         | Yes      | Release date                             |
| Status         | Select       | Yes      | `upcoming`, `now_showing`, `ended`       |
| Vote Average   | Number       | No       | TMDB score (0–10, step 0.1)              |
| Vote Count     | Number       | No       | Number of TMDB votes                     |
| Cast           | List         | No       | Up to 10 cast members with profile photo |

#### Cast Management UI

The cast section in `MovieForm.jsx` renders an interactive list of cast member cards:

- Each card shows the TMDB profile image (or a placeholder), the actor's **name**, and the **character** they play
- Hover a card to reveal a **remove (×)** button
- Use the **"Add Member"** inline form to manually add new cast entries (name + character fields)
- When importing from TMDB, the top 10 cast members are pre-populated automatically

#### Available Genres

Action, Comedy, Drama, Horror, Romance, Sci-Fi, Thriller, Animation, Adventure, Crime, Fantasy, Mystery, Musical, War, Western

#### Available Languages

English, Hindi, Tamil, Telugu, Malayalam, Kannada, Bengali, Marathi, Punjabi, Gujarati

#### Movie Card Display

Each movie card shows:

- Poster image (lazy loaded)
- Title
- Genres (with icons)
- Languages (with globe icon)
- Duration
- Release date
- Status badge (color-coded)
- **Vote average** (star icon) and **vote count** sourced from the database
- Edit/Delete actions

#### TMDB Integration

##### Browse Movies Tab

The **Browse Movies** tab (`TMDBBrowser` component) lets a SuperAdmin explore TMDB catalogs directly inside the admin panel:

| Category      | TMDB Endpoint proxied           |
| ------------- | ------------------------------- |
| Popular       | `GET /api/tmdb/popular`         |
| Now Playing   | `GET /api/tmdb/now-playing`     |
| In Theatres   | `GET /api/tmdb/in-theatres`     |
| Upcoming      | `GET /api/tmdb/upcoming`        |
| Top Rated     | `GET /api/tmdb/top-rated`       |
| Search        | `GET /api/tmdb/search?query=…`  |

Each movie card has an **Import** button. Clicking it calls `GET /api/tmdb/movie/:tmdbId` (`append_to_response=videos,credits`) to fetch full details, then pre-fills the Add Movie dialog with:

| Mapped field   | TMDB source                                       |
| -------------- | ------------------------------------------------- |
| Title          | `title`                                           |
| Description    | `overview`                                        |
| Poster URL     | `https://image.tmdb.org/t/p/w500{poster_path}`    |
| Trailer URL    | YouTube key from `videos.results` (type=Trailer)  |
| Duration       | `runtime` (minutes)                               |
| Release Date   | `release_date`                                    |
| Vote Average   | `vote_average`                                    |
| Vote Count     | `vote_count`                                      |
| Cast           | `credits.cast` (top 10, with name/character/photo)|
| `tmdb_id`      | `id` (stored for future sync)                     |

##### Sync from TMDB (Edit Mode)

When editing a movie that has a linked `tmdb_id`, the **MovieForm** shows a blue banner:

> *"Linked to TMDB #\<id\> — fill empty fields from TMDB"*

The **"Sync from TMDB"** button (with a spinning `RefreshCw` icon during the request) calls `GET /api/tmdb/movie/:tmdbId` and performs a **selective merge** — it only overwrites fields that are currently empty or null in the form, preserving any manually entered values:

| Field          | Synced only when…                         |
| -------------- | ----------------------------------------- |
| Cast           | `cast` array is empty                     |
| Vote Average   | `vote_average` is null                    |
| Vote Count     | `vote_count` is null                      |
| Trailer URL    | `trailer_url` is empty                    |
| Duration       | `duration_mins` is empty / 0              |
| Poster URL     | `poster_url` is empty                     |

#### Filtering System

```mermaid
flowchart LR
    A[User Input] --> B{Filter Type}
    B -->|Genre| C[Toggle Genre Filter]
    B -->|Language| D[Toggle Language Filter]
    B -->|Status| E[Select Status]
    B -->|Search| F[Text Search]

    C --> G[Update Filter State]
    D --> G
    E --> G
    F --> G

    G --> H[Fetch Movies with Filters]
    H --> I[Display Results]
```

---

### 2. Screen Designer

| Route | Component | Purpose |
|---|---|---|
| `/screens` | `CinemaScreens.jsx` (`CinemaScreenDesigner`) | Screen list, delete, view preview |
| `/screens/new` | `ScreenDesignerPage.jsx` | Add new screen with layout designer |
| `/screens/:id/edit` | `ScreenDesignerPage.jsx` | Edit existing screen layout |

**Access**: Admin (any role)

#### Feature Overview

Interactive seat layout designer for creating and managing cinema screens with customizable seating arrangements. The list and designer views are now **separate routes** — navigating to add/edit changes the browser URL, enabling back-button support.

```mermaid
stateDiagram-v2
    [*] --> ScreenList: /screens
    ScreenList --> AddScreen: navigate /screens/new
    ScreenList --> EditScreen: navigate /screens/:id/edit
    ScreenList --> ViewScreen: open dialog
    ScreenList --> DeleteScreen: confirm dialog

    AddScreen --> LayoutDesigner
    EditScreen --> LayoutDesigner: pre-populated from location.state

    LayoutDesigner --> ConfigureSeats: Set Rows/Cols
    ConfigureSeats --> AssignTypes: Premium/Gold/Silver
    AssignTypes --> SetPrices: Price per Type
    SetPrices --> SaveScreen
    SaveScreen --> ScreenList: navigate('/screens')

    ViewScreen --> ScreenList
    DeleteScreen --> ScreenList
```

#### Navigation Pattern

**List → Add**: `navigate('/screens/new')`
**List → Edit**: `navigate('/screens/:id/edit', { state: { screen } })` — screen object passed via `location.state` to avoid a redundant API fetch
**Designer → Back/Cancel/Save**: `navigate('/screens')`
**Guard**: If `/screens/:id/edit` is accessed directly (no `location.state`), `ScreenDesignerPage` redirects to `/screens`

#### Screen Configuration

**Basic Settings:**

```javascript
{
  name: "IMAX Screen 1",
  rows: 12,
  columns: 16,
  screen_position: "top" | "bottom",
  total_seats: 192,
  premium_seats: 64,
  gold_seats: 64,
  silver_seats: 64,
  premium_price: 200,
  gold_price: 150,
  silver_price: 130,
  layout: { ... }  // Full layout JSONB (seats array + aisle config)
}
```

#### Seat Layout Structure

Each seat in the layout:

```javascript
{
  id: "2-5",             // "{rowIndex}-{colIndex}" (0-based)
  row: "C",              // Row letter (A, B, C...)
  column: 6,             // 1-based column number
  label: "C-6",          // Display label (row + column)
  type: "premium",       // "premium" | "gold" | "silver" | "entrance" | "door"
  price: 200,            // Derived from pricing config for this type
  isBlocked: false       // Admin-blocked seat
}
```

#### Aisle System

Aisles are **gaps** in the grid, not seats. Stored in the layout as:

```javascript
{
  aisleAfterColumns: [5, 11],  // vertical gap after column 5 and 11
  aisleAfterRows: ["D", "H"]   // horizontal gap after row D and H
}
```

- **Aisle tool** in designer: click a column number header to toggle a vertical aisle; click a row's `⬌` button to toggle a horizontal aisle
- Old screens saved with passage-type seats are **auto-migrated** on load via `migrateLayoutFromPassage()` in `ScreenDesignerPage.jsx`

#### Rows/Columns Resize Behaviour

- **Add mode**: changing rows or columns reinitializes the entire seat grid (all seats reset to `silver`).
- **Edit mode**: changing rows or columns **reconciles** — existing seat configurations are preserved; only new seats (for the expanded dimensions) are added as `silver`; seats for removed rows/columns are dropped.
- **Debounced input** (600 ms): the Rows and Columns inputs are controlled by separate `inputRows`/`inputColumns` state that updates immediately for a responsive feel. The actual layout update (and seat reconciliation) fires only after the user stops typing for 600 ms, preventing unnecessary re-renders on every keystroke.

#### UI Layout

The designer uses a **3-column layout** inside a sticky-header shell:

| Area | Description |
|---|---|
| **Sticky top navbar** | Back arrow, "Screen Designer" title, screen name badge; action buttons: Clear Selection, Reset Grid, Preview, Save Screen |
| **Left panel** (~240px) | Screen Settings · Seat Summary · Pricing · Selection Mode · Tools |
| **Center panel** (flex) | Zoom bar + scrollable/scalable seat canvas |
| **Right panel** (~220px) | Selected Seat inspector · Quick Apply · History log · Keyboard Shortcuts |

#### Seat Summary

Live counts derived from `layout.seats` + `selectedSeats` (updates on every seat change):

| Metric | Description |
|---|---|
| TOTAL | Non-blocked seats |
| PREMIUM / GOLD / SILVER | Count by type (non-blocked) |
| BLOCKED | Seats with `isBlocked: true` |
| SELECTED | Currently selected seat count |

#### Zoom Controls

Canvas is wrapped in a `transform: scale()` div. Controls in the zoom bar:

| Control | Action |
|---|---|
| `−` / `+` | Decrease / increase zoom by 10% (range 20–200%) |
| `Fit` | Calculates zoom to fit the grid into the center panel |
| `80%` display | Shows current zoom level |

#### Undo / Redo

Before every destructive operation (`updateMultipleSeats`, aisle toggles, reset), the current `layout` snapshot is pushed to `undoStack` (capped at 50). Redo stack is cleared on new edits.

- Keyboard: `Ctrl+Z` / `Ctrl+Shift+Z` (Mac: `⌘Z` / `⌘⇧Z`)
- Buttons in zoom bar: `← Undo` / `Redo →` (disabled when stack is empty)

#### Interactive Features

**Selection Modes** (buttons in left panel):

| Mode | Behaviour |
|---|---|
| **Single** | Click a seat to apply the active tool immediately; click clears selection after applying |
| **Multi** | `Ctrl+Click` to toggle individual seats; `Shift+Click` to range-select a rectangle; tool applies to all selected on next click |
| **Row** | Click any seat to select its entire row |

**Additional selection actions:**
- **Column Select** — Click column number header (any mode except Aisle)
- **Row ⬌ button** — Click row's `⬌` button to select full row (or toggle aisle in Aisle mode)
- **Select All** (`Ctrl+A`) — Selects all non-blocked seats

**Tools:**

| Tool | Action |
|---|---|
| Premium / Gold / Silver | Set seat type + price |
| Aisle | Toggle aisle gap after a column/row header |
| Entrance / Door | Mark seat as entrance or door (price = 0) |
| Block/Unblock | Toggle `isBlocked` on selected seats |

**Quick Apply panel** (right panel):

| Button | Action |
|---|---|
| Fill Selected Row | Selects all seats in the row of the last-selected seat |
| Apply to All Selected | Applies the current tool to all selected seats at once |
| Clear Selected | Clears the current selection |

**Selected Seat Inspector** (right panel):

When exactly 1 seat is selected, the right panel shows: Row, Column, Type badge, Price, Blocked status.

**History Log** (right panel):

Every action (grid generated, type applied, aisle toggled, undo/redo, save) is prepended to a 50-entry scrollable log with a colored dot and timestamp.

**Visual Indicators:**

- **Premium**: Yellow gradient
- **Gold**: Violet gradient
- **Silver**: Slate gradient
- **Entrance/Door**: Green/Orange gradient
- **Blocked**: Red background + ✕
- **Selected**: Blue border + ring + scale-up

**Keyboard Shortcuts:**

| Shortcut | Action |
|---|---|
| `⌘Z` / `Ctrl+Z` | Undo |
| `⌘⇧Z` / `Ctrl+Shift+Z` | Redo |
| `⌘A` / `Ctrl+A` | Select All |
| `⌘+Click` / `Ctrl+Click` | Toggle individual seat in Multi mode |
| `⇧+Click` / `Shift+Click` | Range-select in Multi mode |

#### Layout Designer Workflow

```mermaid
sequenceDiagram
    participant User
    participant Designer
    participant State
    participant API

    User->>Designer: Set rows & columns
    Designer->>State: Generate initial layout
    State-->>Designer: Display grid

    User->>Designer: Select seats
    Designer->>State: Update selection

    User->>Designer: Change seat type
    Designer->>State: Update seat properties
    State-->>Designer: Re-render layout

    User->>Designer: Click Save
    Designer->>State: Validate layout
    State->>API: POST /api/screens/create
    API-->>Designer: Screen created
    Designer->>User: Success notification
```

---

### 3. Shows Management

| Route | Component | Purpose |
|---|---|---|
| `/shows` | `ShowsManagement.jsx` | List shows by date, delete |
| `/shows/new` | `AddShowPage.jsx` | Create a single show |
| `/shows/bulk` | `AddMultipleShowsPage.jsx` | Create multiple time slots at once |
| `/shows/:id/edit` | `EditShowPage.jsx` | Edit an existing show |
| `/show/:id` | `ShowPage.jsx` | View seat layout + live status + revenue for a specific show |

**Access**: Admin (any role)

#### Feature Overview

Manage movie showtimes with date-based scheduling. Add/Edit are **separate routes** — navigating to them changes the URL, enabling back-button support. Deleting a show stays on the list page via `window.confirm`.

```mermaid
flowchart TD
    A[Shows Management /shows] --> B[View Shows by Date]
    A --> C[navigate /shows/new]
    A --> D[navigate /shows/bulk]
    A --> E[navigate /shows/:id/edit]
    A --> F[Delete Show - confirm dialog]

    B --> G[Group by Movie]
    G --> H[Display Show Time Buttons]

    C --> I[AddShowPage - single show form]
    D --> J[AddMultipleShowsPage - shared details + time slots list]
    E --> K[EditShowPage - pre-filled form fetched by ID]

    I --> L[POST /api/shows/create]
    J --> M[POST /api/shows/bulk]
    K --> N[PUT /api/shows/edit/:id]

    L --> A
    M --> A
    N --> A
```

#### UI Layout — Shows List (`/shows`)

**Header row:** "Shows Management" title + description + `+ Add Multiple` (outline) + `+ Add Show` (primary) buttons (top-right)

**Date Selector shelf** (`bg-card border-b border-border`):
- **3-part vertical date buttons** (DOW / day number / month) — 7 days, `w-14` fixed width, hidden scrollbar
- Selected: `bg-primary text-primary-foreground`; others: `border border-border hover:border-primary`
- `selectedDate` stored as a `Date` object; formatted to `YYYY-MM-DD` string only when calling `showsAPI.getShowsByDate(dateStr)`

**Availability Legend:** `● AVAILABLE` (green) + `● FAST FILLING` (amber) aligned right

**Movie Cards** (`rounded-xl`, shadcn `Card`):
- Poster (`rounded-lg shadow-md`) + movie title + duration badge + genre/language pills (`rounded-full`)
- Show time buttons: **green-bordered outlined style** — screen info (MapPin icon + name + seat count) on line 1, time (bold) on line 2, language + price on line 3
- **Edit/Delete hover actions** — appear absolutely positioned at top-right of each button on `group-hover`
  - Edit → `navigate('/shows/:id/edit')`
  - Delete → `window.confirm` → `showsAPI.deleteShow(id)` → refresh

**Show list data flow:**
```mermaid
sequenceDiagram
    participant Admin
    participant ShowsPage
    participant API

    Admin->>ShowsPage: Navigate to /shows
    ShowsPage->>ShowsPage: selectedDate = today (Date object)
    ShowsPage->>API: GET /api/shows/date/YYYY-MM-DD
    API-->>ShowsPage: { grouped: [{ movie_id, title, poster_url, shows: [...] }] }
    ShowsPage->>Admin: Render date shelf + movie cards + show buttons

    Admin->>ShowsPage: Click different date
    ShowsPage->>ShowsPage: setSelectedDate(date) → triggers useEffect
    ShowsPage->>API: Refetch with new date
    ShowsPage->>Admin: Update shows section (isLoading skeleton)
```

#### Add Show Page (`/shows/new`)

Full-page form. On success → navigates back to `/shows`.

**Auto-fill behaviour:**
- **Select movie** → `language_version` auto-filled smartly:
  - 1 language → auto-set, plain text input shown
  - Multiple languages → `language_version` cleared; a **Select dropdown** appears with each language as an option (admin must pick one)
- **Select screen** → `price_override.premium/gold/silver` auto-filled from `screen.premium_price / gold_price / silver_price`
- Price override can be manually overridden; language input (single-language case) can also be edited manually

**Form fields:**

```javascript
{
  movie_id: "uuid",              // MovieSearchDropdown — passes full movie object; language auto-filled
  screen_id: "uuid",             // Select from screensAPI.getMyScreens(); prices auto-filled
  show_date: "2024-02-15",       // ShadCN Popover + Calendar picker; stored as YYYY-MM-DD via dayjs
  start_time: "14:00",           // time input
  end_time: "16:30",             // time input
  language_version: "Tamil",     // auto-set (1 lang) or chosen from dropdown (multiple langs); editable when single
  price_override: {              // auto-filled from screen defaults; editable
    premium: 200,
    gold: 150,
    silver: 130
  }
}
```

Calls `showsAPI.createShow(formData)` → `POST /api/shows/create`.

#### Edit Show Page (`/shows/:id/edit`)

Fetches show by ID on mount (`showsAPI.getShowById(id)`), maps response to form fields:

| Response field | Form field |
|---|---|
| `movie.id` | `movie_id` |
| `movie.language` | `movieLanguages` state (drives dropdown vs input) |
| `screen.id` | `screen_id` |
| `show_details.show_date` | `show_date` |
| `show_details.start_time` | `start_time` |
| `show_details.end_time` | `end_time` |
| `show_details.language_version` | `language_version` |
| `show_details.price_override` | `price_override` |

**Language Version behaviour (same as AddShowPage):**
- `movieLanguages` is initialized from `movie.language` on fetch — so the correct UI (input vs dropdown) is shown immediately on load
- If the stored `language_version` matches one of the movie's languages, the dropdown pre-selects it
- If it was stored in the old joined format (e.g. `"English, Tamil"`), it won't match any dropdown option — admin must re-select
- Changing the movie resets `movieLanguages` and clears `language_version` (auto-sets if new movie has 1 language)

Loading skeleton shown while fetching. On success → `navigate('/shows')`.
Calls `showsAPI.editShow(id, formData)` → `PUT /api/shows/edit/:id`.

#### Add Multiple Shows Page (`/shows/bulk`)

Same auto-fill behaviour as AddShowPage (language dropdown for multi-language movies, auto-set for single). Instead of a single start/end time, there is a **dynamic time slots list**:
- Minimum 1 slot; "+ Add Slot" button appends a new row
- Each row: `Slot N — Start` (time) + `End` (time) + trash icon (disabled when only 1 slot)
- Footer label: `N slot(s) → N show(s) will be created`
- Submit button label updates dynamically: `Create N Show(s)`

Payload sent:
```javascript
{
  movie_id: "uuid",
  screen_ids: ["uuid"],          // single screen wrapped in array
  dates: ["2024-02-15"],         // single date wrapped in array
  time_slots: [
    { start_time: "10:00", end_time: "12:30" },
    { start_time: "14:00", end_time: "16:30" },
    { start_time: "19:00", end_time: "21:30" }
  ],
  language_version: "Tamil",     // single language chosen from dropdown or auto-set
  price_override: { premium: 200, gold: 150, silver: 130 }
}
```

Calls `showsAPI.createMultipleShows(payload)` → `POST /api/shows/bulk`. Backend creates one show per `screen × date × time_slot` (cartesian product).

#### Show Detail Page (`/show/:id`)

Read-only view for a specific show. Navigated to from `ShowsManagement` when an admin clicks a show time button.

**Data fetched on mount (in parallel):**
- `showsAPI.getShowById(id)` → `GET /api/shows/get/:id` — full seat layout, show metadata, price override
- `settingsAPI.getSettings()` → `GET /api/settings` — `convenience_fee_per_ticket` + `gst_percentage` (falls back to ₹15 / 18% if request fails)

**Left panel (3/4 width) — Seat Layout:**
- Legend: AVAILABLE (green border) / HELD (yellow) / BOOKED (red)
- Seats rendered by category section (Premium → Gold → Silver) via `renderSeatSection`
- Aisle gaps and `screenPosition` honoured (same logic as user `SeatSelectionPage`)
- Screen indicator bar positioned above or below seats based on `screen.layout.screenPosition`
- Seats are display-only — no click interaction (admin view)

**Right panel (1/4 width) — Seat Status Overview card (sticky):**

*Seat counts:*
- Available (green tile), Held (yellow tile), Booked (red tile)
- Booked Seats grid — shows each booked seat label (e.g. `A4`) in a 4-column grid, max-height scrollable

*Revenue Breakdown section:*
- Per-category rows (only rendered if count > 0): `Premium (N × ₹price) — ₹subtotal`
- **Ticket Revenue** subtotal (sum across all categories)
- **Conv. Fee** row: `₹{fee} × {totalBooked tickets}` — flat per-ticket rate from settings
- **GST** row: `{gst_percentage}% on conv.` — GST applied only on convenience fee (not on ticket price), matching backend logic
- **Total Revenue** — highlighted green box: `ticketRevenue + convFee + gst`

*All amounts formatted in Indian locale:* `₹1,90,000` via `toLocaleString('en-IN')`

**Price resolution helpers:**
```javascript
getPrice(type)      // price_override[type] ?? layout.pricing[type] ?? 0
formatCurrency(amt) // `₹${Math.round(amt).toLocaleString('en-IN')}`
```

**Revenue formula:**
$$\text{ticketRevenue} = \sum_{\text{booked seats}} \text{getPrice}(\text{seat.type})$$
$$\text{convFee} = \text{totalBookedCount} \times \text{convenienceFeePerTicket}$$
$$\text{gst} = \text{convFee} \times \frac{\text{gstPercentage}}{100}$$
$$\text{total} = \text{ticketRevenue} + \text{convFee} + \text{gst}$$

> Revenue counts **booked** seats only — `status === "booked" | "BOOKED"`. Held seats (`in_booking` / `HELD`) are excluded.

---

#### Movie Search Component

**`MovieSearchDropdown`** — Extracted to `src/components/MovieSearchDropdown.jsx`, shared across AddShowPage, EditShowPage, and AddMultipleShowsPage.

**Features:**
- Real-time debounced search (300ms) via `moviesAPI.getAllMovies({ search, limit: 10 })`
- Shows poster thumbnail, title, genres + duration in dropdown
- Pre-loads the selected movie on edit (fetches by `selectedMovieId` on mount via `moviesAPI.getMovieById`)
- Separate `isInitialLoading` state to prevent flicker when editing an existing show
- Calls `onMovieSelect(movie)` with the **full movie object** — callers extract `movie.id` and `movie.language`

---

### 4. Additional Features

#### HomePage

- Dashboard overview
- Recent activity

#### Bookings

**Route**: `/bookings`
**Component**: `Bookings.jsx`

Displays all bookings for the admin's cinema hall in a paginated table, with filter-aware aggregate stats cards.

**Features:**
- **Stats cards** (4-card grid above filters): Total Bookings, Total Revenue, Convenience Fees Collected, GST Collected — all scoped to active filters and updated on every fetch
  - Skeleton loading state while data is in flight
  - Icons: `Ticket` (primary), `IndianRupee` (emerald), `Receipt` (sky), `Percent` (amber)
- Table columns: Customer (avatar + name + email), Movie, Show date/time, Screen (pill badge with monitor icon), Seats (primary-tinted chips), Amount, Status badge, Booking ID (monospace code)
- Filters (4-column grid layout): show date (ShadCN Popover + Calendar picker), movie title search (debounced 400ms), screen dropdown (populated from `screensAPI.getMyScreens()`), booking status dropdown
  - Filter params: `date`, `search`, `screen_id`, `status` (all / confirmed / cancelled / completed)
  - Active filter count badge on the Filters header
  - "Clear all" button shown when any filter is active
- Status badges: custom glass-style pills — emerald (confirmed), red (cancelled), blue (completed)
- Customer column: coloured avatar circle with initials derived from name
- Screen column: rendered as a `<Monitor>` icon pill using `screensAPI.getMyScreens()` data loaded on mount
- **Clickable rows** — clicking any booking row navigates to `/bookings/:id` (BookingDetailPage)
- Pagination: 50 bookings per page with Prev/Next controls and "Showing X of Y" count
- Loading skeleton, contextual empty state (with "Clear filters" CTA when filters active), and error state
- Calls `GET /api/booking/admin/all` with `{ date, search, status, screen_id, page }` query params on filter/page change; response includes `stats` aggregate

#### BookingDetailPage

**Route**: `/bookings/:id`
**Component**: `BookingDetailPage.jsx`

Full detail view for a single booking. Accessible by clicking a row in the Bookings list or via direct URL.

**Data source**: reuses `GET /api/booking/admin/verify/:booking_id` (same endpoint as VerifyTicket QR scanner) via `bookingAPI.getBookingById(id)`.

**Layout** (responsive: stacked on mobile, 2-col on `lg`):

Left column (`lg:col-span-2`):
- **Show Details card** — movie title, date (`DD MMM YYYY`), time, screen (pill badge), seat chips
- **Customer card** — coloured avatar circle with initials, name, email
- **Payment card** — payment status badge, Razorpay payment ID (monospace), booked-at timestamp

Right column (`lg:col-span-1`):
- **Price Breakdown card** — receipt-style line items:
  - Tickets (N) — computed: `total_amount + discount_amount − convenience_fee − gst_amount`
  - Convenience fee
  - GST
  - Offer discount (only shown if `discount_amount > 0`)
  - Divider + bold **Total**
- **Offer Applied card** — only rendered when `offer_code` is present; shows offer code (styled green monospace chip) + discount amount. Hidden entirely when no offer was used.

**Header**: movie title + booking status badge + full booking UUID in a code element.

**States**:
- Loading: full-page skeleton grid matching the 2-col layout
- Error / not found: centred icon + message + "Back to Bookings" button
- Back button (ghost) at top navigates to `/bookings`

**Price formula** (frontend-computed, no extra API call):
```
seatSubtotal = total_amount + discount_amount − convenience_fee − gst_amount
```

**Icons**: `ArrowLeft`, `User`, `CreditCard`, `Ticket`, `Monitor`, `CalendarDays`, `Clock`, `Tag`, `IndianRupee`, `Receipt`, `Percent`

#### VerifyTicket

**Route**: `/verify-ticket`
**Component**: `VerifyTicket.jsx`

QR code ticket verification page for cinema entrance staff.

**Features:**
- **Camera scanner** — starts/stops the device camera via `html5-qrcode`'s `Html5Qrcode` class. Decodes QR code frames at 10fps with a 220×220 scanning box. On successful decode, validates the UUID format before calling the API
- **Manual entry** — `Input` + "Verify" button to paste or type a booking UUID. Also supports pressing Enter. Same UUID validation applied before the API call
- **Result card** (view-only) — shows customer name + email, movie title, show date/time, screen name, seat labels (as chips), total amount, booking status badge, full booking UUID
- **Error states** — "Invalid QR code" if scanned text is not a UUID, API error message if booking not found
- **Camera cleanup** — `useEffect` stops the scanner on component unmount to prevent camera from staying open when navigating away
- Calls `GET /api/booking/admin/verify/:booking_id`

**Layout:** Two columns on desktop (scanner + input left, result right), stacked vertically on mobile.

**Dependencies:**
- `html5-qrcode` — `Html5Qrcode` class for camera-based QR scanning
- `qrcode.react` — not used here (QR display is user-side only)

#### ProfilePage

- Admin profile information
- Edit profile details

#### SettingsPage

**Route**: `/settings`
**Component**: `SettingsPage.jsx`
**Access**: Super Admin only (read is open, save calls a SuperAdmin-protected endpoint)

Configure system-wide booking fees:

- **Convenience Fee (₹ per ticket)** — flat fee added to every ticket
- **GST Percentage (%)** — applied only on the convenience fee (not on seat prices)
- **Live preview** — card below the inputs shows the per-ticket fee + GST + total in real time as you type
- On save, calls `PUT /api/settings` (SuperAdmin auth required); shows success/error toast
- Loads current values from `GET /api/settings` on mount

---

## API Service Layer

**Location**: `src/services/api.js`

### Service Modules

```mermaid
graph LR
    A[API Services] --> B[authAPI]
    A --> C[screensAPI]
    A --> D[moviesAPI]
    A --> E[showsAPI]
    A --> F[bookingAPI]
    A --> G2[settingsAPI]

    B --> G[register, login, logout, getMe, refresh]
    C --> H[createScreen, getMyScreens, updateScreen, deleteScreen]
    D --> I[addMovie, editMovie, deleteMovie, getAllMovies, getMovieById]
    E --> J[createShow, createMultipleShows, editShow, deleteShow, getShowsByDate]
    F --> K[getCinemaHallBookings, verifyBooking, getBookingById]
    G2 --> L[getSettings, updateSettings]
```

### API Configuration

```javascript
const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:5000";

// All requests include:
credentials: "include"; // Send cookies
```

### Error Handling

```javascript
try {
  const response = await fetch(url, options);
  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.message || "Request failed");
  }
  return response.json();
} catch (error) {
  console.error("API Error:", error);
  throw error;
}
```

---

## UI Components

### shadcn/ui Components Used

| Component | Usage               |
| --------- | ------------------- |
| Button    | Actions, navigation |
| Card      | Content containers  |
| Dialog    | Modals for forms    |
| Input     | Text fields         |
| Select    | Dropdowns           |
| Badge     | Status indicators   |
| Separator | Visual dividers     |
| Skeleton  | Loading states      |
| Sonner    | Toast notifications |
| Calendar  | Date pickers        |
| Popover   | Contextual menus    |

### Custom Components

**AppSidebar** - Navigation sidebar

- Collapsible menu
- Active route highlighting
- User profile section
- Theme toggle

**Loader** - Loading spinner

- Full-screen overlay
- Animated spinner

**MovieSearchDropdown** (`src/components/MovieSearchDropdown.jsx`) - Shared movie selector used in show forms

- Debounced search (300ms), shows poster + genre + duration in results
- Pre-loads selected movie by ID on mount (for edit pages)
- Calls `onMovieSelect(movie)` with **full movie object** — callers extract `movie.id` and `movie.language`
- Used by: `AddShowPage`, `EditShowPage`, `AddMultipleShowsPage`

**SearchMovies** - Movie search component

- Debounced search
- Autocomplete dropdown

**CinemaLayout** - Main layout wrapper

- Sidebar + content area
- Responsive design

---

## State Management

### Context Providers

```mermaid
graph TD
    A[App] --> B[AuthContext]
    B --> C[Router]
    C --> D[Pages]

    D --> E[Access admin state]
    D --> F[Access hall state]
    D --> G[Call login/logout]
```

**AuthContext API:**

```javascript
const {
  admin, // Current admin object
  hall, // Admin's cinema hall
  isLoggedIn, // Boolean auth status
  loading, // Loading state
  login, // Login function
  logout, // Logout function
  checkAuth, // Verify auth on mount
  refreshToken, // Refresh access token
} = useAuth();
```

---

## Routing & Navigation

### Route Protection

```mermaid
flowchart TD
    A[User Navigates] --> B{isLoggedIn?}
    B -->|No| C[Redirect to /login]
    B -->|Yes| D{Route Type}
    D -->|Normal| E[Allow Access]
    D -->|SuperAdmin| F{Is SuperAdmin?}
    F -->|No| G[Redirect to /unauthorized]
    F -->|Yes| E
```

### Navigation Structure

**Sidebar Menu Items:**

1. Home
2. Movies (SuperAdmin only)
3. Screens
4. Shows
5. Bookings
6. Verify Ticket
7. Profile
8. Settings

---

## Image Upload

### Cloudinary Integration

**Service**: `src/services/cloudinary.js`

```javascript
export const uploadImageToCloudinary = async (file) => {
  const formData = new FormData();
  formData.append("file", file);
  formData.append("upload_preset", CLOUDINARY_UPLOAD_PRESET);

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/image/upload`,
    { method: "POST", body: formData },
  );

  const data = await response.json();
  return data.secure_url;
};
```

**Usage in MovieManagement:**

1. User selects image file
2. Upload to Cloudinary
3. Get secure URL
4. Save URL in movie record

---

## Styling & Theming

### Tailwind Configuration

**Custom Colors:**

- Primary: Cinema brand color
- Secondary: Accent color
- Background: Light/dark mode support
- Foreground: Text colors
- Muted: Subtle elements

### Dark Mode Support

Theme toggle available in sidebar:

- Light mode
- Dark mode
- System preference

---

## Performance Optimizations

### Lazy Loading

**Images:**

```jsx
import { LazyLoadImage } from "react-lazy-load-image-component";

<LazyLoadImage src={movie.poster_url} effect="blur" className="..." />;
```

**Routes:**
Code splitting with React.lazy() (if implemented)

### Debouncing

**Search Input:**

```javascript
const debounce = (func, wait) => {
  let timeout;
  return (...args) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), wait);
  };
};
```

---

## User Workflows

### Complete Show Creation Workflow

```mermaid
sequenceDiagram
    participant Admin
    participant ShowsPage
    participant AddShowPage
    participant API

    Admin->>ShowsPage: Click "+ Add Show"
    ShowsPage->>AddShowPage: navigate('/shows/new')

    Admin->>AddShowPage: Search + select movie
    Note over AddShowPage: 1 language → auto-set; multiple → language dropdown shown
    Admin->>AddShowPage: Select screen
    Note over AddShowPage: price_override auto-filled from screen.premium/gold/silver_price
    Admin->>AddShowPage: Set date, start/end time
    Admin->>AddShowPage: Pick language (if dropdown) / review prices
    Admin->>AddShowPage: Click "Add Show"

    AddShowPage->>API: POST /api/shows/create
    API-->>AddShowPage: Show created
    AddShowPage->>Admin: toast.success("Show added successfully!")
    AddShowPage->>ShowsPage: navigate('/shows')
```

### Add Multiple Shows Workflow

```mermaid
sequenceDiagram
    participant Admin
    participant ShowsPage
    participant BulkPage
    participant API

    Admin->>ShowsPage: Click "+ Add Multiple"
    ShowsPage->>BulkPage: navigate('/shows/bulk')

    Admin->>BulkPage: Select movie → language auto-set or dropdown shown
    Admin->>BulkPage: Select screen → prices auto-filled
    Admin->>BulkPage: Set date
    Admin->>BulkPage: Add time slots (+ Add Slot button)
    Note over BulkPage: "3 slots → 3 shows will be created"
    Admin->>BulkPage: Click "Create 3 Shows"

    BulkPage->>API: POST /api/shows/bulk {screen_ids:[id], dates:[date], time_slots:[...]}
    API-->>BulkPage: { shows: [...3 created shows] }
    BulkPage->>Admin: toast.success("3 shows created successfully!")
    BulkPage->>ShowsPage: navigate('/shows')
```

### Screen Designer Workflow

```mermaid
sequenceDiagram
    participant Admin
    participant ScreenList
    participant Designer
    participant API

    Admin->>ScreenList: Visit /screens
    ScreenList->>API: GET /api/screens
    API-->>ScreenList: screens[]
    ScreenList->>Admin: Display screen cards

    alt Add new screen
        Admin->>ScreenList: Click "Add Screen"
        ScreenList->>Designer: navigate('/screens/new')
        Designer->>Admin: Blank designer (10×15 silver defaults)
    else Edit existing screen
        Admin->>ScreenList: Click "Edit" on card
        ScreenList->>Designer: navigate('/screens/:id/edit', {state:{screen}})
        Designer->>Designer: Load screen from location.state + migrateLayoutFromPassage()
        Designer->>Admin: Pre-populated designer
    end

    Admin->>Designer: Configure rows, columns, pricing
    Designer->>Designer: Add mode — reinitialize all seats; Edit mode — reconcile (preserve existing, add new)
    Admin->>Designer: Paint seat types with tools
    Admin->>Designer: Toggle aisles on headers
    Admin->>Designer: Click Save

    Designer->>API: POST /api/screens/create OR PUT /api/screens/update/:id
    API-->>Designer: Success
    Designer->>Admin: Show success dialog → navigate('/screens')
```

---

## Environment Variables

```env
# API Configuration
VITE_API_BASE_URL=http://localhost:5000

# Cloudinary Configuration
VITE_CLOUDINARY_CLOUD_NAME=your-cloud-name
VITE_CLOUDINARY_UPLOAD_PRESET=your-preset
```

---

## Build & Deployment

### Development

```bash
npm run dev
# Runs on http://localhost:5173
```

### Production Build

```bash
npm run build
# Outputs to /dist
```

### Deployment

Configured for Vercel deployment:

- Automatic builds on push
- Environment variables via Vercel dashboard
- Custom domain support

---

## Recently Implemented

✅ **Screen Designer — full UI redesign** (March 25, 2026):
- Replaced 2-column layout with a **3-column layout**: left settings panel (240px) | center canvas | right inspector panel (220px)
- New **sticky top navbar**: back arrow, "Screen Designer" title, screen name badge, and action buttons (Clear Selection, Reset Grid, Preview, Save Screen)
- **Seat Summary** cards in left panel: live counts for Total / Premium / Gold / Silver / Blocked / Selected (updates reactively)
- **Selection Mode** buttons now include a **Row** mode (clicking any seat selects its entire row), alongside Single and Multi
- **Zoom controls** in center toolbar: `−` / `%` / `+` / `Fit`; grid scales via CSS `transform: scale()` (range 20–200%)
- **Undo/Redo** (`Ctrl+Z` / `Ctrl+Shift+Z`): 50-step layout snapshot stack; cleared on new edits; buttons disabled when stack is empty
- **Select All** (`Ctrl+A`): selects all non-blocked seats
- **History log** (right panel): 50-entry scrollable log of every action with colored dots and timestamps
- **Selected Seat inspector** (right panel): shows Row / Column / Type / Price / Blocked when exactly 1 seat is selected
- **Quick Apply** (right panel): Fill Selected Row, Apply to All Selected, Clear Selected
- **Keyboard Shortcuts** reference table (right panel): static display of Undo, Redo, Select All, Multi-select, Row select
- **Preview dialog**: read-only grid rendered at 70% scale in a full-width modal
- Tool buttons restyled as pill buttons with active ring highlight; gold changed from blue → violet gradient

✅ **ShowPage — Revenue Breakdown** (March 25, 2026):
- New **Revenue Breakdown** section added to the Seat Status Overview sidebar card
- Settings fetched in parallel (`settingsAPI.getSettings()`) on page mount; defaults to ₹15/ticket + 18% GST if request fails
- Per-category rows (Premium / Gold / Silver) — each shows `N seats × ₹price = ₹subtotal` (row hidden when count is 0)
- Ticket Revenue subtotal, Convenience Fee row (`₹fee × N tickets`), GST row (`X% on conv.`)
- **Total Revenue** highlighted green tile: `ticketRevenue + convFee + gst` — only booked seats counted, held seats excluded
- GST applied on convenience fee only (not ticket price), matching backend `payment.Controller.js` logic
- All currency values formatted in Indian comma style: `₹1,90,000` via `toLocaleString('en-IN')`
- `getPrice(type)` helper resolves `price_override → layout.pricing → 0`; `formatCurrency(amt)` helper added

✅ **ShowPage — aisle gaps + screenPosition** (March 12, 2026):
- `renderSeatSection` now reads `aisleAfterColumns` and `aisleAfterRows` from `screen.layout` (same logic as user `SeatSelectionPage`)
  - `aisleAfterColumns: number[]` — inserts a `w-3` gap div after the matching column number in every row
  - `aisleAfterRows: string[]` — inserts a `h-3` gap div after the matching row letter
- `screenPosition` (`"top"` | `"bottom"`, default `"bottom"`) from `screen.layout` now controls whether "SCREEN THIS WAY" bar renders **above** or **below** the seat sections
- `React` import added (required for `React.Fragment` wrapper pattern)

✅ **Screen Designer — edit-mode resize fix + debounced inputs** (March 12, 2026):
- **Bug fix**: in edit mode, increasing rows/columns now generates proper seat objects for the new rows/columns. Previously they rendered as empty, non-clickable placeholders because the seat-initialization effect was guarded by `!isEditing`.
- **Seat reconciliation**: the effect now runs in both modes. Add mode fully reinitializes; edit mode preserves existing seat configs and only appends new seats for expanded dimensions (or drops out-of-bounds seats when dimensions shrink).
- **Debounced inputs**: `inputRows` / `inputColumns` state drives the inputs immediately; a 600 ms `setTimeout` (cleared on each keystroke) applies the change to `layout.rows` / `layout.columns`, preventing rapid seat-grid rebuilds while the user is still typing.

✅ **Screen Designer split into separate routes** (March 12, 2026):
- `/screens` now renders `CinemaScreens.jsx` (list only — ~260 lines)
- `/screens/new` and `/screens/:id/edit` render new `ScreenDesignerPage.jsx` (extracted designer)
- Edit navigation passes full screen object via `location.state` to avoid extra API fetch
- Page refresh / direct URL to edit route redirects safely to `/screens`
- Legacy `AddScreen.jsx` and `EditScreen.jsx` (localStorage-based) deleted
- Browser URL now reflects which mode (add vs edit) the user is in; back button works correctly

✅ **QR Ticket Verification** (March 8, 2026):
- New `VerifyTicket` page at `/verify-ticket` — camera QR scanner + manual booking UUID entry
- Shows full booking details (view-only) after scan/lookup
- `ScanLine` icon added to Operations sidebar
- `bookingAPI.verifyBooking(bookingId)` added to admin API service
- Calls `GET /api/booking/admin/verify/:booking_id` (scoped to admin's cinema hall)

✅ **Shows Management — separate routes + bulk create** (March 12, 2026):
- "Add Show" modal replaced by dedicated **`AddShowPage`** at `/shows/new`
- "Edit Show" modal replaced by dedicated **`EditShowPage`** at `/shows/:id/edit` — fetches show data via `showsAPI.getShowById(id)` on mount, pre-fills all fields
- New **`AddMultipleShowsPage`** at `/shows/bulk` — shared movie/screen/date/language/price section + dynamic time slots list (+ Add Slot / remove); calls `POST /api/shows/bulk`
- **`MovieSearchDropdown`** extracted from `ShowsManagement.jsx` into `src/components/MovieSearchDropdown.jsx` — now shared across all three pages
- **Auto-fill on screen select**: `price_override.premium/gold/silver` auto-populated from `screen.premium_price / gold_price / silver_price`
- **Auto-fill on movie select**: if movie has **1 language**, `language_version` is auto-set and shown as a plain text input; if movie has **multiple languages**, a Select dropdown appears so the admin picks exactly one — `language_version` is not pre-set until a choice is made; applies to `AddShowPage`, `EditShowPage`, and `AddMultipleShowsPage`
- **EditShowPage**: `movieLanguages` initialized from fetched `movie.language` on mount so the language dropdown/input renders correctly on page load
- `ShowsManagement.jsx` stripped to list-only (removed `ShowModal`, modal state, `screensAPI` call); Edit button navigates to `/shows/:id/edit`; header now has both `+ Add Multiple` and `+ Add Show` buttons

✅ **ShowsManagement UI redesign** (BookMyShow style):
- Replaced shadcn `Tabs` date selector with 3-part vertical buttons (DOW/day/month) — 7 days, same shelf style as user pages
- `selectedDate` changed from string to `Date` object; formatted to string only at API call
- Availability legend (● AVAILABLE green / ● FAST FILLING amber)
- Show time buttons redesigned: green-bordered outlined style with screen name + seat count / time / language + price in 3 lines
- Movie cards use `rounded-xl` + `rounded-full` genre/language pills
- Edit/Delete hover actions preserved on `group-hover`
- Removed unused `Tabs, TabsContent, TabsList, TabsTrigger` imports

✅ **OffersManagement — route-based create/edit pages** (March 17, 2026):
- Replaced the Create/Edit `Dialog` with dedicated route-based pages: `/offers/new` and `/offers/:id/edit` (both render `OfferFormPage.jsx`)
- `OffersManagement.jsx` stripped to list-only: "Create Offer" button navigates to `/offers/new`; pencil icon navigates to `/offers/:id/edit`; only the delete `AlertDialog` remains
- `OfferFormPage.jsx` (new): fetches offer by ID via `GET /api/offers/:id` when editing; navigates back to `/offers` on save or cancel; offer code field is read-only on edit
- Date pickers reverted from `createPortal` to standard `Popover + Calendar` — the pointer-events conflict only existed because the form was inside a Radix `Dialog`
- `offersAPI.getById(id)` added to `cinema-hall-admin/src/services/api.js`

✅ **OffersManagement — date picker fix via createPortal** (March 17, 2026 — superseded):
- ~~Replaced Radix `Popover + Calendar` with a `createPortal`-based floating calendar~~ — this workaround was made obsolete by the route-based refactor above

✅ **ShadCN date pickers — AddShowPage, AddMultipleShowsPage, Bookings** (March 12, 2026):
- Replaced all `<input type="date">` fields with ShadCN **Popover + Calendar** date picker pattern
- `AddShowPage` (`show_date`), `AddMultipleShowsPage` (`show_date`), `Bookings` (Show Date filter)
- Trigger: outlined `Button` with `CalendarIcon`; displays `MMM D, YYYY` or "Pick a date" placeholder
- `onSelect` stores date as `YYYY-MM-DD` string via `dayjs`; `selected` prop converts string back to `Date` object
- `handleDateChange` in `Bookings.jsx` updated to accept a `Date` object directly (was `e.target.value` from input event)

✅ **Bookings page — Screen filter + visual redesign** (March 9, 2026):
- Added **Screen dropdown filter** — fetches screens via `screensAPI.getMyScreens()` on mount; passes `screen_id` UUID to `GET /api/booking/admin/all`
- Backend `getCinemaHallBookings` updated: added `$5::uuid IS NULL OR sc.id = $5` condition to both data and count queries (param index shift: limit → `$6`, offset → `$7`)
- `bookingAPI.getCinemaHallBookings` updated to forward `screen_id` query param
- Filters reorganised into a 4-column grid with a "Filters" header row, active filter count badge, and "Clear all" button
- Customer column: coloured avatar circle (initials, colour derived from name hash)
- Screen column: `<Monitor>` icon pill badge
- Seats: primary-tinted chips with subtle border
- Status indicators: custom glass-style pills (emerald / red / blue) replacing generic `<Badge>`
- Booking ID: monospace `<code>` element with muted background
- Empty state: icon-in-circle, descriptive sub-text, "Clear filters" CTA

---

**Last Updated**: March 16, 2026 (SettingsPage — configurable convenience fee + GST; settingsAPI added)

---

## Best Practices Implemented

✅ **Code Organization:**

- Feature-based folder structure
- Reusable components
- Centralized API services
- Context for global state

✅ **User Experience:**

- Loading states with skeletons
- Error handling with toast notifications
- Responsive design
- Keyboard navigation support

✅ **Performance:**

- Lazy loading images
- Debounced search
- Optimistic UI updates
- Efficient re-renders

✅ **Security:**

- Protected routes
- Role-based access control
- Secure cookie handling
- Input validation

---

## Future Enhancements

💡 **Potential Features:**

- Real-time booking updates (WebSockets)
- Analytics dashboard
- Revenue reports
- Email notifications
- Bulk operations
- Export data (CSV/PDF)
- Advanced filtering
- Seat availability heatmap

---

**Last Updated**: March 25, 2026 (ShowPage — Revenue Breakdown added to Seat Status Overview sidebar: per-category ticket revenue, convenience fee, GST, and Indian-formatted total; `settingsAPI` fetched in parallel on mount)
