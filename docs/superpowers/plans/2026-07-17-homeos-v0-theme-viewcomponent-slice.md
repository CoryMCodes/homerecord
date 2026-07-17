# HomeOS V0 Theme ViewComponent Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Translate the approved v0 design reference into a local Tailwind 4 token layer and one representative Rails UI slice: `homes/show` with timeline and shared UI primitives.

**Architecture:** Add ViewComponent now, but use it selectively for reusable primitives with variants, slots, conditional rendering, or isolated test value. Keep page composition in ERB templates and page-specific partials. The first implementation slice builds only the components needed by `homes/show`; later screens can adopt the same primitives incrementally.

**Tech Stack:** Rails 8.1, ERB, Hotwire/Turbo, Tailwind CSS 4 via `tailwindcss-rails`, ViewComponent, Minitest.

## Global Constraints

- No React.
- No inline styles.
- Continue using the existing `tailwindcss-rails` Tailwind 4 setup.
- Do not install `shadcn/tailwind.css`.
- Do not install `tw-animate-css` yet.
- Recreate only needed semantic tokens locally in `app/assets/tailwind/application.css`.
- Use Tailwind 4 CSS-first configuration with `@theme inline`.
- Use built-in Tailwind transition and `motion-reduce` utilities for now.
- Do not import dependencies merely because the v0 reference contains them.
- Forest is the default theme.
- Keep the other approved palettes as dormant theme classes for future theme switching.
- Do not build every planned component upfront unless it is needed by this slice.
- Do not convert every fragment into a component.
- Do not write production code until the user approves this plan.

---

## Approved Visual Source

Reference file:

- `docs/design/v0-theme-reference.css`

Production translation rule:

- Treat the reference CSS as visual truth for semantic color relationships and radius.
- Do not copy it wholesale.
- Remove generated-only imports and unrelated shadcn/sidebar/chart tokens.
- Keep reviewed semantic tokens locally.

## Revised Token Decisions

### Default Color Theme

Use `.theme-c-forest` values as `:root` defaults:

| Token | Value | Production Name |
|---|---:|---|
| page background | `#f5f5f1` | `--background` |
| primary text | `#14231c` | `--foreground` |
| surface | `#ffffff` | `--card`, `--popover` |
| primary | `#124a37` | `--primary` |
| primary hover | `#0d3b2c` | `--primary-hover` |
| primary foreground | `#ffffff` | `--primary-foreground` |
| primary soft | `#dfe9e1` | `--accent` |
| secondary soft | `#ebeae3` | `--secondary` |
| muted soft | `#edece6` | `--muted` |
| muted text | `#5c625b` | `--muted-foreground` |
| border/input | `#e4e2da` | `--border`, `--input` |
| focus ring | `#124a37` | `--ring` |

Keep these dormant theme classes for future switching:

- `.theme-warm`
- `.theme-c-blue`
- `.theme-c-terracotta`
- `.theme-c-slate`
- `.theme-c-teal`
- `.theme-c-forest`
- `.theme-c-burgundy`

### Added Production Tokens

Add local tokens that the v0 reference implies but does not define:

- `--primary-soft`: alias to the Forest accent, used for active chips and soft icon backgrounds.
- `--surface`: alias to `--card`, used in component naming when `card` is too specific.
- `--shadow-card`: subtle neutral/forest shadow for timeline cards.
- `--shadow-floating`: stronger shadow for floating primary action.
- `--focus-ring`: `color-mix(in srgb, var(--ring) 35%, transparent)` for focus-visible rings.
- `--app-content-width`: `48rem` for the first mobile-first application column.
- `--app-page-x`: default horizontal shell padding.
- `--app-section-gap`: vertical spacing between header/search/filter/timeline regions.

### Tailwind Integration

Add `@theme inline` mappings to `app/assets/tailwind/application.css`:

```css
@theme inline {
  --color-background: var(--background);
  --color-foreground: var(--foreground);
  --color-card: var(--card);
  --color-card-foreground: var(--card-foreground);
  --color-primary: var(--primary);
  --color-primary-hover: var(--primary-hover);
  --color-primary-foreground: var(--primary-foreground);
  --color-primary-soft: var(--primary-soft);
  --color-secondary: var(--secondary);
  --color-secondary-foreground: var(--secondary-foreground);
  --color-muted: var(--muted);
  --color-muted-foreground: var(--muted-foreground);
  --color-accent: var(--accent);
  --color-accent-foreground: var(--accent-foreground);
  --color-border: var(--border);
  --color-input: var(--input);
  --color-ring: var(--ring);
  --radius-sm: calc(var(--radius) * 0.6);
  --radius-md: calc(var(--radius) * 0.8);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) * 1.4);
  --shadow-card: var(--shadow-card);
  --shadow-floating: var(--shadow-floating);
}
```

Do not add external CSS imports beyond the existing `@import "tailwindcss";`.

## Revised Component Boundaries

### Build In This Slice

These components are needed by `homes/show` and should be built now:

- `Ui::ButtonComponent`
- `Ui::SearchFieldComponent`
- `Ui::FilterNavComponent`
- `Ui::MetadataRowComponent`
- `Ui::EmptyStateComponent`
- `Ui::FloatingActionComponent`
- `Entries::TimelineComponent`
- `Entries::TimelineEntryComponent`

### Defer Unless Needed Later

Keep these as page-level ERB partials for now:

- `app/views/homes/_property_header.html.erb`
- `app/views/homes/_stat_group.html.erb`

Rationale:

- They are tied to `Home` page composition.
- They do not yet need variants, slots, or isolated rendering behavior.
- They may become components later if reused on dashboards, item pages, onboarding, or multiple property contexts.

### Component Responsibilities

`Ui::ButtonComponent`

- Renders links or buttons with semantic variants.
- Variants for this slice: `:primary`, `:secondary`, `:ghost`.
- Sizes for this slice: `:sm`, `:md`, `:icon`.
- Handles disabled state for `<button>` and `aria-disabled` for links.
- Accepts optional icon slot later, but do not build icon machinery in this slice unless needed.

`Ui::SearchFieldComponent`

- Renders a semantic search form.
- Accepts `url:`, `query_param: :q`, `value:`, `placeholder:`.
- For this slice, submit to the current home path as a harmless GET affordance; no search filtering behavior is implemented yet.
- Uses accessible label text with visual hiding.

`Ui::FilterNavComponent`

- Renders nav links/chips with one active item.
- Accepts items shaped as `{ label:, href:, active: }`.
- For this slice, render visual filters for timeline categories without controller filtering.

`Ui::MetadataRowComponent`

- Renders compact label/value pairs or inline metadata items.
- Skips blank values.
- Used by timeline entries and can later be reused by item details.

`Ui::EmptyStateComponent`

- Renders title, body, and optional action slot.
- Used for empty timeline state.

`Ui::FloatingActionComponent`

- Renders fixed-position primary action.
- Accepts `href:`, `label:`, and optional short visual symbol.
- Must include a full accessible label.

`Entries::TimelineComponent`

- Accepts `entries:` and `home:`.
- Renders ordered timeline when entries exist.
- Renders `Ui::EmptyStateComponent` when empty.
- Owns timeline list semantics, not individual entry layout details.

`Entries::TimelineEntryComponent`

- Accepts `entry:`.
- Renders timeline icon, title, date, optional description, optional item metadata, and optional cost/contractor metadata when present later.
- Timeline icon remains internal markup in this slice.

## Proposed File List

### Dependency And Configuration

- Modify: `Gemfile`
  - Add `gem "view_component"`.
- Modify: `Gemfile.lock`
  - Updated by Bundler.
- Modify: `config/application.rb`
  - Optional generator config only:
    - `config.view_component.generate.sidecar = true`
    - `config.view_component.parent_class = "ApplicationComponent"`

### Token Layer

- Modify: `app/assets/tailwind/application.css`
  - Add local Tailwind 4 token layer.
  - Add Forest defaults.
  - Add dormant theme classes.
  - Add base body and focus-visible styles.

### Component Base

- Create: `app/components/application_component.rb`
  - Base class for app components.

### UI Components

- Create: `app/components/ui/button_component.rb`
- Create: `app/components/ui/button_component.html.erb`
- Create: `app/components/ui/search_field_component.rb`
- Create: `app/components/ui/search_field_component.html.erb`
- Create: `app/components/ui/filter_nav_component.rb`
- Create: `app/components/ui/filter_nav_component.html.erb`
- Create: `app/components/ui/metadata_row_component.rb`
- Create: `app/components/ui/metadata_row_component.html.erb`
- Create: `app/components/ui/empty_state_component.rb`
- Create: `app/components/ui/empty_state_component.html.erb`
- Create: `app/components/ui/floating_action_component.rb`
- Create: `app/components/ui/floating_action_component.html.erb`

### Entry Components

- Create: `app/components/entries/timeline_component.rb`
- Create: `app/components/entries/timeline_component.html.erb`
- Create: `app/components/entries/timeline_entry_component.rb`
- Create: `app/components/entries/timeline_entry_component.html.erb`

### Page ERB And Partials

- Modify: `app/views/layouts/application.html.erb`
  - Apply app shell classes and default theme class.
- Modify: `app/views/homes/show.html.erb`
  - Keep page composition here.
  - Render property header partial, stat group partial, search component, filter nav component, timeline component, and floating action component.
- Create: `app/views/homes/_property_header.html.erb`
  - Page-specific home title/address/back navigation.
- Create: `app/views/homes/_stat_group.html.erb`
  - Page-specific home stats.

### Tests

- Create: `test/components/ui/button_component_test.rb`
- Create: `test/components/ui/search_field_component_test.rb`
- Create: `test/components/ui/filter_nav_component_test.rb`
- Create: `test/components/ui/metadata_row_component_test.rb`
- Create: `test/components/ui/empty_state_component_test.rb`
- Create: `test/components/ui/floating_action_component_test.rb`
- Create: `test/components/entries/timeline_component_test.rb`
- Create: `test/components/entries/timeline_entry_component_test.rb`
- Modify: `test/controllers/homes_controller_test.rb`
  - Keep existing semantic assertions.
  - Add or adjust only assertions required by changed semantics, such as `role="search"`, timeline list semantics, and primary action link.

## Task 1: Add ViewComponent Dependency

**Files:**

- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Modify: `config/application.rb`
- Create: `app/components/application_component.rb`

**Interfaces:**

- Produces: `ApplicationComponent < ViewComponent::Base`
- Consumes: Rails view rendering and Minitest.

- [ ] **Step 1: Add the gem**

Run:

```bash
bundle add view_component
```

Expected:

- `Gemfile` includes `gem "view_component"`.
- `Gemfile.lock` includes the resolved ViewComponent version.

- [ ] **Step 2: Add app component base**

Create `app/components/application_component.rb`:

```ruby
class ApplicationComponent < ViewComponent::Base
end
```

- [ ] **Step 3: Configure generators**

In `config/application.rb`, inside the `class Application < Rails::Application` block, add:

```ruby
config.view_component.generate.sidecar = true
config.view_component.parent_class = "ApplicationComponent"
```

- [ ] **Step 4: Verify dependency boots**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected:

- PASS.

## Task 2: Add Local Tailwind Token Layer

**Files:**

- Modify: `app/assets/tailwind/application.css`

**Interfaces:**

- Produces: semantic Tailwind utilities such as `bg-background`, `text-foreground`, `bg-primary`, `hover:bg-primary-hover`, `border-border`, `ring-ring`, `shadow-card`, and `shadow-floating`.
- Consumes: approved color values from `docs/design/v0-theme-reference.css`.

- [ ] **Step 1: Replace bare Tailwind import with reviewed token layer**

Keep the existing import:

```css
@import "tailwindcss";
```

Add `@theme inline`, `:root`, dormant theme classes, and base styles after the import. Default `:root` must use Forest values.

- [ ] **Step 2: Add base accessibility styling**

Add reviewed base styles:

```css
@layer base {
  body {
    @apply bg-background text-foreground antialiased;
  }

  :focus-visible {
    outline: 2px solid var(--focus-ring);
    outline-offset: 3px;
  }
}
```

- [ ] **Step 3: Compile Tailwind through the normal Rails path**

Run:

```bash
bin/rails tailwindcss:build
```

Expected:

- Tailwind build succeeds.
- `app/assets/builds/tailwind.css` updates only with generated output.

## Task 3: Build UI Primitive Components Needed By Homes Show

**Files:**

- Create: `app/components/ui/button_component.rb`
- Create: `app/components/ui/button_component.html.erb`
- Create: `app/components/ui/search_field_component.rb`
- Create: `app/components/ui/search_field_component.html.erb`
- Create: `app/components/ui/filter_nav_component.rb`
- Create: `app/components/ui/filter_nav_component.html.erb`
- Create: `app/components/ui/metadata_row_component.rb`
- Create: `app/components/ui/metadata_row_component.html.erb`
- Create: `app/components/ui/empty_state_component.rb`
- Create: `app/components/ui/empty_state_component.html.erb`
- Create: `app/components/ui/floating_action_component.rb`
- Create: `app/components/ui/floating_action_component.html.erb`

**Interfaces:**

- Produces:
  - `Ui::ButtonComponent.new(label: nil, href: nil, variant: :primary, size: :md, type: "button", disabled: false)`
  - `Ui::SearchFieldComponent.new(url:, value: nil, placeholder: "Search", query_param: :q)`
  - `Ui::FilterNavComponent.new(label:, items:)`
  - `Ui::MetadataRowComponent.new(items:)`
  - `Ui::EmptyStateComponent.new(title:, body: nil)`
  - `Ui::FloatingActionComponent.new(href:, label:, symbol: "+")`

- [ ] **Step 1: Implement `Ui::ButtonComponent`**

Rules:

- Render `<a>` when `href` is present.
- Render `<button>` when `href` is blank.
- Permit only known variants and sizes.
- Raise `ArgumentError` for unknown variants or sizes.
- Use Tailwind classes backed by semantic tokens.

- [ ] **Step 2: Implement `Ui::SearchFieldComponent`**

Rules:

- Render `<form role="search">`.
- Render visually hidden `<label>`.
- Render `<input type="search">`.
- Use `method="get"`.
- Use `name` from `query_param`.

- [ ] **Step 3: Implement `Ui::FilterNavComponent`**

Rules:

- Render `<nav aria-label="...">`.
- Render links for each item.
- Add `aria-current="page"` to the active item.
- Use soft primary styling for active item.

- [ ] **Step 4: Implement `Ui::MetadataRowComponent`**

Rules:

- Skip items with blank values.
- Render no output if all values are blank.
- Render values as plain text by default.

- [ ] **Step 5: Implement `Ui::EmptyStateComponent`**

Rules:

- Render a titled empty state.
- Render body only when provided.
- Render action/content slot only when present.

- [ ] **Step 6: Implement `Ui::FloatingActionComponent`**

Rules:

- Render an accessible fixed-position action link.
- Include visible short symbol and screen-reader-friendly full label.
- Use `shadow-floating`, `bg-primary`, `hover:bg-primary-hover`, and `motion-reduce:transition-none`.

## Task 4: Build Timeline Components

**Files:**

- Create: `app/components/entries/timeline_component.rb`
- Create: `app/components/entries/timeline_component.html.erb`
- Create: `app/components/entries/timeline_entry_component.rb`
- Create: `app/components/entries/timeline_entry_component.html.erb`

**Interfaces:**

- Consumes:
  - `Ui::EmptyStateComponent`
  - `Ui::MetadataRowComponent`
- Produces:
  - `Entries::TimelineComponent.new(entries:, home:)`
  - `Entries::TimelineEntryComponent.new(entry:)`

- [ ] **Step 1: Implement `Entries::TimelineEntryComponent`**

Rules:

- Render each entry inside `<li>`.
- Render title in a heading.
- Render date using `entry.occurred_on.to_fs(:long)`.
- Render description only when present.
- Render item metadata only when `entry.item` is present.
- Keep the timeline icon as internal markup, not a separate component yet.

- [ ] **Step 2: Implement `Entries::TimelineComponent`**

Rules:

- Render `<ol>` when entries exist.
- Render `Entries::TimelineEntryComponent` for each entry.
- Render `Ui::EmptyStateComponent` when entries are empty.
- Preserve existing ordering from the controller; do not sort in the component.

## Task 5: Apply The Representative Homes Show Slice

**Files:**

- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/views/homes/show.html.erb`
- Create: `app/views/homes/_property_header.html.erb`
- Create: `app/views/homes/_stat_group.html.erb`

**Interfaces:**

- Consumes all components from Tasks 3 and 4.
- Keeps page-specific home composition in ERB.

- [ ] **Step 1: Update app shell**

Change layout body/main classes to use:

- `bg-background`
- `text-foreground`
- constrained app width
- responsive padding
- no fixed `mt-28`

- [ ] **Step 2: Add `homes/property_header` partial**

Responsibilities:

- Back link to homes index.
- Home name.
- Optional address.
- Optional home type chip when present.

- [ ] **Step 3: Add `homes/stat_group` partial**

Responsibilities:

- Item count.
- Timeline entry count.
- Last activity date when entries exist.

- [ ] **Step 4: Update `homes/show` composition**

Render, in order:

1. Property header partial.
2. Stat group partial.
3. Search field component.
4. Filter nav component.
5. Timeline component.
6. Existing item actions where appropriate.
7. Floating action component.

Search and filter are visual/semantic affordances in this slice. They do not implement backend search or filtering yet.

## Task 6: Add Focused Component Tests

**Files:**

- Create: `test/components/ui/button_component_test.rb`
- Create: `test/components/ui/search_field_component_test.rb`
- Create: `test/components/ui/filter_nav_component_test.rb`
- Create: `test/components/ui/metadata_row_component_test.rb`
- Create: `test/components/ui/empty_state_component_test.rb`
- Create: `test/components/ui/floating_action_component_test.rb`
- Create: `test/components/entries/timeline_component_test.rb`
- Create: `test/components/entries/timeline_entry_component_test.rb`
- Modify: `test/controllers/homes_controller_test.rb`

**Interfaces:**

- Consumes `ViewComponent::TestCase` and `render_inline`.

- [ ] **Step 1: Test button variants and semantics**

Assertions:

- Link variant renders `<a href="...">`.
- Button variant renders `<button type="...">`.
- Primary variant includes semantic primary classes.
- Unknown variant raises `ArgumentError`.

- [ ] **Step 2: Test search field semantics**

Assertions:

- Renders `form[role='search']`.
- Renders `input[type='search'][name='q']`.
- Renders accessible label.

- [ ] **Step 3: Test filter nav active state**

Assertions:

- Renders `nav[aria-label='Timeline filters']`.
- Active item has `aria-current="page"`.
- Inactive items do not.

- [ ] **Step 4: Test metadata row conditional rendering**

Assertions:

- Blank values are skipped.
- Component renders no wrapper when all values are blank.

- [ ] **Step 5: Test empty state slot and text**

Assertions:

- Title renders.
- Body renders only when provided.
- Optional action slot renders.

- [ ] **Step 6: Test floating action semantics**

Assertions:

- Renders link with expected href.
- Accessible label is present.
- Visual symbol does not replace accessible text.

- [ ] **Step 7: Test timeline entry rendering**

Assertions:

- Title renders.
- Long date renders.
- Description renders only when present.
- Linked item metadata renders when present.

- [ ] **Step 8: Test timeline empty and populated states**

Assertions:

- Empty timeline renders empty state.
- Populated timeline renders one `<li>` per entry.
- Timeline preserves input order.

- [ ] **Step 9: Update controller/view semantics test**

Keep current behavior assertions in `test/controllers/homes_controller_test.rb`, and add focused assertions for:

- `form[role='search']`
- `nav[aria-label='Timeline filters']`
- `ol` timeline entries still render newest first
- existing item links remain reachable

## Task 7: Verification

**Files:**

- No new files.

**Interfaces:**

- Verifies the full slice.

- [ ] **Step 1: Run component tests**

Run:

```bash
bin/rails test test/components
```

Expected:

- PASS.

- [ ] **Step 2: Run affected controller tests**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected:

- PASS.

- [ ] **Step 3: Run full test suite**

Run:

```bash
bin/rails test
```

Expected:

- PASS.

- [ ] **Step 4: Run RuboCop**

Run:

```bash
bin/rubocop
```

Expected:

- PASS.

- [ ] **Step 5: Start local server for visual QA**

Run:

```bash
bin/dev
```

Expected:

- App starts.
- `homes/show` renders with Forest default theme.
- Timeline, search field, filters, metadata, and floating action are visible and do not overlap at mobile or desktop widths.

## Self-Review

- Spec coverage: Covers ViewComponent adoption, selective boundaries, Tailwind 4 token layer, Forest default, dormant future themes, no shadcn/tw-animate imports, homes/show slice, timeline, shared primitives, and focused component tests.
- Placeholder scan: No `TBD`, `TODO`, or unresolved implementation placeholders remain.
- Scope check: This is one coherent slice. It intentionally defers item pages, auth pages, real search behavior, real filter behavior, animation dependencies, and theme switching UI.
- Component boundary check: Page-specific `homes/property_header` and `homes/stat_group` stay as partials. Shared variant-heavy primitives and timeline rendering become ViewComponents.

