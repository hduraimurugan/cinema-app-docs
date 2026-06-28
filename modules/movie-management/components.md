# Movie Management - Components

## Admin App Component Hierarchy

```
MovieManagement (page)
 ├── FilterPanel (genre/language/status/date/search filters)
 ├── Tabs
 │    ├── Tab: "Database" → Movie grid/list
 │    │    └── MovieCard → poster, title, status badge, actions dropdown
 │    │         └── DropdownMenu → Edit, Delete, View Details
 │    └── Tab: "TMDB Browser" → TMDBBrowser
 │         ├── Section tabs (Popular, In Theatres, Now Playing, Upcoming, Top Rated, Search)
 │         ├── Language filter
 │         ├── TMDBCard → poster, rating, import button
 │         └── Pagination
 ├── EditMovieSheet (slide-over)
 │    └── MovieForm
 │         ├── Title, Duration, Description fields
 │         ├── Genre/Language tags
 │         ├── Release date calendar picker
 │         ├── Poster upload → Cloudinary
 │         ├── Backdrop upload → Cloudinary
 │         ├── Cast member list + add form
 │         └── Sync from TMDB button
 └── Add Movie button → MovieForm (inline)

MoviePage (single movie view)
 ├── Poster + backdrop hero
 ├── Movie metadata (genre, language, duration, rating)
 ├── Trailer embed (YouTube iframe)
 ├── Cast list
 └── Status selector (super admin only)

SearchMovies (global search bar)
 └── SearchInput → debounced → dropdown results → navigate to MoviePage

MovieSearchDropdown (show creation form)
 └── SearchInput → debounced → dropdown → select movie
```

## Component Catalog

| Component | File | Props | State | Parent | Children |
|-----------|------|-------|-------|--------|----------|
| `MovieManagement` | `pages/MovieManagement.jsx` | - | movies[], filters, activeTab, editingMovie, editSheetOpen, uploading | Layout/Routes | FilterPanel, Tabs (MovieGrid, TMDBBrowser), EditMovieSheet, MovieForm |
| `EditMovieSheet` | `pages/MovieManagement.jsx` | open, onOpenChange, formData, setFormData, onSubmit | - | MovieManagement | MovieForm |
| `FilterPanel` | `pages/MovieManagement.jsx` | filters, setFilters, expandedFilters, setExpandedFilters, clearFilters | expanded state | MovieManagement | Genre/Status/Language/Date filters |
| `MovieForm` | `pages/MovieForm.jsx` | formData, setFormData, onSubmit, uploading, handleImageUpload, editingMovie, onSyncFromTMDB, syncing | datePickerOpen, newCast, showCastForm | MovieManagement / EditMovieSheet | shadcn Input, Textarea, Badge, Calendar, Button |
| `MoviePage` | `pages/MoviePage.jsx` | - | movie, loading, error, selectedStatus | Routes | LazyLoadImage, Badge, Select |
| `TMDBBrowser` | `components/TMDBBrowser.jsx` | - | activeSection, movies[], page, searchQuery, languageFilter, addedTmdbIds[] | MovieManagement | Section tabs, TMDBCard, Pagination |
| `TMDBCard` | `components/TMDBBrowser.jsx` | movie, isAdded, onImport, importing | - | TMDBBrowser | Poster, rating badge, import/added badge |
| `MovieSearchDropdown` | `components/MovieSearchDropdown.jsx` | selectedMovieId, onMovieSelect, placeholder | searchValue, movies[], isLoading, isOpen, selectedMovie | Show creation forms | Search input, result list |
| `SearchMovies` | `components/SearchMovies.jsx` | - | searchValue, movies[], isSearchFocused, showResults | App sidebar/header | Search input, result cards |
