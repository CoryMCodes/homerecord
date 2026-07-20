# Home-Scoped Search Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Turbo Native friendly current-home search surface for entries, items, and entry attachment filenames.

**Architecture:** Add a nested `SearchesController#show` endpoint that renders results into a Turbo Frame. Keep matching in `HomeSearch`, with grouped results and a narrow interface that can later switch to PostgreSQL full-text ranking.

**Tech Stack:** Rails 8.1, PostgreSQL, ERB, Turbo, Stimulus, Tailwind CSS, Importmap, Active Storage, Minitest.

## Global Constraints

- Search only the current home.
- Do not search home name or address.
- Search entries, items, and entry attachment filenames only.
- Attachment search is filename-only; no OCR, PDF text extraction, image text extraction, semantic search, or attachment content indexing.
- Result clicks use normal Rails links to entry and item detail pages.
- Keep UI server-rendered and Turbo Native friendly.
- Escape SQL wildcard characters and cap query length before matching.

---

## File Structure

- `config/routes.rb`: add the nested singular search route under homes.
- `app/controllers/searches_controller.rb`: load the scoped home, run `HomeSearch`, and render results.
- `app/models/home_search.rb`: normalize query text and return grouped entry, item, and attachment filename matches.
- `app/views/searches/show.html.erb`: full endpoint response with the results frame.
- `app/views/searches/_results.html.erb`: grouped floating-panel result markup.
- `app/components/ui/search_field_component.rb`: allow Turbo Frame and Stimulus data attributes.
- `app/components/ui/search_field_component.html.erb`: render a GET form targeting the results frame.
- `app/javascript/controllers/search_panel_controller.js`: debounce input, submit the form, and close on click-away/Escape.
- `app/javascript/controllers/index.js`: register the controller through the existing eager loader.
- `app/views/homes/show.html.erb`: wrap the search field and results frame in the floating-panel Stimulus surface.
- `test/models/home_search_test.rb`: query object behavior.
- `test/controllers/searches_controller_test.rb`: endpoint behavior, result grouping, authorization, and links.
- `test/controllers/homes_controller_test.rb`: verify the timeline search frame wiring.

### Task 1: Search Query Object

**Files:**
- Create: `app/models/home_search.rb`
- Create: `test/models/home_search_test.rb`

**Interfaces:**
- Consumes: `Home`, `Entry`, `Item`, Active Storage attachments.
- Produces: `HomeSearch.new(home:, query:).results`, where `results.entries`, `results.items`, `results.attachment_matches`, `results.query`, and `results.any?` are available.

- [ ] **Step 1: Write the failing tests**

Create `test/models/home_search_test.rb` with tests for blank query, entry fields, item fields, attachment filename matching, home scoping, wildcard escaping, and query truncation.

- [ ] **Step 2: Run the focused test**

Run: `bin/rails test test/models/home_search_test.rb`

Expected: fails because `HomeSearch` is not defined.

- [ ] **Step 3: Implement `HomeSearch`**

Create `app/models/home_search.rb` with:

```ruby
class HomeSearch
  MAX_QUERY_LENGTH = 80
  LIMIT_PER_GROUP = 5
  Result = Data.define(:query, :entries, :items, :attachment_matches) do
    def any?
      entries.any? || items.any? || attachment_matches.any?
    end
  end
  AttachmentMatch = Data.define(:entry, :filename)

  def initialize(home:, query:)
    @home = home
    @query = query.to_s.strip.first(MAX_QUERY_LENGTH)
  end

  def results
    return Result.new(query: query, entries: Entry.none, items: Item.none, attachment_matches: []) if query.blank?

    Result.new(
      query: query,
      entries: matching_entries,
      items: matching_items,
      attachment_matches: matching_attachment_matches
    )
  end

  private

  attr_reader :home, :query
end
```

Fill in private matching methods using escaped `ILIKE` patterns and home-scoped relations.

- [ ] **Step 4: Run the focused test**

Run: `bin/rails test test/models/home_search_test.rb`

Expected: passes.

### Task 2: Search Endpoint and Result Markup

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/searches_controller.rb`
- Create: `app/views/searches/show.html.erb`
- Create: `app/views/searches/_results.html.erb`
- Create: `test/controllers/searches_controller_test.rb`

**Interfaces:**
- Consumes: `HomeSearch.new(home:, query:).results`.
- Produces: `home_search_path(@home)` and grouped result links.

- [ ] **Step 1: Write the failing controller tests**

Create tests that assert the endpoint renders a Turbo Frame, blocks cross-account homes, renders entry and item links, renders attachment filename links to the owning entry, and returns an empty state for no matches.

- [ ] **Step 2: Run the focused test**

Run: `bin/rails test test/controllers/searches_controller_test.rb`

Expected: fails because the route/controller do not exist.

- [ ] **Step 3: Implement route, controller, and views**

Add the nested route:

```ruby
resource :search, only: :show
```

Create `SearchesController#show`:

```ruby
class SearchesController < ApplicationController
  def show
    @home = current_account.homes.find(params[:home_id])
    @results = HomeSearch.new(home: @home, query: params[:q]).results
  end
end
```

Render results inside `turbo_frame_tag "home_search_results"`, grouped by entries, items, and attachments.

- [ ] **Step 4: Run the focused test**

Run: `bin/rails test test/controllers/searches_controller_test.rb`

Expected: passes.

### Task 3: Turbo/Stimulus Search Surface

**Files:**
- Modify: `app/components/ui/search_field_component.rb`
- Modify: `app/components/ui/search_field_component.html.erb`
- Create: `app/javascript/controllers/search_panel_controller.js`
- Modify: `app/views/homes/show.html.erb`
- Modify: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: `home_search_path(@home)` and `home_search_results` frame.
- Produces: a floating results panel under the search bar that closes on click-away or Escape.

- [ ] **Step 1: Write the failing controller/component assertions**

Update `test/controllers/homes_controller_test.rb` to assert the search form targets `home_search_results`, submits to `home_search_path(@home)`, and renders an initially empty `turbo-frame#home_search_results`.

- [ ] **Step 2: Run the focused test**

Run: `bin/rails test test/controllers/homes_controller_test.rb`

Expected: fails because the search form still targets the home timeline.

- [ ] **Step 3: Implement component and view wiring**

Update `Ui::SearchFieldComponent` to accept `turbo_frame:` and `data:`. In `homes/show`, wrap the search form and frame in a positioned Stimulus container and point the form to `home_search_path(@home)`.

- [ ] **Step 4: Add Stimulus controller**

Create `search_panel_controller.js` with targets for form, input, and panel. Debounce input, call `requestSubmit`, open the panel for nonblank queries, close on click-away, and close on Escape.

- [ ] **Step 5: Run the focused test**

Run: `bin/rails test test/controllers/homes_controller_test.rb`

Expected: passes.

### Task 4: Verification

**Files:**
- All files touched by Tasks 1-3.

- [ ] **Step 1: Run search-related tests**

Run: `bin/rails test test/models/home_search_test.rb test/controllers/searches_controller_test.rb test/controllers/homes_controller_test.rb`

Expected: passes.

- [ ] **Step 2: Run full Rails test suite**

Run: `bin/rails test`

Expected: passes.

- [ ] **Step 3: Run RuboCop**

Run: `bin/rubocop`

Expected: passes.
