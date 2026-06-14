# Graph Report - docs  (2026-06-14)

## Corpus Check
- 8 files · ~54,275 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 554 nodes · 561 edges · 40 communities (38 shown, 2 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `046cc6a9`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 126|Community 126]]
- [[_COMMUNITY_Community 127|Community 127]]
- [[_COMMUNITY_Community 128|Community 128]]
- [[_COMMUNITY_Community 129|Community 129]]
- [[_COMMUNITY_Community 131|Community 131]]
- [[_COMMUNITY_Community 132|Community 132]]
- [[_COMMUNITY_Community 133|Community 133]]
- [[_COMMUNITY_Community 137|Community 137]]
- [[_COMMUNITY_Community 138|Community 138]]
- [[_COMMUNITY_Community 139|Community 139]]
- [[_COMMUNITY_Community 140|Community 140]]
- [[_COMMUNITY_Community 142|Community 142]]
- [[_COMMUNITY_Community 164|Community 164]]
- [[_COMMUNITY_Community 165|Community 165]]

## God Nodes (most connected - your core abstractions)
1. `Admin Panel Documentation` - 19 edges
2. `Concurrency-Safe Seat Booking - Implementation Plan` - 18 edges
3. `User Application Documentation` - 18 edges
4. `2. Screen Designer` - 15 edges
5. `2. Movie Management` - 14 edges
6. `Cinema Hall Ticket Booking App - Documentation` - 14 edges
7. `Progress` - 14 edges
8. `Authentication System` - 13 edges
9. `4. Additional Pages` - 13 edges
10. `2. Ads Management (SuperAdmin Only)` - 12 edges

## Surprising Connections (you probably didn't know these)
- None detected - all connections are within the same source files.

## Import Cycles
- None detected.

## Communities (40 total, 2 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (39): 1. Movie Browsing, 2. Authentication Modal, 2a. Forgot Password Page, 3. Top Navigation Bar, 3b. Secondary Navigation Bar, 4. Additional Pages, AdBanner Component, Auto-Open Login Modal (Protected Route Redirect) (+31 more)

### Community 1 - "Community 1"
Cohesion: 0.11
Nodes (17): Adding New Tests, Cleanup Rules, Concurrency Test, Controller Test (Real DB), Coverage, Database, Detailed Test Case Reference, Factories (+9 more)

### Community 2 - "Community 2"
Cohesion: 0.18
Nodes (11): Admin Authentication (`/api/auth`), GET `/api/auth/security`, GET `/api/auth/verify-email?token=<token>`, PATCH `/api/auth/hall`, POST `/api/auth/change-password`, POST `/api/auth/forgot-password`, POST `/api/auth/login`, POST `/api/auth/logout-all` (+3 more)

### Community 3 - "Community 3"
Cohesion: 0.29
Nodes (7): adsAPI, API Request Flow, API Service Layer, customerAuthAPI, customerMoviesAPI, Service Modules, settingsAPI

### Community 4 - "Community 4"
Cohesion: 0.33
Nodes (6): Authentication System, Customer Authentication Flow, CustomerAuthContext State, Forgot Password Flow, Google OAuth Flow, OTP Verification Process

### Community 5 - "Community 5"
Cohesion: 0.40
Nodes (5): 2. Movie Info Page, 3. Movie Shows Page, Complete Signup & Login Flow, Movie Discovery Flow, User Workflows

### Community 6 - "Community 6"
Cohesion: 0.50
Nodes (4): API Error Handling, Empty States, Error Handling, Loading States

### Community 7 - "Community 7"
Cohesion: 0.50
Nodes (4): Build & Deployment, Deployment, Development, Production Build

### Community 8 - "Community 8"
Cohesion: 0.50
Nodes (4): Dark Mode, Responsive Design, Styling & Theming, Tailwind Configuration

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (30): Adding New Tests, Cinema Hall API — Test Suite, Configuration (`vitest.config.js`), Controllers (Real DB), Database, Factories, Fixes Applied, Key Finding — holdSeats Locking Gap (+22 more)

### Community 10 - "Community 10"
Cohesion: 0.50
Nodes (4): Horizontal Scrolling, Lazy Loading Images, Memoization, Performance Optimizations

### Community 11 - "Community 11"
Cohesion: 0.67
Nodes (3): Application Architecture, Component Hierarchy, Route Structure

### Community 12 - "Community 12"
Cohesion: 0.67
Nodes (3): Custom Components, shadcn/ui Components Used, UI Components

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (25): Adding New Tests, Cinema Hall API — Test Suite Guide, Cleanup Rules, Concurrency Test Pattern, Configuration (`vitest.config.js`), Controller Test (Real DB), Coverage Report, Database (+17 more)

### Community 40 - "Community 40"
Cohesion: 0.08
Nodes (23): Cinema Hall API — Bug Report, CRIT-1: `ANY(b.seats)` Fails on JSONB Arrays, CRIT-2: JS Array Passed as JSONB Without Serialization, CRIT-3: Missing `payment_signature` Column in Schema, CRIT-4: Non-Unique Index on `bookings(payment_id)` Prevents `ON CONFLICT`, 🔴 Critical (Data Integrity), FACTORY-1: `createScreen` Wrong Column Name, FACTORY-2: `createMovie` Type Mismatch (JSONB → text[]) (+15 more)

### Community 45 - "Community 45"
Cohesion: 0.06
Nodes (31): 1. [Backend API Documentation](./backend.md), 2. [Admin Panel Documentation](./admin.md), 3. [Database Setup Script](./db_setup.sql), 4. [User Application Documentation](./users.md), 5. [Graphify Knowledge Graph](./graphify-out/), 5. [Test Suite Documentation](./backend_tests.md), 6. [Graphify Knowledge Graph](./graphify-out/), Admin Features (+23 more)

### Community 46 - "Community 46"
Cohesion: 0.09
Nodes (30): 1. Generate bcrypt hash, 2. Insert in pgAdmin / psql, Account Linking Rules, Admin Authentication Flow, API Endpoints, Authentication System, Backend API Documentation, Constraints (+22 more)

### Community 48 - "Community 48"
Cohesion: 0.12
Nodes (17): 10. Backend: Register Payment Routes, 11. Frontend: Razorpay Checkout Integration, 12. Frontend: Payment Component, 13. Frontend: Add Razorpay Script, 7. Backend: Payment Controller, 8. Database: Payment Orders Table, 9. Backend: Payment Routes, Environment Variables (+9 more)

### Community 71 - "Community 71"
Cohesion: 0.05
Nodes (41): 1. `migration_idempotency.sql` (NEW), 2. `controllers/payment.Controller.js` (MODIFIED), 3. `routes/payment.routes.js` (MODIFIED), 4. `server.js` (MODIFIED), 5. `hooks/useRazorpayPayment.js` (MODIFIED), Automated Testing, Booking Success Page, Complete Payment Flow (+33 more)

### Community 126 - "Community 126"
Cohesion: 0.12
Nodes (16): 2. Movie Management, Add / Edit Movie — Right-Side Sheet, Available Genres, Available Languages, Browse Movies Tab, Cast Management UI, Feature Overview, Feature Overview (+8 more)

### Community 127 - "Community 127"
Cohesion: 0.13
Nodes (15): 2. Screen Designer, Aisle System, Feature Overview, Feature Overview, Feature Overview, Interactive Features, Layout Designer Workflow, Navigation Pattern (+7 more)

### Community 128 - "Community 128"
Cohesion: 0.14
Nodes (13): 1. System Architecture, 2. Module Dependency Structure, 3. Frontend/Backend Communication Flow, 4. Shared Components, 5. Authentication Flows, 6. Data Flows, A. Concurrency-Safe Seat Hold and Ticket Booking, B. Show Cancellation and Refund Flow (+5 more)

### Community 129 - "Community 129"
Cohesion: 0.15
Nodes (12): 1. Clone the repository, 2. Install dependencies, 3. Setup the Database Schema, 4. Running the Server, 📘 API Documentation, 🎬 Cinema Hall Ticket Booking System - Backend API Service, Development Mode (with hot reloading via Nodemon), 📂 Directory Structure (+4 more)

### Community 131 - "Community 131"
Cohesion: 0.08
Nodes (25): 0. Dashboard (All Admins), 1. Offers Management (SuperAdmin Only), 4. Additional Features, BookingDetailPage, Bookings, Customers, Date Picker Implementation Note, Export — Offers Management (+17 more)

### Community 132 - "Community 132"
Cohesion: 0.14
Nodes (14): 1. Database Schema Changes, 2. Backend: New Booking Controller, 3. Backend: Booking Routes, 4. Backend: Register Routes, 5. Backend: Background Cleanup Job, 6. Frontend: API Service, Migration SQL (for existing data), [MODIFY] [api.js](file:///d:/Users/Duraimurugan%20H/Git%20Cloned/My%20Projects/cinema-hall/cinema-hall-users/src/services/api.js) (+6 more)

### Community 133 - "Community 133"
Cohesion: 0.07
Nodes (24): 1. Install Dependencies, 2. Start Development Server, 3. Build for Production, 4. Preview Production Build Locally, 📘 Admin Documentation, ⚙️ Cinema Hall Management - Admin Panel, 🔑 Environment Setup, 🚀 Execution Instructions (+16 more)

### Community 137 - "Community 137"
Cohesion: 0.17
Nodes (12): 2. Ads Management (SuperAdmin Only), Ad Placements, Ads Tab (Card Grid), Analytics Tab (Table), Click-through Details Modal, Create / Edit Ad — Right-Side Sheet, Create/Edit Form Fields, Export — Ads Management (+4 more)

### Community 138 - "Community 138"
Cohesion: 0.17
Nodes (12): 3. Shows Management, Add Multiple Shows Page (`/shows/bulk`), Add Show Page (`/shows/new`), Confirm Dialog (`AlertDialog`), Edit Show Page (`/shows/:id/edit`), Feature Overview, Feature Overview, Feature Overview (+4 more)

### Community 139 - "Community 139"
Cohesion: 0.05
Nodes (39): Add Multiple Shows Workflow, Admin Panel Documentation, API Configuration, API Service Layer, Application Architecture, Best Practices Implemented, Build & Deployment, Cloudinary Integration (+31 more)

### Community 140 - "Community 140"
Cohesion: 0.09
Nodes (26): 1. LoginForm (`LoginForm.jsx`), 1. Onboarding Page (`/onboarding`), 2. Hall Guard (`HallGuard.jsx`), 2. RegisterForm (`RegisterForm.jsx`), 3. ForgotPasswordForm (`ForgotPasswordForm.jsx`), 3. Hall Switcher (`HallSwitcher.jsx`), 4. Halls Management (`/halls`), 4. VerifyEmailForm (`VerifyEmailForm.jsx`) (+18 more)

### Community 142 - "Community 142"
Cohesion: 0.20
Nodes (9): Accessibility, Best Practices Implemented, Context Providers, Environment Variables, Future Enhancements, Implemented Features, Overview, State Management (+1 more)

## Knowledge Gaps
- **396 isolated node(s):** `Overview`, `Route Structure`, `Component Hierarchy`, `Authentication Flow`, `AuthContext State Management` (+391 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Admin Panel Documentation` connect `Community 139` to `Community 131`, `Community 140`, `Community 133`?**
  _High betweenness centrality (0.255) - this node is a cross-community bridge._
- **Why does `User Application Documentation` connect `Community 142` to `Community 0`, `Community 3`, `Community 4`, `Community 133`, `Community 6`, `Community 7`, `Community 8`, `Community 5`, `Community 10`, `Community 11`, `Community 12`?**
  _High betweenness centrality (0.180) - this node is a cross-community bridge._
- **Why does `Features Documentation` connect `Community 131` to `Community 137`, `Community 138`, `Community 139`, `Community 126`, `Community 127`?**
  _High betweenness centrality (0.166) - this node is a cross-community bridge._
- **What connects `Overview`, `Route Structure`, `Component Hierarchy` to the rest of the system?**
  _396 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05128205128205128 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.1111111111111111 - nodes in this community are weakly interconnected._
- **Should `Community 9` be split into smaller, more focused modules?**
  _Cohesion score 0.06451612903225806 - nodes in this community are weakly interconnected._