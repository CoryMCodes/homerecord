# Home-Scoped Search Design

## Goal

Build the MVP search slice for HouseOS: an authenticated user can search the current home's entries, items, and entry attachment filenames from the home timeline, then tap a result to navigate to the matching record.

This intentionally reflects the MVP product constraint that the app allows one home. Search should stay inside the current home context and should not search home names or addresses.

## Scope

Search includes:

- entry title
- entry description
- entry contractor/vendor name
- item name
- item brand
- item model number
- item serial number
- entry attachment filenames

Search excludes:

- home name
- home address
- global account-wide results
- OCR
- PDF text extraction
- image text extraction
- semantic search
- saved searches
- searching attachment file contents

Attachment search means filename matching only. A matching attachment result should navigate to the owning entry detail page.

## Architecture

Add a home-nested search endpoint:

```ruby
resources :homes, only: %i[index new create show] do
  resource :search, only: :show
  resources :items, only: %i[index new create show edit update]
  resources :entries, only: %i[new create show]
end
```

The endpoint is `GET /homes/:home_id/search?q=...`. It loads the home through `current_account.homes.find(params[:home_id])` and returns a Turbo Frame friendly result partial.

Search logic should live outside the controller in a small query object, `HomeSearch`, initialized with `home:` and `query:`. The object should expose:

```ruby
HomeSearch.new(home: @home, query: params[:q]).results
```

The returned result object should have grouped collections for entries, items, and attachment filename matches. Keeping this boundary small lets the matching internals move from simple SQL to PostgreSQL full-text ranking later without rewriting the controller or view.

## Matching Behavior

The MVP matching implementation should use Rails/PostgreSQL primitives and avoid additional search infrastructure.

Behavior:

- Blank or whitespace-only queries return empty groups.
- Queries are normalized by trimming whitespace.
- Matching is case-insensitive.
- Entry matches search title, description, and contractor/vendor name.
- Item matches search name, brand, model number, and serial number.
- Attachment matches search Active Storage blob filenames attached to entries in the current home.
- Results are scoped to the selected home only.
- Results do not include records from another account, because the controller loads the home through the current account.

Ranking can stay simple for MVP:

- entries ordered by `occurred_on DESC, id DESC`
- items ordered by `name ASC, id ASC`
- attachment matches ordered by entry recency and filename

## User Experience

The existing search field near the top of the home timeline becomes a floating result surface.

Interaction:

- Typing into the search field requests `home_search_path(@home, q: query)`.
- Results render in a floating panel directly underneath the search bar.
- The panel opens only when there is a nonblank query.
- Clicking outside the search area closes the panel.
- Pressing Escape closes the panel.
- Clicking a result uses a normal link and navigates to that result's detail page.
- Entry results link to `home_entry_path(@home, entry)`.
- Item results link to `home_item_path(@home, item)`.
- Attachment filename results link to `home_entry_path(@home, entry)`.

The UI should remain server-rendered and Turbo Native friendly. Result clicks should be ordinary anchor navigation so the native shell gets predictable navigation behavior, history, refresh, and back handling.

## Stimulus

Add one focused Stimulus controller for the search surface.

Responsibilities:

- observe input changes
- debounce requests
- submit the GET request into a Turbo Frame
- open the floating panel when the query is nonblank
- close the panel on click-away
- close the panel on Escape

The controller should not own search matching, result rendering, or navigation. Those stay in Rails.

## Turbo

Wrap result content in a stable Turbo Frame rendered beneath the search field. The search form should target this frame.

The endpoint should render only the frame content when called from the search field. Full-page navigation to the search endpoint is not a primary UX path, but it should still return a valid response rather than raising.

## Components

Update `Ui::SearchFieldComponent` rather than duplicating markup in `homes/show`.

The component should gain optional configuration for:

- Turbo Frame target
- Stimulus controller attributes
- autocomplete behavior

Add a separate partial or component for search results if the markup grows beyond a small partial. Keep repeated result row markup simple and accessible.

## Error Handling

The search endpoint should not raise for blank queries. Blank queries return an empty frame.

Malformed or very long user input should be treated as text. SQL wildcard characters must be escaped so `%` and `_` do not become unbounded wildcard searches. Queries should be length-limited before matching to keep requests cheap.

## Performance

MVP performance should be reasonable without introducing Elasticsearch, OpenSearch, Redis, background indexing, OCR, or semantic search.

Use database-side filtering, select only scoped records, and keep limits per group. Add a clear query length cap and per-group result limits so the floating panel stays fast on mobile.

PostgreSQL full-text search tuning remains a roadmap item. The `HomeSearch` object is the boundary for adding generated `tsvector` columns or ranking later.

## Testing

Add controller/model-level tests for:

- blank queries return no results
- entry title matches
- entry description matches
- contractor/vendor matches
- item name matches
- item brand/model/serial matches
- attachment filename matches the owning entry
- cross-home records do not appear
- cross-account homes are blocked
- unsupported wildcard characters are escaped as plain text

Add UI/controller tests for:

- the home timeline renders a search form targeting the search frame
- result links point to entry and item detail pages
- attachment filename results point to the owning entry page

Stimulus click-away behavior can be covered with a focused system test if the existing system test setup is already reliable. If not, controller/component coverage is enough for this MVP slice.

## Out Of Scope

- replacing the home timeline with full search pages
- global search
- multi-home grouping
- attachment content indexing
- background indexing
- typeahead suggestions unrelated to actual results
- separate JSON API
