# CineMax Design System

Welcome to the CineMax design system reference. This document specifies the design tokens, visual assets, interactive states, and component guidelines used to create a consistent, premium, and theme-adaptive web experience across the CineMax platform.

---

## 🎨 Color System

CineMax leverages the modern OKLCH color space for system tokens (allowing precise light/dark mode variations without losing chroma consistency) combined with standard hexadecimal branding highlights.

### 1. Brand Accents
Used for prominent highlight elements, active badges, and core visual action buttons (inspired by BookMyShow).
*   **Brand Red/Pink (Default)**: `#f84464`
*   **Brand Red/Pink (Hover)**: `#e23655`
*   **Brand Red/Pink (Active)**: `#c92844`
*   **Brand Red Shadow/Glow**: `rgba(248, 68, 100, 0.2)`

### 2. Theme Token Values

| Token | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| `--background` | `oklch(0.98 0.01 240)` *(Light bluish-gray)* | `oklch(0.14 0.01 240)` *(Navy black)* |
| `--foreground` | `oklch(0.15 0.01 240)` *(Deep gray text)* | `oklch(0.98 0.01 240)` *(Off-white text)* |
| `--primary` | `oklch(0.6 0.2 10)` *(Cinema red)* | `oklch(0.68 0.2 10)` *(Vibrant cinema red)* |
| `--secondary` | `oklch(0.9 0.02 250)` *(Soft blue)* | `oklch(0.3 0.02 240)` *(Cool gray-blue)* |
| `--accent` | `oklch(71.87% 0.00008 271.15)` | `oklch(53.12% 0.00006 271.15)` |
| `--card` | `oklch(0.96 0.008 240)` | `oklch(0.18 0.01 240)` |
| `--border` | `oklch(0.85 0.01 250)` | `oklch(1 0 0 / 10%)` |

### 3. Seat Status Color Coding
*   **Available Seat**: Faint outline. Light border with light gray text in light theme; dark border with zinc text in dark theme.
    *   *Hover*: Brand red outline + border, 5% opacity brand red background.
*   **Selected Seat**: High-contrast emerald green (`bg-emerald-500`) with active border-b and glowing outer shadow.
*   **Sold/Held Seat**: Muted gray base with 35% opacity. Non-interactive.

---

## 🔤 Typography

*   **Primary Font Family**: `'JetBrains Mono Variable', monospace` (imported via `@fontsource-variable/jetbrains-mono`)
*   **Heading Styles**: Bold tracking, line-height 1.2, weight 600+.
    *   `h1`: `font-size: clamp(2rem, 5vw, 3.5rem);`
    *   `h2`: `font-size: clamp(1.5rem, 4vw, 2.5rem);`
    *   `h3`: `font-size: clamp(1.25rem, 3vw, 2rem);`

---

## 🕹️ Interactive States & Custom Hover Rules

Interactive elements have specific transition animations to ensure smooth visual response.

### 1. General Transition
*   Class: `.transition-all`
*   CSS: `transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);`
*   Hover Lift (`.hover-lift`): Translates `-2px` vertically and applies a soft shadow.

### 2. Global Button Hover Separation (`index.css`)
Global hover overrides are split between default (light) and dark modes to avoid color contrast issues:

#### Default/Light Mode:
```css
button.border:not(.bg-emerald-500):not(.custom-hover):hover,
button:not(.bg-primary):not(.bg-destructive):not(.bg-secondary):not(.bg-emerald-500):not(.custom-hover):hover {
  background-color: rgba(0, 0, 0, 0.05) !important;
  color: var(--foreground) !important;
  border-color: rgba(0, 0, 0, 0.12) !important;
}
```

#### Dark Mode:
```css
.dark button.border:not(.bg-emerald-500):not(.custom-hover):hover,
.dark button:not(.bg-primary):not(.bg-destructive):not(.bg-secondary):not(.bg-emerald-500):not(.custom-hover):hover {
  background-color: rgba(255, 255, 255, 0.08) !important;
  color: #ffffff !important;
  border-color: rgba(255, 255, 255, 0.25) !important;
}
```

### 3. Brand CTA Buttons (`.custom-hover`)
Buttons that leverage the brand red color scheme (`bg-[#f84464]`) **must** include the `.custom-hover` class to avoid global outline/ghost override matches, allowing their specific brand transitions to run:
*   *Hover state*: `hover:bg-[#e23655] hover:scale-[1.02] active:scale-[0.98] shadow-lg shadow-[#f84464]/20 hover:shadow-[#f84464]/35`

---

## 🏗️ Structure & Layout Guidelines

### 1. Glassmorphism (`.glass-effect`)
Utilized for top headers, modals, floating panels, and sidebars.
*   **CSS Rules**:
    ```css
    backdrop-filter: blur(12px) saturate(180%);
    background: oklch(from var(--card) l c h / 0.8);
    border: 1px solid oklch(from var(--border) l c h / 0.3);
    ```

### 2. Physical 3D Seat Styling
Seats are represented as 3D theater chairs:
*   Rounded top corners (`rounded-t-md`) + subtle rounded bottom corners (`rounded-b-[3px]`).
*   Thicker bottom border cushion representing the seat fold (`border-b-2`).

### 3. Curved Screen & Projector Glow
*   Screen: A curved top border representing the silver screen curvature (`rounded-[50%/10px_10px_0_0]`).
*   Projector Light: Fading vertical gradient light cone casting downwards (`bg-gradient-to-b from-blue-400/12 via-blue-400/3 to-transparent blur-md`).

### 4. Floating Checkout Dock
*   Fixed at the bottom of the viewport (`fixed bottom-5 left-1/2 -translate-x-1/2`).
*   Uses a wide container (`w-[calc(100%-2rem)] max-w-4xl`) with frosted glass backing, selected seat list text tags, and a brand red CTA.
