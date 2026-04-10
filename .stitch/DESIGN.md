# Design System: DNGo Market App
**Project ID:** TBD

## 1. Visual Theme & Atmosphere
Fresh, airy, and trustworthy. The atmosphere evokes a clean, modern farmer's market or organic grocery store. It feels efficient for sellers to manage their store while remaining visually tied to the fresh produce identity of the buyer app.

## 2. Color Palette & Roles
* **Primary Fresh Green (#26CD3A):** Used for primary buttons, active toggles, and positive actions (like accepting orders).
* **Deep Forest Green (#1B5E20):** Used for solid headers, strong text emphasis, or primary admin actions.
* **Light Mint Background (#F5F9F6):** A very subtle green-tinted off-white used as the main app background to reduce eye strain.
* **Alert Red (#E53935):** Used for error states, destructive actions (closing store, rejecting orders).
* **Warning Yellow (#FFB300):** Used for low stock warnings or pending statuses.
* **Surface White (#FFFFFF):** Used for cards, containers, and inputs to pop against the light mint background.

## 3. Typography Rules
* Font Family: Modern sans-serif (Inter or similar).
* Headers are bold and legible, emphasizing clarity for data (e.g. Revenue numbers are large and prominent).
* Body text is clean and readable, keeping a professional dashboard feel.

## 4. Component Stylings
* **Cards/Containers:** Softly rounded corners (borderRadius: 16px), background White, with a whisper-soft diffused shadow (blurRadius: 10, opacity 5%).
* **Buttons:** Pill-shaped or generously rounded (borderRadius: 16-20px), solid primary color for main actions.
* **Status Toggles/Badges:** Soft background tint (e.g. 10% opacity of primary color) with solid text color.

## 5. Layout Principles
* Ample whitespace between dashboard widgets.
* Clear grid structures for statistics and KPIs.
* Use section headers that clearly define groups of information (e.g., "Recent Orders", "Inventory Alerts").

## 6. Design System Notes for Stitch Generation
**DESIGN SYSTEM (REQUIRED):**
* Apply a "Fresh & Clean Dashboard" aesthetic.
* Use `#26CD3A` as the primary accent color, with `#F5F9F6` as the overall app background.
* Ensure all cards and containers are white `#FFFFFF` with `16px` border-radius and very faint drop shadows (5% opacity).
* Keep the layout spacious and organized, prioritizing data legibility for a seller dashboard.
