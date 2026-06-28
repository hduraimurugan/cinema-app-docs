# Movie Management - Backend

## Routes

### `movies.routes.js`
- **Path**: `routes/movies.routes.js`
- **Purpose**: Admin movie management endpoints

| Endpoint | Method | Middleware | Controller |
|----------|--------|-----------|------------|
| `/api/movies` | GET | - | `getAllMovies` |
| `/api/movies/add` | POST | `verifySuperAdmin` | `addMovie` |
| `/api/movies/edit/:movieId` | PUT | `verifySuperAdmin` | `editMovie` |
| `/api/movies/delete/:movieId` | DELETE | `verifySuperAdmin` | `deleteMovie` |
| `/api/movies/:id` | GET | - | `getMovieById` |
| `/api/movies/:movieId/status` | PATCH | `verifySuperAdmin` | `updateMovieStatus` |
| `/api/movies/tmdb-ids` | GET | `verifySuperAdmin` | `getMovieTmdbIds` |
| `/api/movies/migrate-backdrops` | GET | - | `runBackdropMigration` |
| `/api/movies/proxy-image` | GET | - | Inline TMDB image proxy |

### `userMovies.routes.js`
- **Path**: `routes/userMovies.routes.js`
- **Purpose**: Customer-facing movie endpoints (no auth required)

| Endpoint | Method | Controller |
|----------|--------|------------|
| `GET /api/user/movies` | GET | `getAllMovies` |
| `GET /api/user/movies/:id` | GET | `getMovieById` |
| `GET /api/user/movies/location/movies` | GET | `getMoviesByLocation` |
| `GET /api/user/movies/state/movies` | GET | `getMoviesByState` |
| `GET /api/user/movies/:movieId/showtimes` | GET | `getMovieDetailsWithShowtimes` |
| `GET /api/user/movies/location/districts` | GET | `getDistrictsInState` |
| `GET /api/user/movies/location/cinema-halls` | GET | `getCinemaHallsByLocation` |
| `GET /api/user/movies/location/theatres` | GET | `getCinemaHallsWithShows` |

### `tmdb.routes.js`
- **Path**: `routes/tmdb.routes.js`
- **Purpose**: TMDB proxy endpoints (authenticated)

| Endpoint | Method | Middleware | Controller |
|----------|--------|-----------|------------|
| `/api/tmdb/popular` | GET | `verifySuperAdmin` | `getTMDBPopular` |
| `/api/tmdb/now-playing` | GET | `verifySuperAdmin` | `getTMDBNowPlaying` |
| `/api/tmdb/upcoming` | GET | `verifySuperAdmin` | `getTMDBUpcoming` |
| `/api/tmdb/top-rated` | GET | `verifySuperAdmin` | `getTMDBTopRated` |
| `/api/tmdb/in-theatres` | GET | `verifySuperAdmin` | `getTMDBInTheatres` |
| `/api/tmdb/search` | GET | `verifySuperAdmin` | `searchTMDB` |
| `/api/tmdb/movie/:tmdbId` | GET | `verifySuperAdmin` | `getTMDBMovieDetails` |

## Controllers

### `movies.Controller.js`
- **Path**: `controllers/movies.Controller.js`

| Function | Purpose |
|----------|---------|
| `addMovie` | Inserts movie with all fields including JSON-serialized cast |
| `editMovie` | Dynamic UPDATE with whitelisted field filtering |
| `deleteMovie` | Hard delete by ID |
| `getAllMovies` | Paginated + filtered listing (genre[], language[] array overlap, ILIKE search) |
| `getMovieById` | Single movie by UUID, validates UUID format |
| `updateMovieStatus` | Patch status field |
| `getMovieTmdbIds` | Returns all TMDB IDs for duplicate detection |
| `runBackdropMigration` | Backfills backdrop_path from TMDB for movies with tmdb_id |

### `userMovies.Controller.js`
- **Path**: `controllers/userMovies.Controller.js`

| Function | Purpose |
|----------|---------|
| `getAllMovies` | Customer movie listing with filters |
| `getMovieById` | Single movie detail |
| `getMoviesByLocation` | Movies with shows in a specific district+state (JOIN shows→screens→cinema_hall) |
| `getMoviesByState` | Same but state-wide |
| `getMovieDetailsWithShowtimes` | Movie + grouped cinema halls + shows for a date |
| `getDistrictsInState` | Available districts where movies are showing |
| `getCinemaHallsByLocation` | Halls in a location with active shows |
| `getCinemaHallsWithShows` | Halls → movies → shows grouped response for a date/location |

### `tmdb.Controller.js`
- **Path**: `controllers/tmdb.Controller.js`

| Function | Purpose |
|----------|---------|
| `getTMDBPopular` | TMDB `/movie/popular` proxy |
| `getTMDBNowPlaying` | TMDB `/movie/now_playing` proxy |
| `getTMDBUpcoming` | TMDB `/movie/upcoming` proxy |
| `getTMDBTopRated` | TMDB `/movie/top_rated` proxy |
| `searchTMDB` | TMDB `/search/movie` proxy |
| `getTMDBInTheatres` | TMDB `/discover/movie` with last 30 days filter |
| `getTMDBMovieDetails` | TMDB `/movie/:id` with videos+credits appended |
