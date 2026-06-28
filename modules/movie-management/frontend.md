# Movie Management - Frontend

## Admin App (`cinema-hall-admin`)

### Pages

#### `MovieManagement.jsx`
- **Path**: `src/pages/MovieManagement.jsx`
- **Purpose**: Main movie catalog page with list view, filtering, TMDB browser integration, and CRUD operations
- **State**: `movies[]`, `loading`, `error`, `filters` (genre[], language[], status, date, search), `activeTab` ('database' | 'tmdb'), `editingMovie`, `editSheetOpen`
- **API Usage**: `moviesAPI.getAllMovies()`, `moviesAPI.addMovie()`, `moviesAPI.editMovie()`, `moviesAPI.deleteMovie()`, `moviesAPI.updateStatus()`, `tmdbAPI.getPopular()`, `tmdbAPI.getNowPlaying()`, `tmdbAPI.getUpcoming()`, `tmdbAPI.getTopRated()`, `tmdbAPI.search()`, `tmdbAPI.getInTheatres()`, `tmdbAPI.getTmdbIds()`
- **Data Flow**: On mount fetches movies + existing TMDB IDs. Supports dual-tab layout: "Database" (local movies) and "TMDB Browser" (external discovery). Importing from TMDB auto-fills movie form. Edit via sheet overlay.
- **Key Functions**:
  - `handleSubmit` - Creates or updates movie with poster/backdrop upload
  - `handleImport` - Imports TMDB movie to local DB
  - `handleDelete` - Deletes movie with confirmation
  - `handleStatusChange` - Bulk/patch status updates

#### `MoviePage.jsx`
- **Path**: `src/pages/MoviePage.jsx`
- **Purpose**: Single movie detail view with full metadata display
- **State**: `movie`, `loading`, `error`, `selectedStatus`, `updatingStatus`
- **API Usage**: `moviesAPI.getMovieById()`, `moviesAPI.updateStatus()`
- **Data Flow**: Fetches movie by `:id` param, displays poster, details, cast, trailer embed. Super admin can change movie status.

#### `MovieForm.jsx`
- **Path**: `src/pages/MovieForm.jsx`
- **Purpose**: Reusable movie form component (create + edit modes)
- **Props**: `formData`, `setFormData`, `onSubmit`, `onCancel`, `uploading`, `handleImageUpload`, `editingMovie`, `onSyncFromTMDB`, `syncing`, `hideActions`, `handleBackdropUpload`
- **State**: `datePickerOpen`, `newCast`, `showCastForm`
- **Data Flow**: Synchronized form state from parent. TMDB sync fills empty fields from TMDB API. Supports dynamic cast member addition.

#### `EditMovieDialog.jsx`
- **Path**: `src/pages/EditMovieDialog.jsx`
- **Purpose**: Placeholder/wrapper (currently minimal, functionality in MovieManagement via EditMovieSheet)

### Components

#### `TMDBBrowser.jsx`
- **Path**: `src/components/TMDBBrowser.jsx`
- **Purpose**: External movie discovery from TMDB with section tabs (Popular, In Theatres, Now Playing, Upcoming, Top Rated, Search)
- **State**: `activeSection`, `movies[]`, `page`, `searchQuery`, `languageFilter`, `addedTmdbIds[]`
- **API Usage**: `tmdbAPI.getPopular()`, `tmdbAPI.getNowPlaying()`, `tmdbAPI.getUpcoming()`, `tmdbAPI.getTopRated()`, `tmdbAPI.getInTheatres()`, `tmdbAPI.search()`
- **Data Flow**: Fetches from TMDB API, checks local `addedTmdbIds` to mark already-imported movies, provides import button per movie

#### `MovieSearchDropdown.jsx`
- **Path**: `src/components/MovieSearchDropdown.jsx`
- **Purpose**: Searchable dropdown for movie selection (used in show creation forms)
- **Props**: `selectedMovieId`, `onMovieSelect`, `placeholder`
- **State**: `searchValue`, `movies[]`, `isLoading`, `isOpen`, `selectedMovie`
- **API Usage**: `moviesAPI.getAllMovies()` with debounced search
- **Data Flow**: Debounced search (300ms), fetches top 10 matches, displays with poster thumbnails and duration

#### `SearchMovies.jsx`
- **Path**: `src/components/SearchMovies.jsx`
- **Purpose**: Global movie search bar with dropdown results
- **State**: `searchValue`, `movies[]`, `isSearchFocused`, `showResults`
- **API Usage**: `moviesAPI.getAllMovies()` with debounced search
- **Data Flow**: Navigates to movie detail page on selection

### Services

#### `api.js` (moviesAPI, tmdbAPI sections)
- **Path**: `src/services/api.js`
- **Purpose**: Movie and TMDB API endpoints

### Utilities

#### `utils.js`
- **Path**: `src/utils/utils.js`
- **Purpose**: Movie-related constants: `genres[]`, `languages[]`, `formatStatus()`, `getStatusColor()`

#### `cloudinary.js`
- **Path**: `src/services/cloudinary.js`
- **Purpose**: Cloudinary upload widget for posters and backdrops

---

## User App (`cinema-hall-users`)

### Pages

#### `MoviesPage.jsx`
- **Path**: `src/pages/MoviesPage.jsx`
- **Purpose**: Customer-facing movie browsing with filters
- **API Usage**: `customerMoviesAPI.getAllMovies()`, `getMoviesByLocation()`

#### `MovieDetailsPage.jsx`
- **Path**: `src/pages/MovieDetailsPage.jsx`
- **Purpose**: Single movie detail with cinema hall showtimes
- **API Usage**: `customerMoviesAPI.getMovieDetailsWithShowtimes()`

#### `MovieInfoPage.jsx`
- **Path**: `src/pages/MovieInfoPage.jsx`
- **Purpose**: Additional movie information view

### Components

#### `MoviesList.jsx`
- **Path**: `src/components/MoviesList.jsx`
- **Purpose**: Movie grid/list display component

### Services

#### `api.js` (customerMoviesAPI section)
- **Path**: `src/services/api.js`
- **Purpose**: Customer-facing movie endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `getAllMovies(params)` | GET `/api/user/movies` | Browse with filters |
| `getMovieById(id)` | GET `/api/user/movies/:id` | Single movie |
| `getMoviesByLocation(district, state)` | GET `/api/user/movies/location/movies` | Location-based |
| `getMoviesByState(state)` | GET `/api/user/movies/state/movies` | State-based |
| `getMovieDetailsWithShowtimes(movieId, district, state, date)` | GET `/api/user/movies/:movieId/showtimes` | Movie + showtimes |
| `getDistrictsInState(state)` | GET `/api/user/movies/location/districts` | District list |
| `getCinemaHallsByLocation(district, state)` | GET `/api/user/movies/location/cinema-halls` | Halls in area |
| `getTheatresWithShows(district, state, date)` | GET `/api/user/movies/location/theatres` | Halls + shows |
