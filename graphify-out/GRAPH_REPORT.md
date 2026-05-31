# Graph Report - .  (2026-05-31)

## Corpus Check
- 259 files · ~186,316 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1225 nodes · 2220 edges · 125 communities (112 shown, 13 thin omitted)
- Extraction: 75% EXTRACTED · 25% INFERRED · 0% AMBIGUOUS · INFERRED: 566 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Admin Authentication & Security|Admin Authentication & Security]]
- [[_COMMUNITY_Customer Authentication & OTP|Customer Authentication & OTP]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Admin Frontend Dependencies|Admin Frontend Dependencies]]
- [[_COMMUNITY_Admin Frontend Dependencies|Admin Frontend Dependencies]]
- [[_COMMUNITY_User Frontend Dependencies|User Frontend Dependencies]]
- [[_COMMUNITY_Booking & Payment APIs|Booking & Payment APIs]]
- [[_COMMUNITY_Admin Frontend Dependencies|Admin Frontend Dependencies]]
- [[_COMMUNITY_Customer Authentication & OTP|Customer Authentication & OTP]]
- [[_COMMUNITY_Booking & Payment APIs|Booking & Payment APIs]]
- [[_COMMUNITY_Admin Frontend Dependencies|Admin Frontend Dependencies]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Package Dependencies|Package Dependencies]]
- [[_COMMUNITY_Booking & Payment APIs|Booking & Payment APIs]]
- [[_COMMUNITY_Admin Frontend Dependencies|Admin Frontend Dependencies]]
- [[_COMMUNITY_Booking & Payment APIs|Booking & Payment APIs]]
- [[_COMMUNITY_Customer Authentication & OTP|Customer Authentication & OTP]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Tailwind Module|Tailwind Module]]
- [[_COMMUNITY_Package Module|Package Module]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Admin UI Components|Admin UI Components]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_User UI Components|User UI Components]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Screen Designer & Seat Layout|Screen Designer & Seat Layout]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Package Module|Package Module]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_User UI Components|User UI Components]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Application Routing & Security Guards|Application Routing & Security Guards]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Booking & Payment Views|Booking & Payment Views]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Admin UI Components|Admin UI Components]]
- [[_COMMUNITY_Jsconfig Module|Jsconfig Module]]
- [[_COMMUNITY_Authentication Services|Authentication Services]]
- [[_COMMUNITY_Screen Designer & Seat Layout|Screen Designer & Seat Layout]]
- [[_COMMUNITY_User UI Components|User UI Components]]
- [[_COMMUNITY_Ad Campaign Management|Ad Campaign Management]]
- [[_COMMUNITY_Jsconfig Module|Jsconfig Module]]
- [[_COMMUNITY_React Contexts & State|React Contexts & State]]
- [[_COMMUNITY_Admin UI Components|Admin UI Components]]
- [[_COMMUNITY_Admin UI Components|Admin UI Components]]
- [[_COMMUNITY_Admin UI Components|Admin UI Components]]
- [[_COMMUNITY_Admin Authentication & Security|Admin Authentication & Security]]
- [[_COMMUNITY_User UI Components|User UI Components]]
- [[_COMMUNITY_User UI Components|User UI Components]]
- [[_COMMUNITY_Movie Catalog & TMDB Integration|Movie Catalog & TMDB Integration]]

## God Nodes (most connected - your core abstractions)
1. `Documentation Index` - 119 edges
2. `Admin Panel Documentation` - 109 edges
3. `User Application Documentation` - 83 edges
4. `⚙️ Cinema Hall Management - Admin Panel` - 60 edges
5. `🎟️ Cinema Hall Ticket Booking - Customer Web App` - 55 edges
6. `Backend API Documentation` - 55 edges
7. `🎬 Cinema Hall Ticket Booking System - Backend API Service` - 42 edges
8. `Concurrency-Safe Seat Booking - Implementation Plan` - 28 edges
9. `useAuth()` - 26 edges
10. `useCustomerAuth()` - 25 edges

## Surprising Connections (you probably didn't know these)
- `User Application Documentation` --conceptually_related_to--> `prefix`  [INFERRED]
  docs/users.md → cinema-hall-admin/components.json
- `🎬 Cinema Hall Ticket Booking System - Backend API Service` --conceptually_related_to--> `private`  [INFERRED]
  cinema-hall-api/README.md → cinema-hall-admin/package.json
- `Admin Panel Documentation` --conceptually_related_to--> `country-state-city`  [INFERRED]
  docs/admin.md → cinema-hall-admin/package.json
- `Admin Panel Documentation` --conceptually_related_to--> `html5-qrcode`  [INFERRED]
  docs/admin.md → cinema-hall-admin/package.json
- `User Application Documentation` --conceptually_related_to--> `lucide-react`  [INFERRED]
  docs/users.md → cinema-hall-admin/package.json

## Import Cycles
- None detected.

## Communities (125 total, 13 thin omitted)

### Community 0 - "Admin Authentication & Security"
Cohesion: 0.05
Nodes (44): App(), CinemaLayout(), ThemeContext, HomePage(), ProfilePage(), SettingsPage(), ProtectedRoute(), AppSidebar() (+36 more)

### Community 1 - "Customer Authentication & OTP"
Cohesion: 0.07
Nodes (52): PASSWORD_POLICY_CHECKS, changePassword(), forgotPassword(), getAdminSecurity(), getAdminSecurityLogs(), getAllAdmins(), getCinemaAdminMe(), getLockDuration() (+44 more)

### Community 2 - "Movie Catalog & TMDB Integration"
Cohesion: 0.07
Nodes (21): debounce(), SearchMovies(), LANG_OPTIONS, SECTIONS, TMDB_GENRE_MAP, TMDBBrowser(), EMPTY_FORM, formatDate() (+13 more)

### Community 3 - "Admin Frontend Dependencies"
Cohesion: 0.05
Nodes (43): dependencies, class-variance-authority, clsx, cmdk, country-state-city, date-fns, @fontsource-variable/jetbrains-mono, @hookform/resolvers (+35 more)

### Community 4 - "Admin Frontend Dependencies"
Cohesion: 0.10
Nodes (28): hooks, files, references, routes, __dirname, migrations, execArgs, ext (+20 more)

### Community 5 - "User Frontend Dependencies"
Cohesion: 0.05
Nodes (41): dependencies, class-variance-authority, clsx, cmdk, country-state-city, date-fns, embla-carousel-autoplay, embla-carousel-react (+33 more)

### Community 6 - "Booking & Payment APIs"
Cohesion: 0.10
Nodes (24): pool, getAllCustomers(), getDashboardStats(), getRefundByBooking(), getRefunds(), manuallySettleRefund(), createScreen(), deleteScreen() (+16 more)

### Community 7 - "Admin Frontend Dependencies"
Cohesion: 0.08
Nodes (17): qrcode.react, react-lazy-load-image-component, builds, qrcode.react, react-lazy-load-image-component, adsAPI, bookingAPI, offersAPI (+9 more)

### Community 8 - "Customer Authentication & OTP"
Cohesion: 0.12
Nodes (17): adsAPI, bookingAPI, offersAPI, paymentAPI, settingsAPI, showsAPI, Admin Panel Documentation, EMPTY_FORM (+9 more)

### Community 9 - "Booking & Payment APIs"
Cohesion: 0.17
Nodes (19): createOffer(), deleteOffer(), getActiveOffers(), getAllCinemaHalls(), getAllOffers(), getOfferById(), updateOffer(), validateOffer() (+11 more)

### Community 10 - "Admin Frontend Dependencies"
Cohesion: 0.12
Nodes (14): style, dayjs, recharts, shadcn, dayjs, components, style, dayjs (+6 more)

### Community 11 - "Ad Campaign Management"
Cohesion: 0.10
Nodes (19): devDependencies, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals, tw-animate-css, @types/node (+11 more)

### Community 12 - "Package Dependencies"
Cohesion: 0.10
Nodes (19): author, dependencies, bcrypt, chalk, cookie-parser, cors, dotenv, jsonwebtoken (+11 more)

### Community 13 - "Booking & Payment APIs"
Cohesion: 0.16
Nodes (14): allowedOrigins, app, appStartTime, cleanupExpiredHolds(), confirmBooking(), getBookingByPaymentId(), getBookingDetails(), getCinemaHallBookings() (+6 more)

### Community 14 - "Admin Frontend Dependencies"
Cohesion: 0.19
Nodes (12): components, utils, react, tailwindcss, build, preview, ⚙️ Cinema Hall Management - Admin Panel, utils (+4 more)

### Community 15 - "Booking & Payment APIs"
Cohesion: 0.22
Nodes (15): bookShow(), bulkCancelShows(), bulkOpenBooking(), bulkRestoreShows(), cancelShow(), createMultipleShows(), createShow(), deleteMultipleShows() (+7 more)

### Community 18 - "Customer Authentication & OTP"
Cohesion: 0.23
Nodes (9): ProfilePage(), ProtectedRoute(), LoginModal(), CustomerAuthContext, CustomerAuthProvider(), useCustomerAuth(), MoviesPage(), OffersPage() (+1 more)

### Community 19 - "Ad Campaign Management"
Cohesion: 0.14
Nodes (13): aliases, lib, ui, iconLibrary, rsc, $schema, tailwind, baseColor (+5 more)

### Community 20 - "Tailwind Module"
Cohesion: 0.14
Nodes (13): aliases, lib, ui, iconLibrary, rsc, $schema, tailwind, baseColor (+5 more)

### Community 22 - "Package Module"
Cohesion: 0.17
Nodes (12): devDependencies, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals, tw-animate-css, @types/node (+4 more)

### Community 24 - "Movie Catalog & TMDB Integration"
Cohesion: 0.17
Nodes (6): debounce(), MovieSearchDropdown(), activeConfig, debounce(), OffersManagement(), scopeConfig

### Community 29 - "Booking & Payment Views"
Cohesion: 0.24
Nodes (8): BookingDetailPage(), fmt(), refundStatusConfig, statusConfig, avatarColor(), avatarColors, getInitials(), paymentStatusConfig

### Community 30 - "Movie Catalog & TMDB Integration"
Cohesion: 0.44
Nodes (9): getTMDBInTheatres(), getTMDBMovieDetails(), getTMDBNowPlaying(), getTMDBPopular(), getTMDBTopRated(), getTMDBUpcoming(), searchTMDB(), tmdbFetch() (+1 more)

### Community 31 - "Movie Catalog & TMDB Integration"
Cohesion: 0.33
Nodes (9): getAllMovies(), getCinemaHallsByLocation(), getCinemaHallsWithShows(), getDistrictsInState(), getMovieById(), getMovieDetailsWithShowtimes(), getMoviesByLocation(), getMoviesByState() (+1 more)

### Community 36 - "Ad Campaign Management"
Cohesion: 0.27
Nodes (9): AdminDetailSheet(), AdminsPage(), avatarColor(), avatarColors, debounce(), fmtDate(), fmtDateTime(), getInitials() (+1 more)

### Community 38 - "Admin UI Components"
Cohesion: 0.29
Nodes (7): FormControl(), FormDescription(), FormFieldContext, FormItemContext, FormLabel(), FormMessage(), useFormField()

### Community 39 - "Movie Catalog & TMDB Integration"
Cohesion: 0.36
Nodes (8): addMovie(), deleteMovie(), editMovie(), getAllMovies(), getMovieById(), getMovieTmdbIds(), updateMovieStatus(), router

### Community 40 - "Ad Campaign Management"
Cohesion: 0.36
Nodes (8): createAd(), deleteAd(), getActiveAds(), getAdClicks(), getAllAds(), recordClick(), updateAd(), router

### Community 42 - "User UI Components"
Cohesion: 0.29
Nodes (7): FormControl(), FormDescription(), FormFieldContext, FormItemContext, FormLabel(), FormMessage(), useFormField()

### Community 45 - "Booking & Payment Views"
Cohesion: 0.25
Nodes (5): ShowsManagement(), MovieDetailsPage(), getNextDates(), SHOW_BORDER_COLOR, STATUS_CONFIG

### Community 46 - "Screen Designer & Seat Layout"
Cohesion: 0.28
Nodes (5): mockNotifications, TopBar(), leftNavItems, rightNavItems, TopNavbar()

### Community 47 - "Movie Catalog & TMDB Integration"
Cohesion: 0.28
Nodes (6): allCities, LocationModal(), POPULAR_CITIES, popularCitiesWithState, stateMap, TheatresPage()

### Community 48 - "Booking & Payment Views"
Cohesion: 0.33
Nodes (5): useRazorpayPayment(), discountLabel(), fmtExpiry(), OfferCard(), OrderSummaryPage()

### Community 51 - "Package Module"
Cohesion: 0.25
Nodes (7): name, private, scripts, dev, lint, type, version

### Community 52 - "Booking & Payment Views"
Cohesion: 0.29
Nodes (4): BookingDetailPage(), fmt(), refundStatusConfig, statusConfig

### Community 55 - "User UI Components"
Cohesion: 0.39
Nodes (6): CarouselContent(), CarouselContext, CarouselItem(), CarouselNext(), CarouselPrevious(), useCarousel()

### Community 56 - "Booking & Payment Views"
Cohesion: 0.33
Nodes (4): avatarColors, debounce(), PaymentOrders(), statusConfig

### Community 57 - "Application Routing & Security Guards"
Cohesion: 0.48
Nodes (5): createHall(), deleteHall(), getMyHalls(), updateHall(), router

### Community 60 - "Booking & Payment Views"
Cohesion: 0.33
Nodes (4): Bookings(), avatarColors, debounce(), statusConfig

### Community 62 - "Ad Campaign Management"
Cohesion: 0.40
Nodes (3): UsersPage(), avatarColors, debounce()

### Community 63 - "Ad Campaign Management"
Cohesion: 0.40
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 70 - "Jsconfig Module"
Cohesion: 0.40
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 79 - "Ad Campaign Management"
Cohesion: 0.50
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 82 - "Jsconfig Module"
Cohesion: 0.50
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 86 - "Admin UI Components"
Cohesion: 0.67
Nodes (3): getPageNumbers(), PAGE_SIZE_OPTIONS, Pagination()

## Knowledge Gaps
- **234 isolated node(s):** `$schema`, `rsc`, `tsx`, `config`, `css` (+229 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Documentation Index` connect `Admin Frontend Dependencies` to `Admin Authentication & Security`, `Customer Authentication & OTP`, `Movie Catalog & TMDB Integration`, `Admin Frontend Dependencies`, `Admin Frontend Dependencies`, `User Frontend Dependencies`, `Booking & Payment APIs`, `Admin Frontend Dependencies`, `Customer Authentication & OTP`, `Booking & Payment APIs`, `Package Dependencies`, `Booking & Payment APIs`, `Admin Frontend Dependencies`, `Customer Authentication & OTP`, `Movie Catalog & TMDB Integration`, `Booking & Payment Views`, `Movie Catalog & TMDB Integration`, `Ad Campaign Management`, `Ad Campaign Management`, `Booking & Payment Views`, `Movie Catalog & TMDB Integration`, `Booking & Payment Views`, `Booking & Payment Views`, `Booking & Payment Views`, `Application Routing & Security Guards`, `Ad Campaign Management`, `Booking & Payment Views`, `Booking & Payment Views`, `Ad Campaign Management`, `Authentication Services`, `Screen Designer & Seat Layout`, `Admin Authentication & Security`?**
  _High betweenness centrality (0.167) - this node is a cross-community bridge._
- **Why does `Backend API Documentation` connect `Admin Frontend Dependencies` to `Customer Authentication & OTP`, `Booking & Payment APIs`, `Admin Frontend Dependencies`, `Customer Authentication & OTP`, `Admin Frontend Dependencies`, `Ad Campaign Management`, `Package Dependencies`, `Booking & Payment APIs`, `Admin Frontend Dependencies`, `Booking & Payment Views`, `Package Module`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Why does `Admin Panel Documentation` connect `Customer Authentication & OTP` to `Admin Authentication & Security`, `Movie Catalog & TMDB Integration`, `Admin Frontend Dependencies`, `Admin Frontend Dependencies`, `User Frontend Dependencies`, `Admin Frontend Dependencies`, `Booking & Payment APIs`, `Admin Frontend Dependencies`, `Admin Frontend Dependencies`, `Movie Catalog & TMDB Integration`, `Booking & Payment Views`, `Ad Campaign Management`, `Booking & Payment Views`, `Screen Designer & Seat Layout`, `Booking & Payment Views`, `Booking & Payment Views`, `Ad Campaign Management`, `Booking & Payment Views`, `Booking & Payment Views`, `Ad Campaign Management`, `Authentication Services`, `Screen Designer & Seat Layout`, `Admin UI Components`?**
  _High betweenness centrality (0.055) - this node is a cross-community bridge._
- **Are the 115 inferred relationships involving `Documentation Index` (e.g. with `components` and `hooks`) actually correct?**
  _`Documentation Index` has 115 INFERRED edges - model-reasoned connections that need verification._
- **Are the 106 inferred relationships involving `Admin Panel Documentation` (e.g. with `components` and `utils`) actually correct?**
  _`Admin Panel Documentation` has 106 INFERRED edges - model-reasoned connections that need verification._
- **Are the 80 inferred relationships involving `User Application Documentation` (e.g. with `components` and `style`) actually correct?**
  _`User Application Documentation` has 80 INFERRED edges - model-reasoned connections that need verification._
- **Are the 59 inferred relationships involving `⚙️ Cinema Hall Management - Admin Panel` (e.g. with `components` and `utils`) actually correct?**
  _`⚙️ Cinema Hall Management - Admin Panel` has 59 INFERRED edges - model-reasoned connections that need verification._