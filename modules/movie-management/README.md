# Movie Management Module

## Module Purpose
Manage the entire movie lifecycle from discovery (via TMDB) through creation, editing, status tracking, and customer-facing browsing.

## Business Objective
Provide cinema operators a complete movie catalog system with TMDB integration for metadata import, custom movie creation, genre/language filtering, and customer-facing movie browsing with showtimes.

## Features
- **TMDB Integration**: Browse TMDB popular, now-playing, upcoming, top-rated, in-theatres movies
- **One-click Import**: Import movie details from TMDB with poster, backdrop, cast, rating
- **Custom Movie Creation**: Add movies manually with full metadata
- **Movie Editing**: Edit all movie fields, sync from TMDB
- **Status Management**: now_showing, upcoming, expired status transitions
- **Filtering & Search**: Filter by genre, language, status, date; full-text search
- **Customer Movie Browsing**: Browse movies by location (district/state), view showtimes grouped by cinema hall
- **Cloudinary Integration**: Upload poster and backdrop images to Cloudinary

## User Roles Involved
- **Super Admin**: Add, edit, delete movies; update movie status
- **Customer**: Browse movies, view details with showtimes
- **Cinema Admin**: View movie list (read-only or limited depending on permissions)

## Dependencies
- **TMDB API**: Movie metadata source (posters, backdrops, cast, ratings)
- **Cloudinary**: Image upload/storage for posters and backdrops
- **PostgreSQL**: Movie data storage with array columns for genre and language

## Related Modules
- [Show Management](../show-management/README.md) - Movies are linked to shows
- [Screen Management](../screen-management/README.md) - Movies play on screens via shows
- [Settings](../settings/README.md) - TMDB API key configuration
