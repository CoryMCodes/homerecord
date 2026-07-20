# Single-Home Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Route authenticated users without a home to home creation and users with a home to its timeline, while preventing access to a multi-home index or second-home creation.

**Architecture:** Keep `GET /homes` as the centralized authenticated landing endpoint and make it redirect based on `current_account.homes.first`. Reuse that account-scoped lookup to guard `new` and `create`, while keeping stored post-authentication return URLs ahead of the default `/homes` destination.

**Tech Stack:** Rails 8, Ruby, Action Controller, ERB, Minitest integration tests

## Global Constraints

- MVP supports exactly one home per account through application-level controller enforcement.
- Do not add a database uniqueness constraint.
- Preserve account-scoped authorization through `current_account.homes`.
- Preserve stored return URLs after authentication.
- Do not alter nested item, entry, or search routes.
- Preserve unrelated existing worktree changes in `app/views/layouts/application.html.erb` and `test/integration/authentication_menu_test.rb`.

---

## File Structure

- `app/controllers/concerns/authentication.rb`: changes the default post-sign-in destination while preserving stored return URLs.
- `app/controllers/homes_controller.rb`: owns the single-home redirect decision and prevents access to second-home creation.
- `app/views/homes/_property_header.html.erb`: links back to the current timeline instead of implying a home collection.
- `app/views/homes/index.html.erb`: removed because the index action always redirects.
- `test/controllers/sessions_controller_test.rb`: verifies default and stored-return authentication redirects.
- `test/controllers/homes_controller_test.rb`: verifies landing redirects, one-home enforcement, and timeline navigation.
- `test/integration/registration_default_account_test.rb`: verifies registration enters the centralized landing flow.

### Task 1: Default Authentication Destination

**Files:**
- Modify: `app/controllers/concerns/authentication.rb:37-39`
- Test: `test/controllers/sessions_controller_test.rb`

**Interfaces:**
- Consumes: Rails session key `:return_to_after_authenticating` and route helper `homes_url`.
- Produces: private `after_authentication_url` returning the stored URL when present, otherwise `homes_url`.

- [ ] **Step 1: Write failing sign-in redirect tests**

Replace the valid-credentials test in `test/controllers/sessions_controller_test.rb` and add a stored-return test:

```ruby
test "create with valid credentials redirects to the homes landing route" do
  post session_path, params: { email_address: @user.email_address, password: "password" }

  assert_redirected_to homes_url
  assert cookies[:session_id]
end

test "create returns to a protected page requested before authentication" do
  get home_url(homes(:main))
  assert_redirected_to new_session_path

  post session_path, params: { email_address: users(:owner).email_address, password: "password" }

  assert_redirected_to home_url(homes(:main))
end
```

- [ ] **Step 2: Run the focused tests and verify the sign-in default fails**

Run: `bin/rails test test/controllers/sessions_controller_test.rb`

Expected: FAIL because valid sign-in redirects to `rails_health_check_url`; the stored-return test passes.

- [ ] **Step 3: Change the default post-authentication URL**

In `app/controllers/concerns/authentication.rb`, replace `after_authentication_url` with:

```ruby
def after_authentication_url
  session.delete(:return_to_after_authenticating) || homes_url
end
```

- [ ] **Step 4: Run the focused authentication tests**

Run: `bin/rails test test/controllers/sessions_controller_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit the authentication destination**

```bash
git add app/controllers/concerns/authentication.rb test/controllers/sessions_controller_test.rb
git commit -m "Route sign in through homes landing"
```

### Task 2: Single-Home Landing and Creation Enforcement

**Files:**
- Modify: `app/controllers/homes_controller.rb:1-18`
- Test: `test/controllers/homes_controller_test.rb`
- Test: `test/integration/registration_default_account_test.rb`

**Interfaces:**
- Consumes: `current_account.homes`, `new_home_path`, and `home_path(home)`.
- Produces: `index` redirecting to creation or timeline; `new` and `create` redirecting to the existing home when present; private `existing_home` returning the current account's first `Home` or `nil`.

- [ ] **Step 1: Write failing index and new-action tests**

Add near the top of `test/controllers/homes_controller_test.rb`:

```ruby
test "index redirects to the current home's timeline" do
  sign_in_as users(:owner)

  get homes_url

  assert_redirected_to home_url(homes(:main))
end

test "index redirects to home creation when the account has no home" do
  user = User.create_with_default_account!(
    email_address: "homeless@example.com",
    password: "password",
    password_confirmation: "password"
  )
  sign_in_as user

  get homes_url

  assert_redirected_to new_home_url
end

test "new redirects to the timeline when the account already has a home" do
  sign_in_as users(:owner)

  get new_home_url

  assert_redirected_to home_url(homes(:main))
end
```

Extend `test "signup creates default account and owner membership"` in `test/integration/registration_default_account_test.rb` after the existing membership assertions:

```ruby
follow_redirect!

assert_redirected_to new_home_url
```

Update `test "shows the new home form"` to create and sign in a fresh no-home user:

```ruby
user = User.create_with_default_account!(
  email_address: "new-home-form@example.com",
  password: "password",
  password_confirmation: "password"
)
sign_in_as user
```

- [ ] **Step 2: Run the focused tests and verify they fail**

Run: `bin/rails test test/controllers/homes_controller_test.rb test/integration/registration_default_account_test.rb`

Expected: FAIL because index renders the old list, `new` allows an existing-home account, and the old fixture-backed creation tests conflict with the new one-home rule.

- [ ] **Step 3: Write failing first-home and second-home creation tests**

Update both existing creation tests to build a fresh user with no home, sign that user in, and assert against `user.accounts.first` instead of `accounts(:household)`:

```ruby
user = User.create_with_default_account!(
  email_address: "first-home@example.com",
  password: "password",
  password_confirmation: "password"
)
sign_in_as user
```

In the valid creation test use:

```ruby
assert_equal user.accounts.first, home.account
```

For the invalid creation test use a distinct email such as `invalid-home@example.com`.

Add this second-home test:

```ruby
test "does not create a second home" do
  sign_in_as users(:owner)

  assert_no_difference -> { Home.count } do
    post homes_url, params: {
      home: { name: "Lake House", address: "9 Lake Road", home_type: "house" }
    }
  end

  assert_redirected_to home_url(homes(:main))
end
```

- [ ] **Step 4: Implement the controller redirects and guard**

Replace the beginning of `HomesController` through `create` with:

```ruby
class HomesController < ApplicationController
  def index
    if existing_home
      redirect_to home_path(existing_home)
    else
      redirect_to new_home_path
    end
  end

  def new
    if existing_home
      redirect_to home_path(existing_home)
    else
      @home = current_account.homes.build
    end
  end

  def create
    if existing_home
      redirect_to home_path(existing_home)
      return
    end

    @home = current_account.homes.build(home_params)

    if @home.save
      redirect_to home_path(@home)
    else
      render :new, status: :unprocessable_entity
    end
  end
```

Add under the controller's `private` declaration:

```ruby
def existing_home
  @existing_home ||= current_account.homes.first
end
```

- [ ] **Step 5: Run the homes controller tests**

Run: `bin/rails test test/controllers/homes_controller_test.rb test/integration/registration_default_account_test.rb`

Expected: PASS.

- [ ] **Step 6: Commit the single-home controller behavior**

```bash
git add app/controllers/homes_controller.rb test/controllers/homes_controller_test.rb test/integration/registration_default_account_test.rb
git commit -m "Enforce single-home routing"
```

### Task 3: Remove Multi-Home Navigation and Verify the Flow

**Files:**
- Modify: `app/views/homes/_property_header.html.erb:1-3`
- Delete: `app/views/homes/index.html.erb`
- Test: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: partial local `home` and route helper `home_path(home)`.
- Produces: a `Timeline` navigation link to the current home; no rendered homes index template.

- [ ] **Step 1: Write the failing navigation assertion**

In `test "shows a home in the current account"` in `test/controllers/homes_controller_test.rb`, add:

```ruby
assert_select "a[href='#{home_path(homes(:main))}']", "Timeline"
assert_select "a[href='#{homes_path}']", count: 0
```

- [ ] **Step 2: Run the navigation test and verify it fails**

Run: `bin/rails test test/controllers/homes_controller_test.rb -n /shows_a_home_in_the_current_account/`

Expected: FAIL because the property header still contains a `Homes` link to `homes_path`.

- [ ] **Step 3: Replace the property-header link and remove the unused view**

In `app/views/homes/_property_header.html.erb`, replace the first link with:

```erb
<%= link_to "Timeline", home_path(home), class: "text-sm font-medium text-muted-foreground hover:text-foreground" %>
```

Delete `app/views/homes/index.html.erb`; the index action now always redirects and never renders it.

- [ ] **Step 4: Run all routing-related tests**

Run: `bin/rails test test/controllers/sessions_controller_test.rb test/controllers/homes_controller_test.rb test/integration/registration_default_account_test.rb test/integration/authentication_menu_test.rb`

Expected: PASS.

- [ ] **Step 5: Run the full test and style suites**

Run: `bin/rails test`

Expected: PASS with zero failures and zero errors.

Run: `bin/rubocop`

Expected: PASS with no offenses.

- [ ] **Step 6: Commit navigation cleanup**

Stage only the files owned by this task. Because `test/integration/authentication_menu_test.rb` and `app/views/layouts/application.html.erb` contain pre-existing user changes, do not stage them unless the user explicitly requests it.

```bash
git add app/views/homes/_property_header.html.erb app/views/homes/index.html.erb test/controllers/homes_controller_test.rb
git commit -m "Remove multi-home navigation"
```
