# Movie Management - File Reference

## Admin App (`cinema-hall-admin`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/MovieManagement.jsx` | Main movie catalog + TMDB browser + CRUD | moviesAPI, tmdbAPI, cloudinary, MovieForm, TMDBBrowser, shadcn/ui, lucide-react, utils | `MovieManagement` |
| `src/pages/MovieForm.jsx` | Reusable create/edit movie form | shadcn/ui (Input, Textarea, Badge, Calendar, Button), lucide-react | `MovieForm` |
| `src/pages/MoviePage.jsx` | Single movie detail view | moviesAPI, shadcn/ui, lucide-react, LazyLoadImage, useAuth | `MoviePage` |
| `src/components/TMDBBrowser.jsx` | TMDB movie discovery interface | tmdbAPI, shadcn/ui, lucide-react | `TMDBBrowser` |
| `src/components/MovieSearchDropdown.jsx` | Searchable movie dropdown | moviesAPI, shadcn/ui, lucide-react, LazyLoadImage | `MovieSearchDropdown` |
| `src/components/SearchMovies.jsx` | Global movie search bar | moviesAPI, shadcn/ui, lucide-react, LazyLoadImage | `SearchMovies` |
| `src/services/api.js` | API client (moviesAPI, tmdbAPI) | fetch | `moviesAPI`, `tmdbAPI` |
| `src/services/cloudinary.js` | Cloudinary image upload | cloudinary | `uploadImageToCloudinary` |
| `src/utils/utils.js` | Movie constants (genres, languages, formatStatus) | - | `genres`, `languages`, `formatStatus`, `getStatusColor` |

## User App (`cinema-hall-users`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `src/pages/MoviesPage.jsx` | Customer movie browsing | customerMoviesAPI | `MoviesPage` |
| `src/pages/MovieDetailsPage.jsx` | Movie + showtime details | customerMoviesAPI | `MovieDetailsPage` |
| `src/pages/MovieInfoPage.jsx` | Additional movie info | - | `MovieInfoPage` |
| `src/components/MoviesList.jsx` | Movie grid display | - | `MoviesList` |
| `src/services/api.js` | API client (customerMoviesAPI) | fetch | `customerMoviesAPI` |

## Backend API (`cinema-hall-api`)

| File Path | Purpose | Key Imports | Exports |
|-----------|---------|-------------|---------|
| `routes/movies.routes.js` | Admin movie routes | movies.Controller, verifySuperAdmin | `router` |
| `routes/userMovies.routes.js` | Customer movie routes | userMovies.Controller | `router` |
| `routes/tmdb.routes.js` | TMDB proxy routes | tmdb.Controller, verifySuperAdmin | `router` |
| `controllers/movies.Controller.js` | Admin movie CRUD logic | pool, logger | 8 controller functions |
| `controllers/userMovies.Controller.js` | Customer movie query logic | pool, logger | 8 controller functions |
| `controllers/tmdb.Controller.js` | TMDB API proxy logic | logger | 7 controller functions |
