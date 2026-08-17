# Movie Management - API

## Current Authorization Note

Admin movie list and mutation routes now use permission middleware (`movies.read`, `movies.create`, `movies.update`, and `movies.delete`) after admin authentication. Super admins continue to pass through the permission middleware.

Customer-facing movie responses expose the numeric `vote_average` field used by the user app for normalized one-decimal ratings.

## Admin Movie Endpoints

### GET `/api/movies`
- **Description**: List all movies with filters and pagination
- **Auth**: None (public)
- **Query**: `?page=1&limit=10&genre=Action&language=Tamil&status=now_showing&release_date=2026-06-28&search=avengers`
- **Success (200)**: `{ movies[], page, limit, total }`

### POST `/api/movies/add`
- **Description**: Add new movie
- **Auth**: `verifySuperAdmin`
- **Body**: `{ title, description, poster_url, trailer_url, duration_mins, genre[], language[], release_date, status, tmdb_id, cast[], vote_average, vote_count, backdrop_path }`
- **Success (201)**: Full movie object

### PUT `/api/movies/edit/:movieId`
- **Description**: Edit movie fields
- **Auth**: `verifySuperAdmin`
- **Body**: Any subset of movie fields
- **Success (200)**: Updated movie object

### DELETE `/api/movies/delete/:movieId`
- **Description**: Delete a movie
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ message, movie }`

### GET `/api/movies/:id`
- **Description**: Get single movie by ID
- **Auth**: None (public)
- **Success (200)**: `{ movie }`

### PATCH `/api/movies/:movieId/status`
- **Description**: Update movie status
- **Auth**: `verifySuperAdmin`
- **Body**: `{ status }`
- **Success (200)**: Updated movie object

### GET `/api/movies/tmdb-ids`
- **Description**: Get all TMDB IDs in local DB
- **Auth**: `verifySuperAdmin`
- **Success (200)**: `{ tmdb_ids: [123, 456] }`

### GET `/api/movies/migrate-backdrops`
- **Description**: Backfill backdrop_path from TMDB
- **Auth**: None (public)
- **Success (200)**: `{ success, message, skipped[], failed[] }`

### GET `/api/movies/proxy-image?url=`
- **Description**: Proxy TMDB images (prevents hotlink blocking)
- **Auth**: None (public)
- **Query**: `?url=https://image.tmdb.org/...`
- **Success (200)**: Image binary
- **Errors**: 400 (non-TMDB URL)

## Customer Movie Endpoints

### GET `/api/user/movies`
- **Description**: Browse movies with filters
- **Auth**: None (public)
- **Query**: `?page=1&limit=10&genre=Action&language=Tamil&status=now_showing&search=avengers`
- **Success (200)**: `{ success, movies[], page, limit, count }`

### GET `/api/user/movies/:id`
- **Description**: Single movie detail
- **Auth**: None (public)
- **Success (200)**: `{ success, movie }`

### GET `/api/user/movies/location/movies?district=Mumbai&state=Maharashtra`
- **Description**: Movies showing in a specific location
- **Auth**: None (public)
- **Success (200)**: `{ success, count, district, state, movies[] }`

### GET `/api/user/movies/state/movies?state=Maharashtra`
- **Description**: Movies showing in a state (all districts)
- **Auth**: None (public)
- **Success (200)**: `{ success, count, state, movies[] }`

### GET `/api/user/movies/:movieId/showtimes?district=Mumbai&state=Maharashtra&date=2026-06-28`
- **Description**: Movie details with grouped cinema hall showtimes
- **Auth**: None (public)
- **Success (200)**: `{ success, movie, cinema_halls[] }`

### GET `/api/user/movies/location/districts?state=Maharashtra`
- **Description**: Get districts with active shows
- **Auth**: None (public)
- **Success (200)**: `{ success, state, districts[] }`

### GET `/api/user/movies/location/cinema-halls?district=Mumbai&state=Maharashtra`
- **Description**: Cinema halls in a location
- **Auth**: None (public)
- **Success (200)**: `{ success, count, district, state, cinema_halls[] }`

### GET `/api/user/movies/location/theatres?district=Mumbai&state=Maharashtra&date=2026-06-28`
- **Description**: Theatres with movies and shows grouped
- **Auth**: None (public)
- **Success (200)**: `{ success, count, district, state, date, cinema_halls[] }`

## TMDB Proxy Endpoints

### GET `/api/tmdb/popular?page=1&with_original_language=en`
### GET `/api/tmdb/now-playing?page=1&with_original_language=en`
### GET `/api/tmdb/upcoming?page=1&with_original_language=en`
### GET `/api/tmdb/top-rated?page=1&with_original_language=en`
### GET `/api/tmdb/in-theatres?page=1&with_original_language=en`
### GET `/api/tmdb/search?query=avengers&page=1&with_original_language=en`
### GET `/api/tmdb/movie/:tmdbId`

- **Auth**: `verifySuperAdmin` (all TMDB endpoints)
- **Success (200)**: Raw TMDB API response
- **Errors**: 502 (TMDB API error)
