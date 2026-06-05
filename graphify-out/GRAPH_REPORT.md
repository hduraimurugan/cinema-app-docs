# Graph Report - cinema-hall  (2026-06-05)

## Corpus Check
- 252 files · ~198,630 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1569 nodes · 2560 edges · 166 communities (152 shown, 14 thin omitted)
- Extraction: 78% EXTRACTED · 22% INFERRED · 0% AMBIGUOUS · INFERRED: 558 edges (avg confidence: 0.85)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 85|Community 85]]
- [[_COMMUNITY_Community 86|Community 86]]
- [[_COMMUNITY_Community 87|Community 87]]
- [[_COMMUNITY_Community 88|Community 88]]
- [[_COMMUNITY_Community 90|Community 90]]
- [[_COMMUNITY_Community 91|Community 91]]
- [[_COMMUNITY_Community 92|Community 92]]
- [[_COMMUNITY_Community 94|Community 94]]
- [[_COMMUNITY_Community 125|Community 125]]
- [[_COMMUNITY_Community 126|Community 126]]
- [[_COMMUNITY_Community 127|Community 127]]
- [[_COMMUNITY_Community 128|Community 128]]
- [[_COMMUNITY_Community 129|Community 129]]
- [[_COMMUNITY_Community 130|Community 130]]
- [[_COMMUNITY_Community 131|Community 131]]
- [[_COMMUNITY_Community 132|Community 132]]
- [[_COMMUNITY_Community 133|Community 133]]
- [[_COMMUNITY_Community 134|Community 134]]
- [[_COMMUNITY_Community 135|Community 135]]
- [[_COMMUNITY_Community 136|Community 136]]
- [[_COMMUNITY_Community 137|Community 137]]
- [[_COMMUNITY_Community 138|Community 138]]
- [[_COMMUNITY_Community 139|Community 139]]
- [[_COMMUNITY_Community 140|Community 140]]
- [[_COMMUNITY_Community 141|Community 141]]
- [[_COMMUNITY_Community 142|Community 142]]
- [[_COMMUNITY_Community 143|Community 143]]
- [[_COMMUNITY_Community 144|Community 144]]
- [[_COMMUNITY_Community 145|Community 145]]
- [[_COMMUNITY_Community 146|Community 146]]
- [[_COMMUNITY_Community 147|Community 147]]
- [[_COMMUNITY_Community 148|Community 148]]
- [[_COMMUNITY_Community 149|Community 149]]
- [[_COMMUNITY_Community 150|Community 150]]
- [[_COMMUNITY_Community 151|Community 151]]
- [[_COMMUNITY_Community 152|Community 152]]
- [[_COMMUNITY_Community 153|Community 153]]
- [[_COMMUNITY_Community 154|Community 154]]
- [[_COMMUNITY_Community 156|Community 156]]
- [[_COMMUNITY_Community 157|Community 157]]
- [[_COMMUNITY_Community 158|Community 158]]
- [[_COMMUNITY_Community 159|Community 159]]
- [[_COMMUNITY_Community 160|Community 160]]
- [[_COMMUNITY_Community 161|Community 161]]
- [[_COMMUNITY_Community 162|Community 162]]
- [[_COMMUNITY_Community 163|Community 163]]
- [[_COMMUNITY_Community 164|Community 164]]
- [[_COMMUNITY_Community 165|Community 165]]

## God Nodes (most connected - your core abstractions)
1. `useAuth()` - 26 edges
2. `useCustomerAuth()` - 25 edges
3. `hashToken()` - 18 edges
4. `Admin Panel Documentation` - 18 edges
5. `Concurrency-Safe Seat Booking - Implementation Plan` - 17 edges
6. `useHall()` - 15 edges
7. `2. Screen Designer` - 14 edges
8. `Authentication System` - 13 edges
9. `2. Movie Management` - 13 edges
10. `Cinema Hall Ticket Booking App - Documentation` - 13 edges

## Surprising Connections (you probably didn't know these)
- `MoviePage()` --calls--> `getYouTubeEmbedUrl()`  [INFERRED]
  cinema-hall-admin/src/pages/MoviePage.jsx → cinema-hall-users/src/pages/MovieInfoPage.jsx
- `MovieDetailsPage()` --calls--> `getNextDates()`  [INFERRED]
  cinema-hall-users/src/pages/MovieDetailsPage.jsx → cinema-hall-admin/src/pages/ShowsManagement.jsx
- `TheatresPage()` --calls--> `getNextDates()`  [INFERRED]
  cinema-hall-users/src/pages/TheatresPage.jsx → cinema-hall-admin/src/pages/ShowsManagement.jsx
- `SettingsPage()` --calls--> `useAuth()`  [INFERRED]
  cinema-hall-admin/src/pages/SettingsPage.jsx → cinema-hall-admin/src/context/AuthContext.jsx
- `MoviePage()` --calls--> `formatDate()`  [INFERRED]
  cinema-hall-admin/src/pages/MoviePage.jsx → cinema-hall-admin/src/pages/AdsManagement.jsx

## Import Cycles
- None detected.

## Communities (166 total, 14 thin omitted)

### Community 1 - "Community 1"
Cohesion: 0.16
Nodes (28): changePassword(), forgotPassword(), getAdminSecurity(), getAdminSecurityLogs(), getAllAdmins(), getCinemaAdminMe(), getLockDuration(), LOCKOUT_THRESHOLDS (+20 more)

### Community 2 - "Community 2"
Cohesion: 0.07
Nodes (23): debounce(), SearchMovies(), LANG_OPTIONS, SECTIONS, TMDB_GENRE_MAP, TMDBBrowser(), EMPTY_FORM, formatDate() (+15 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (43): dependencies, class-variance-authority, clsx, cmdk, country-state-city, date-fns, @fontsource-variable/jetbrains-mono, framer-motion (+35 more)

### Community 4 - "Community 4"
Cohesion: 0.10
Nodes (20): execArgs, ext, ignore, watch, crons, rewrites, version, 1. Generate bcrypt hash (+12 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (40): dependencies, class-variance-authority, clsx, cmdk, country-state-city, date-fns, embla-carousel-autoplay, embla-carousel-react (+32 more)

### Community 6 - "Community 6"
Cohesion: 0.10
Nodes (22): pool, allowedOrigins, app, appStartTime, getAllCustomers(), getDashboardStats(), getRefundByBooking(), getRefunds() (+14 more)

### Community 7 - "Community 7"
Cohesion: 0.18
Nodes (5): showsAPI, PASSWORD_POLICY_CHECKS, LoginModal(), SeatSelectionPage(), customerAuthAPI

### Community 8 - "Community 8"
Cohesion: 0.07
Nodes (39): components, style, files, dayjs, leaflet, qrcode.react, react-lazy-load-image-component, recharts (+31 more)

### Community 9 - "Community 9"
Cohesion: 0.17
Nodes (19): createOffer(), deleteOffer(), getActiveOffers(), getAllCinemaHalls(), getAllOffers(), getOfferById(), updateOffer(), validateOffer() (+11 more)

### Community 11 - "Community 11"
Cohesion: 0.17
Nodes (12): devDependencies, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals, tw-animate-css, @types/node (+4 more)

### Community 12 - "Community 12"
Cohesion: 0.18
Nodes (11): dependencies, chalk, cookie-parser, cors, dotenv, jsonwebtoken, nodemailer, pg (+3 more)

### Community 13 - "Community 13"
Cohesion: 0.15
Nodes (19): cleanupExpiredHolds(), confirmBooking(), getBookingByPaymentId(), getBookingDetails(), getCinemaHallBookings(), getMyBookings(), holdSeats(), releaseSeats() (+11 more)

### Community 14 - "Community 14"
Cohesion: 0.12
Nodes (16): aliases, hooks, lib, ui, utils, react, tailwindcss, build (+8 more)

### Community 15 - "Community 15"
Cohesion: 0.19
Nodes (17): bookShow(), bulkCancelShows(), bulkOpenBooking(), bulkRestoreShows(), cancelShow(), createMultipleShows(), createShow(), deleteMultipleShows() (+9 more)

### Community 18 - "Community 18"
Cohesion: 0.21
Nodes (11): ProtectedRoute(), allCities, LocationModal(), POPULAR_CITIES, popularCitiesWithState, stateMap, useCustomerAuth(), MovieDetailsPage() (+3 more)

### Community 19 - "Community 19"
Cohesion: 0.18
Nodes (10): iconLibrary, rsc, $schema, tailwind, baseColor, config, css, cssVariables (+2 more)

### Community 20 - "Community 20"
Cohesion: 0.18
Nodes (10): iconLibrary, rsc, $schema, tailwind, baseColor, config, css, cssVariables (+2 more)

### Community 22 - "Community 22"
Cohesion: 0.13
Nodes (11): AuthPage(), FEATURES, slideVariants, STATS, viewIndexes, ForgotPasswordForm(), LoginForm(), RegisterForm() (+3 more)

### Community 24 - "Community 24"
Cohesion: 0.50
Nodes (4): activeConfig, debounce(), OffersManagement(), scopeConfig

### Community 29 - "Community 29"
Cohesion: 0.24
Nodes (8): BookingDetailPage(), fmt(), refundStatusConfig, statusConfig, avatarColor(), avatarColors, getInitials(), paymentStatusConfig

### Community 30 - "Community 30"
Cohesion: 0.44
Nodes (9): getTMDBInTheatres(), getTMDBMovieDetails(), getTMDBNowPlaying(), getTMDBPopular(), getTMDBTopRated(), getTMDBUpcoming(), searchTMDB(), tmdbFetch() (+1 more)

### Community 31 - "Community 31"
Cohesion: 0.36
Nodes (8): addMovie(), deleteMovie(), editMovie(), getAllMovies(), getMovieById(), getMovieTmdbIds(), updateMovieStatus(), router

### Community 36 - "Community 36"
Cohesion: 0.27
Nodes (9): AdminDetailSheet(), AdminsPage(), avatarColor(), avatarColors, debounce(), fmtDate(), fmtDateTime(), getInitials() (+1 more)

### Community 38 - "Community 38"
Cohesion: 0.29
Nodes (7): FormControl(), FormDescription(), FormFieldContext, FormItemContext, FormLabel(), FormMessage(), useFormField()

### Community 39 - "Community 39"
Cohesion: 0.08
Nodes (12): showsAPI, EMPTY_FORM, avatarColors, refundStatusConfig, historyColorClass, formatTime(), ShowPage(), STATUS_CONFIG (+4 more)

### Community 40 - "Community 40"
Cohesion: 0.36
Nodes (8): createAd(), deleteAd(), getActiveAds(), getAdClicks(), getAllAds(), recordClick(), updateAd(), router

### Community 42 - "Community 42"
Cohesion: 0.29
Nodes (7): FormControl(), FormDescription(), FormFieldContext, FormItemContext, FormLabel(), FormMessage(), useFormField()

### Community 45 - "Community 45"
Cohesion: 0.07
Nodes (29): 1. [Backend API Documentation](./backend.md), 2. [Admin Panel Documentation](./admin.md), 3. [Database Setup Script](./db_setup.sql), 4. [User Application Documentation](./users.md), 5. [Graphify Knowledge Graph](./graphify-out/), Admin Features, Backend, Backend Features (+21 more)

### Community 46 - "Community 46"
Cohesion: 0.08
Nodes (24): Admin Authentication (`/api/auth`), Admin Authentication Flow, API Endpoints, Authentication System, Backend API Documentation, Constraints, Customer Authentication Flow, Data Types (+16 more)

### Community 47 - "Community 47"
Cohesion: 0.17
Nodes (16): PASSWORD_POLICY_CHECKS, changePasswordCustomer(), forgotPasswordCustomer(), _generateAndSendOtp(), getCustomerMe(), getLockDuration(), LOCKOUT_THRESHOLDS, loginCustomer() (+8 more)

### Community 48 - "Community 48"
Cohesion: 0.12
Nodes (17): 10. Backend: Register Payment Routes, 11. Frontend: Razorpay Checkout Integration, 12. Frontend: Payment Component, 13. Frontend: Add Razorpay Script, 7. Backend: Payment Controller, 8. Database: Payment Orders Table, 9. Backend: Payment Routes, Environment Variables (+9 more)

### Community 51 - "Community 51"
Cohesion: 0.25
Nodes (7): name, private, scripts, dev, lint, type, version

### Community 52 - "Community 52"
Cohesion: 0.29
Nodes (4): BookingDetailPage(), fmt(), refundStatusConfig, statusConfig

### Community 55 - "Community 55"
Cohesion: 0.39
Nodes (6): CarouselContent(), CarouselContext, CarouselItem(), CarouselNext(), CarouselPrevious(), useCarousel()

### Community 56 - "Community 56"
Cohesion: 0.33
Nodes (4): avatarColors, debounce(), PaymentOrders(), statusConfig

### Community 57 - "Community 57"
Cohesion: 0.48
Nodes (5): createHall(), deleteHall(), getMyHalls(), updateHall(), router

### Community 58 - "Community 58"
Cohesion: 0.29
Nodes (4): ShowsManagement(), getNextDates(), SHOW_BORDER_COLOR, STATUS_CONFIG

### Community 59 - "Community 59"
Cohesion: 0.36
Nodes (5): useRazorpayPayment(), discountLabel(), fmtExpiry(), OfferCard(), OrderSummaryPage()

### Community 60 - "Community 60"
Cohesion: 0.33
Nodes (4): Bookings(), avatarColors, debounce(), statusConfig

### Community 62 - "Community 62"
Cohesion: 0.33
Nodes (4): UsersPage(), avatarColors, debounce(), customersAPI

### Community 63 - "Community 63"
Cohesion: 0.40
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 70 - "Community 70"
Cohesion: 0.40
Nodes (4): compilerOptions, baseUrl, paths, @/*

### Community 71 - "Community 71"
Cohesion: 0.12
Nodes (17): 1. `migration_idempotency.sql` (NEW), 2. `controllers/payment.Controller.js` (MODIFIED), 3. `routes/payment.routes.js` (MODIFIED), 4. `server.js` (MODIFIED), 5. `hooks/useRazorpayPayment.js` (MODIFIED), Fix 1 — `createOrder`: Dedup active orders, Fix 2 — `verifyPayment`: Idempotency guard, Fix 3 — `handleWebhook`: Event deduplication table (+9 more)

### Community 72 - "Community 72"
Cohesion: 0.09
Nodes (30): App(), CinemaLayout(), ProfilePage(), SettingsPage(), ProtectedRoute(), AppSidebar(), managementItems, navigationItems (+22 more)

### Community 79 - "Community 79"
Cohesion: 0.33
Nodes (5): compilerOptions, baseUrl, paths, @/*, references

### Community 82 - "Community 82"
Cohesion: 0.33
Nodes (5): compilerOptions, baseUrl, paths, @/*, references

### Community 85 - "Community 85"
Cohesion: 0.19
Nodes (7): generateOtp(), hashOtp(), sendOtp(), verifyOtp(), sendCustomerOtpEmail(), transporter, router

### Community 86 - "Community 86"
Cohesion: 0.67
Nodes (3): getPageNumbers(), PAGE_SIZE_OPTIONS, Pagination()

### Community 94 - "Community 94"
Cohesion: 0.17
Nodes (12): devDependencies, eslint, @eslint/js, eslint-plugin-react-hooks, eslint-plugin-react-refresh, globals, tw-animate-css, @types/node (+4 more)

### Community 125 - "Community 125"
Cohesion: 0.14
Nodes (11): name, private, scripts, dev, lint, type, version, __dirname (+3 more)

### Community 126 - "Community 126"
Cohesion: 0.13
Nodes (15): 2. Movie Management, Add / Edit Movie — Right-Side Sheet, Available Genres, Available Languages, Browse Movies Tab, Cast Management UI, Feature Overview, Feature Overview (+7 more)

### Community 127 - "Community 127"
Cohesion: 0.14
Nodes (14): 2. Screen Designer, Aisle System, Feature Overview, Feature Overview, Interactive Features, Layout Designer Workflow, Navigation Pattern, Rows/Columns Resize Behaviour (+6 more)

### Community 128 - "Community 128"
Cohesion: 0.15
Nodes (13): 1. System Architecture, 2. Module Dependency Structure, 3. Frontend/Backend Communication Flow, 4. Shared Components, 5. Authentication Flows, 6. Data Flows, A. Concurrency-Safe Seat Hold and Ticket Booking, B. Show Cancellation and Refund Flow (+5 more)

### Community 129 - "Community 129"
Cohesion: 0.17
Nodes (12): 1. Clone the repository, 2. Install dependencies, 3. Setup the Database Schema, 4. Running the Server, 📘 API Documentation, 🎬 Cinema Hall Ticket Booking System - Backend API Service, Development Mode (with hot reloading via Nodemon), 📂 Directory Structure (+4 more)

### Community 130 - "Community 130"
Cohesion: 0.17
Nodes (12): Complete Payment Flow, Concurrency Handling, Concurrency-Safe Seat Booking - Implementation Plan, Core Principle, Implementation Order, Problem Statement, Security Checklist, Solution Architecture (+4 more)

### Community 131 - "Community 131"
Cohesion: 0.18
Nodes (11): 4. Additional Features, BookingDetailPage, Bookings, Customers, Hall Admins, HomePage, PaymentOrders, ProfilePage (+3 more)

### Community 132 - "Community 132"
Cohesion: 0.14
Nodes (14): 1. Database Schema Changes, 2. Backend: New Booking Controller, 3. Backend: Booking Routes, 4. Backend: Register Routes, 5. Backend: Background Cleanup Job, 6. Frontend: API Service, Migration SQL (for existing data), [MODIFY] [api.js](file:///d:/Users/Duraimurugan%20H/Git%20Cloned/My%20Projects/cinema-hall/cinema-hall-users/src/services/api.js) (+6 more)

### Community 133 - "Community 133"
Cohesion: 0.20
Nodes (10): 1. Install Dependencies, 2. Start Development Server, 3. Build for Production, 4. Preview Production Build Locally, 📘 Admin Documentation, ⚙️ Cinema Hall Management - Admin Panel, 🔑 Environment Setup, 🚀 Execution Instructions (+2 more)

### Community 134 - "Community 134"
Cohesion: 0.25
Nodes (7): HomePage(), ChartTooltip(), fmt(), fmtRupee(), greeting(), statusConfig, dashboardAPI

### Community 135 - "Community 135"
Cohesion: 0.20
Nodes (9): author, keywords, license, main, name, scripts, dev, type (+1 more)

### Community 136 - "Community 136"
Cohesion: 0.20
Nodes (10): 1. Install Dependencies include peer dependencies, 2. Start Development Server, 3. Build for Production, 4. Preview Production Build Locally, 🎟️ Cinema Hall Ticket Booking - Customer Web App, 🎨 Core Features, 🔑 Environment Setup, 🚀 Execution Instructions (+2 more)

### Community 137 - "Community 137"
Cohesion: 0.18
Nodes (11): 2. Ads Management (SuperAdmin Only), Ad Placements, Ads Tab (Card Grid), Analytics Tab (Table), Click-through Details Modal, Create / Edit Ad — Right-Side Sheet, Create/Edit Form Fields, Export — Ads Management (+3 more)

### Community 138 - "Community 138"
Cohesion: 0.18
Nodes (11): 3. Shows Management, Add Multiple Shows Page (`/shows/bulk`), Add Show Page (`/shows/new`), Confirm Dialog (`AlertDialog`), Edit Show Page (`/shows/:id/edit`), Feature Overview, Feature Overview, Movie Search Component (+3 more)

### Community 139 - "Community 139"
Cohesion: 0.12
Nodes (16): Admin Panel Documentation, Application Architecture, Best Practices Implemented, Cloudinary Integration, Component Hierarchy, Context Providers, Environment Variables, Future Enhancements (+8 more)

### Community 140 - "Community 140"
Cohesion: 0.22
Nodes (9): AuthContext State Management, Authentication Flow, Authentication System, ForgotPasswordPage, Protected Routes, RegisterPage, RegisterPage, ResetPasswordPage (+1 more)

### Community 141 - "Community 141"
Cohesion: 0.25
Nodes (8): 1. Offers Management (SuperAdmin Only), Date Picker Implementation Note, Export — Offers Management, Feature Overview, Offer Form Fields, Offer Form Page Layout (`/offers/new`, `/offers/:id/edit`), Sidebar Navigation, Table Columns

### Community 142 - "Community 142"
Cohesion: 0.25
Nodes (8): Application Architecture, Authentication System, Component Hierarchy, Customer Authentication Flow, Forgot Password Flow, Overview, Route Structure, User Application Documentation

### Community 143 - "Community 143"
Cohesion: 0.33
Nodes (3): razorpay, razorpay, razorpay

### Community 144 - "Community 144"
Cohesion: 0.48
Nodes (5): createScreen(), deleteScreen(), editScreen(), getMyScreens(), router

### Community 145 - "Community 145"
Cohesion: 0.33
Nodes (6): 0. Dashboard (All Admins), Features Documentation, KPI Cards, Recent Bookings, Revenue Trend Chart, Today's Shows

### Community 146 - "Community 146"
Cohesion: 0.33
Nodes (6): API Configuration, API Service Layer, Error Handling, Export — Shared Utility, Pagination — Shared Component, Service Modules

### Community 147 - "Community 147"
Cohesion: 0.33
Nodes (6): Booking Success Page, Data displayed, Download Ticket, Flow, Seat Label Derivation, Why query param instead of location.state?

### Community 148 - "Community 148"
Cohesion: 0.53
Nodes (6): 1. Onboarding Page (`/onboarding`), 2. Hall Guard (`HallGuard.jsx`), 3. Hall Switcher (`HallSwitcher.jsx`), 4. Halls Management (`/halls`), Multi-Hall Support & Onboarding Flow, VerifyEmailPage

### Community 150 - "Community 150"
Cohesion: 0.21
Nodes (7): debounce(), SearchMovies(), mockNotifications, TopBar(), leftNavItems, rightNavItems, TopNavbar()

### Community 151 - "Community 151"
Cohesion: 0.22
Nodes (3): ProfilePage(), getYouTubeEmbedUrl(), MovieInfoPage()

### Community 152 - "Community 152"
Cohesion: 0.50
Nodes (4): Add Multiple Shows Workflow, Complete Show Creation Workflow, Screen Designer Workflow, User Workflows

### Community 153 - "Community 153"
Cohesion: 0.50
Nodes (4): Build & Deployment, Deployment, Development, Production Build

### Community 154 - "Community 154"
Cohesion: 0.29
Nodes (3): ThemeContext, CustomerAuthContext, CustomerAuthProvider()

### Community 156 - "Community 156"
Cohesion: 0.33
Nodes (6): 1. LoginForm (`LoginForm.jsx`), 2. RegisterForm (`RegisterForm.jsx`), 3. ForgotPasswordForm (`ForgotPasswordForm.jsx`), 4. VerifyEmailForm (`VerifyEmailForm.jsx`), 5. ResetPasswordForm (`ResetPasswordForm.jsx`), Sub-Form Reference

### Community 157 - "Community 157"
Cohesion: 0.67
Nodes (3): Custom Components, shadcn/ui Components Used, UI Components

### Community 158 - "Community 158"
Cohesion: 0.67
Nodes (3): Dark Mode Support, Styling & Theming, Tailwind Configuration

### Community 159 - "Community 159"
Cohesion: 0.67
Nodes (3): Debouncing, Lazy Loading, Performance Optimizations

### Community 160 - "Community 160"
Cohesion: 0.50
Nodes (4): AuthPage (Unified Authentication Page), Mobile Responsiveness Features, Motion Graphics Transitions, Unified Split Layout

### Community 162 - "Community 162"
Cohesion: 0.67
Nodes (3): Automated Testing, Manual Verification, Verification Plan

### Community 163 - "Community 163"
Cohesion: 0.67
Nodes (3): Razorpay Dashboard Setup, Testing Webhooks Locally, Webhook Configuration

## Knowledge Gaps
- **498 isolated node(s):** `$schema`, `rsc`, `tsx`, `config`, `css` (+493 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **14 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Admin Panel Documentation` connect `Community 139` to `Community 8`, `Community 140`, `Community 145`, `Community 146`, `Community 152`, `Community 153`, `Community 157`, `Community 158`, `Community 159`?**
  _High betweenness centrality (0.139) - this node is a cross-community bridge._
- **Why does `Features Documentation` connect `Community 145` to `Community 131`, `Community 137`, `Community 138`, `Community 139`, `Community 141`, `Community 126`, `Community 127`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **Why does `Concurrency-Safe Seat Booking - Implementation Plan` connect `Community 130` to `Community 162`, `Community 163`, `Community 132`, `Community 8`, `Community 48`, `Community 147`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `dependencies` (e.g. with `README.md` and `README.md`) actually correct?**
  _`dependencies` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `dependencies` (e.g. with `README.md` and `README.md`) actually correct?**
  _`dependencies` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `dependencies` (e.g. with `README.md` and `README.md`) actually correct?**
  _`dependencies` has 5 INFERRED edges - model-reasoned connections that need verification._
- **What connects `$schema`, `rsc`, `tsx` to the rest of the system?**
  _498 weakly-connected nodes found - possible documentation gaps or missing edges._