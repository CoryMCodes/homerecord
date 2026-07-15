# Home Creation Timeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let an authenticated user create a home, save it under the current account, and land on that home's timeline.

**Architecture:** Keep the slice in the existing Rails homes resource. `HomesController` owns `index`, `new`, `create`, and `show`; all reads and writes go through `current_account.homes`. `homes#show` becomes the first timeline surface by loading the selected home and its entries in newest-first order.

**Tech Stack:** Ruby 3.4+, Rails 8.1, ERB, Minitest, Rails fixtures.

## Global Constraints

- Use `Home`, not `House` or `Property`.
- Use standard Rails resource routes: `resources :homes, only: %i[index new create show]`.
- Home fields in this slice are exactly `name`, optional `address`, and optional `home_type`.
- `home_type` values come from `Home::HOME_TYPES`: `house`, `condo`, `apartment`, `rental`, `other`.
- Home creation must be scoped through `current_account.homes`.
- Home lookup must remain scoped through `current_account.homes.find(params[:id])`.
- Successful home creation redirects to `home_path(@home)`.
- Invalid home creation renders `homes/new` with `422 Unprocessable Entity`.
- `homes#show` is the home timeline page.
- Timeline entries render newest first using `occurred_on` descending with a stable secondary order.
- Entry creation UI, item creation UI, attachments, search, account switching, invite UI, bottom dock navigation, polished mobile design, and Hotwire Native behavior are out of scope.

---

## File Structure

- Modify: `config/routes.rb`
  - Add `new` and `create` to the homes resource.
- Modify: `app/controllers/homes_controller.rb`
  - Add `new`, `create`, and private `home_params`.
  - Keep `index` and `show` scoped through `current_account`.
  - Load timeline entries in `show`.
- Modify: `app/views/homes/index.html.erb`
  - Add a create-home link for both populated and empty states.
- Create: `app/views/homes/new.html.erb`
  - Render the first home form and validation errors.
- Modify: `app/views/homes/show.html.erb`
  - Present the home as a timeline page.
  - Render entries newest first and show an empty state when none exist.
- Modify: `test/controllers/homes_controller_test.rb`
  - Add controller/integration tests for home creation, validation failure, timeline order, and empty timeline state.

---

### Task 1: Home Creation Flow

**Files:**
- Modify: `test/controllers/homes_controller_test.rb`
- Modify: `config/routes.rb`
- Modify: `app/controllers/homes_controller.rb`
- Modify: `app/views/homes/index.html.erb`
- Create: `app/views/homes/new.html.erb`

**Interfaces:**
- Consumes: `current_account` from `ApplicationController`, `Home::HOME_TYPES`, and `sign_in_as(user)` from `test/test_helpers/session_test_helper.rb`.
- Produces: `new_home_path`, `homes_path` accepting `POST`, `HomesController#new`, `HomesController#create`, and a private `HomesController#home_params` method permitting `:name`, `:address`, and `:home_type`.

- [ ] **Step 1: Write failing tests for the creation flow**

Replace `test/controllers/homes_controller_test.rb` with:

```ruby
require "test_helper"

class HomesControllerTest < ActionDispatch::IntegrationTest
  test "shows a home in the current account" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h1", "Main Home"
  end

  test "does not show a home from another account" do
    sign_in_as users(:owner)

    get home_url(homes(:other))

    assert_response :not_found
  end

  test "shows the new home form" do
    sign_in_as users(:owner)

    get new_home_url

    assert_response :success
    assert_select "h1", "Add a home"
    assert_select "form[action='#{homes_path}'][method='post']"
    assert_select "input[name='home[name]']"
    assert_select "textarea[name='home[address]']"
    assert_select "select[name='home[home_type]']"
  end

  test "creates a home in the current account and redirects to its timeline" do
    sign_in_as users(:owner)

    assert_difference -> { Home.count }, 1 do
      post homes_url, params: {
        home: {
          name: "Lake House",
          address: "9 Lake Road",
          home_type: "house"
        }
      }
    end

    home = Home.order(:created_at).last
    assert_equal accounts(:household), home.account
    assert_equal "Lake House", home.name
    assert_equal "9 Lake Road", home.address
    assert_equal "house", home.home_type
    assert_redirected_to home_url(home)

    follow_redirect!

    assert_response :success
    assert_select "h1", "Lake House"
  end

  test "does not create an invalid home" do
    sign_in_as users(:owner)

    assert_no_difference -> { Home.count } do
      post homes_url, params: {
        home: {
          name: "",
          address: "9 Lake Road",
          home_type: "house"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Add a home"
    assert_select "[role='alert']", /Name can't be blank/
  end
end
```

- [ ] **Step 2: Run the focused controller test to verify it fails**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: FAIL because `new_home_url` is not defined or `GET /homes/new` is not routable.

- [ ] **Step 3: Add the homes routes**

Edit `config/routes.rb` to:

```ruby
Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index new create show]

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
```

- [ ] **Step 4: Add the controller actions and strong params**

Edit `app/controllers/homes_controller.rb` to:

```ruby
class HomesController < ApplicationController
  def index
    @homes = current_account.homes.order(:name)
  end

  def new
    @home = current_account.homes.build
  end

  def create
    @home = current_account.homes.build(home_params)

    if @home.save
      redirect_to home_path(@home)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @home = current_account.homes.find(params[:id])
  end

  private

  def home_params
    params.require(:home).permit(:name, :address, :home_type)
  end
end
```

- [ ] **Step 5: Update the homes index with create-home links**

Edit `app/views/homes/index.html.erb` to:

```erb
<% content_for :title, "Homes" %>

<section>
  <h1>Homes</h1>

  <% if @homes.any? %>
    <p><%= link_to "Add a home", new_home_path %></p>

    <ul>
      <% @homes.each do |home| %>
        <li><%= link_to home.name, home_path(home) %></li>
      <% end %>
    </ul>
  <% else %>
    <p>No homes yet.</p>
    <p><%= link_to "Add your first home", new_home_path %></p>
  <% end %>
</section>
```

- [ ] **Step 6: Add the new home form**

Create `app/views/homes/new.html.erb` with:

```erb
<% content_for :title, "Add a home" %>

<section>
  <h1>Add a home</h1>

  <% if @home.errors.any? %>
    <div role="alert">
      <p>Please check the home details.</p>

      <ul>
        <% @home.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <%= form_with model: @home do |form| %>
    <div>
      <%= form.label :name %>
      <%= form.text_field :name, required: true, autofocus: true %>
    </div>

    <div>
      <%= form.label :address %>
      <%= form.text_area :address, rows: 3 %>
    </div>

    <div>
      <%= form.label :home_type, "Home type" %>
      <%= form.select :home_type, options_for_select(Home::HOME_TYPES.map { |home_type| [home_type.humanize, home_type] }, @home.home_type), include_blank: true %>
    </div>

    <%= form.submit "Create home" %>
  <% end %>
</section>
```

- [ ] **Step 7: Run the focused controller test to verify the creation flow passes**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: PASS for the creation-flow tests. Timeline-order tests are not present until Task 2.

- [ ] **Step 8: Commit Task 1**

Run:

```bash
git add config/routes.rb app/controllers/homes_controller.rb app/views/homes/index.html.erb app/views/homes/new.html.erb test/controllers/homes_controller_test.rb
git commit -m "Add home creation flow"
```

Expected: commit succeeds.

---

### Task 2: Home Timeline Rendering

**Files:**
- Modify: `test/controllers/homes_controller_test.rb`
- Modify: `app/controllers/homes_controller.rb`
- Modify: `app/views/homes/show.html.erb`

**Interfaces:**
- Consumes: `@home` from `HomesController#show`, `@home.entries`, and existing `entries(:move_in)` and `entries(:water_heater_replacement)` fixtures.
- Produces: `@timeline_entries`, an `ActiveRecord::Relation` ordered by `occurred_on: :desc` and `id: :desc`, rendered by `app/views/homes/show.html.erb`.

- [ ] **Step 1: Write failing timeline tests**

Append these tests inside `HomesControllerTest` in `test/controllers/homes_controller_test.rb`, before the final `end`:

```ruby
  test "shows timeline entries newest first" do
    sign_in_as users(:owner)

    get home_url(homes(:main))

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "ol li", 2

    timeline_titles = css_select("ol li h3").map(&:text)
    assert_equal [ "Replaced water heater", "Moved in" ], timeline_titles
  end

  test "shows an empty timeline state when the home has no entries" do
    sign_in_as users(:owner)
    home = accounts(:household).homes.create!(name: "Empty Home")

    get home_url(home)

    assert_response :success
    assert_select "h2", "Timeline"
    assert_select "p", "No timeline entries yet."
    assert_select "ol li", 0
  end
```

- [ ] **Step 2: Run the focused controller test to verify it fails**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: FAIL because `homes#show` does not render a `Timeline` heading, timeline list, or empty timeline state.

- [ ] **Step 3: Load timeline entries in the controller**

Edit `app/controllers/homes_controller.rb` to:

```ruby
class HomesController < ApplicationController
  def index
    @homes = current_account.homes.order(:name)
  end

  def new
    @home = current_account.homes.build
  end

  def create
    @home = current_account.homes.build(home_params)

    if @home.save
      redirect_to home_path(@home)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @home = current_account.homes.find(params[:id])
    @timeline_entries = @home.entries.order(occurred_on: :desc, id: :desc)
  end

  private

  def home_params
    params.require(:home).permit(:name, :address, :home_type)
  end
end
```

- [ ] **Step 4: Render the home timeline page**

Edit `app/views/homes/show.html.erb` to:

```erb
<% content_for :title, @home.name %>

<section>
  <p><%= link_to "Homes", homes_path %></p>

  <h1><%= @home.name %></h1>

  <% if @home.address.present? %>
    <p><%= @home.address %></p>
  <% end %>

  <h2>Timeline</h2>

  <% if @timeline_entries.any? %>
    <ol>
      <% @timeline_entries.each do |entry| %>
        <li>
          <h3><%= entry.title %></h3>
          <p><%= entry.occurred_on.to_fs(:long) %></p>

          <% if entry.description.present? %>
            <p><%= entry.description %></p>
          <% end %>
        </li>
      <% end %>
    </ol>
  <% else %>
    <p>No timeline entries yet.</p>
  <% end %>
</section>
```

- [ ] **Step 5: Run the focused controller test to verify timeline rendering passes**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

Run:

```bash
git add app/controllers/homes_controller.rb app/views/homes/show.html.erb test/controllers/homes_controller_test.rb
git commit -m "Show home timeline entries"
```

Expected: commit succeeds.

---

### Task 3: Full Verification

**Files:**
- Verify: `config/routes.rb`
- Verify: `app/controllers/homes_controller.rb`
- Verify: `app/views/homes/index.html.erb`
- Verify: `app/views/homes/new.html.erb`
- Verify: `app/views/homes/show.html.erb`
- Verify: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: completed Task 1 and Task 2 commits.
- Produces: passing focused tests and passing full test suite for this slice.

- [ ] **Step 1: Run the focused homes controller test**

Run:

```bash
bin/rails test test/controllers/homes_controller_test.rb
```

Expected: PASS.

- [ ] **Step 2: Run the full Rails test suite**

Run:

```bash
bin/rails test
```

Expected: PASS.

- [ ] **Step 3: Run style checks**

Run:

```bash
bin/rubocop
```

Expected: PASS.

- [ ] **Step 4: Inspect git status**

Run:

```bash
git status --short
```

Expected: no unstaged or staged changes after Task 1 and Task 2 commits.

- [ ] **Step 5: Record verification in the final response**

Report:

```text
Verification:
- bin/rails test test/controllers/homes_controller_test.rb
- bin/rails test
- bin/rubocop
```

If any command fails, report the exact failing command and the relevant error output before attempting another fix.
