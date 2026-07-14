# Domain Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first HouseOS domain foundation: authentication, default account creation, core home/item/entry models, and account-scoped access tests.

**Architecture:** Use the Rails 8 authentication generator as the auth baseline, then layer conventional Active Record models and controller scoping on top. Keep UI minimal and server-rendered; routes exist only to support signup and scoped home lookup.

**Tech Stack:** Ruby 3.4+, Rails 8.1, PostgreSQL, ERB, Turbo, Tailwind, Minitest, Rails fixtures.

## Global Constraints

- Use Rails conventions before introducing dependencies.
- Use `Account` as the access, billing, and future collaboration container.
- Use `Home`, not `House` or `Property`.
- Use `item_kind`, not `type`, for item category.
- V1 item kinds are exactly `appliance` and `system`.
- V1 entry types are exactly `maintenance`, `repair`, `installation`, `replacement`, `inspection`, `purchase`, `note`, and `memory`.
- A new signup creates one account named `My household` and one `owner` membership.
- Account creation during signup must be atomic with user creation.
- Every home lookup in controllers must be scoped through `current_account`.
- Out of scope: attachments, search, timeline UI, polished mobile styling, invites, account switching, roles beyond `owner`.

---

## File Structure

- `Gemfile`: enable `bcrypt` for generated authentication.
- Rails authentication generator output: create the Rails-standard `User`, `Session`, authentication concern, session/password controllers, mailer, views, and auth migrations.
- `app/models/account.rb`: account container and default account name.
- `app/models/membership.rb`: user/account join with owner role.
- `app/models/home.rb`: account-owned home with optional type.
- `app/models/item.rb`: home-owned appliance/system record.
- `app/models/entry.rb`: home event with optional item and creator.
- `app/models/user.rb`: generated auth model plus account and entry associations, and default account creation helper.
- `app/controllers/application_controller.rb`: include auth and expose `current_account`.
- `app/controllers/registrations_controller.rb`: minimal signup flow.
- `app/controllers/homes_controller.rb`: minimal account-scoped index/show.
- `app/views/registrations/new.html.erb`: minimal signup form.
- `app/views/homes/index.html.erb`: minimal authenticated landing page.
- `app/views/homes/show.html.erb`: minimal page for scoped lookup tests.
- `config/routes.rb`: session/password routes from auth generator plus registration and home routes.
- `db/migrate/20260715000000_create_accounts.rb`: accounts table.
- `db/migrate/20260715000100_create_memberships.rb`: memberships table.
- `db/migrate/20260715000200_create_homes.rb`: homes table.
- `db/migrate/20260715000300_create_items.rb`: items table.
- `db/migrate/20260715000400_create_entries.rb`: entries table.
- `test/fixtures/accounts.yml`: account fixtures.
- `test/fixtures/memberships.yml`: membership fixtures.
- `test/fixtures/homes.yml`: home fixtures.
- `test/fixtures/items.yml`: item fixtures.
- `test/fixtures/entries.yml`: entry fixtures.
- `test/models/*_test.rb`: focused model tests.
- `test/integration/registration_default_account_test.rb`: signup/account integration test.
- `test/controllers/homes_controller_test.rb`: scoped lookup controller test.
- `test/test_helper.rb`: auth helper for integration/controller tests.

---

### Task 1: Baseline Setup

**Files:**
- Track existing Rails scaffold files already present in the repository.
- Modify: `Gemfile`
- Verify: `Gemfile.lock`

**Interfaces:**
- Consumes: Fresh Rails app scaffold and approved design spec.
- Produces: A bootable Rails app with dependencies installed and `bcrypt` available for auth.

- [ ] **Step 1: Enable bcrypt**

Edit `Gemfile` and change:

```ruby
# gem "bcrypt", "~> 3.1.7"
```

to:

```ruby
gem "bcrypt", "~> 3.1.7"
```

- [ ] **Step 2: Install dependencies and prepare databases**

Run:

```bash
bin/setup --skip-server
```

Expected: Bundler installs missing gems, PostgreSQL databases are prepared, and the command exits 0.

If PostgreSQL is not running, start PostgreSQL locally and rerun:

```bash
bin/setup --skip-server
```

- [ ] **Step 3: Verify Rails boots**

Run:

```bash
bin/rails runner "puts Rails.version"
```

Expected: prints `8.1.3`.

- [ ] **Step 4: Commit the Rails baseline**

Run:

```bash
git add -A
git commit -m "Track Rails application baseline"
```

Expected: commit succeeds and includes the existing Rails scaffold plus the `bcrypt` Gemfile/Gemfile.lock change.

---

### Task 2: Authentication Shell

**Files:**
- Create through generator: `app/models/user.rb`
- Create through generator: `app/models/session.rb`
- Create through generator: `app/models/current.rb`
- Create through generator: `app/controllers/concerns/authentication.rb`
- Create through generator: `app/controllers/sessions_controller.rb`
- Create through generator: `app/controllers/passwords_controller.rb`
- Create through generator: `app/mailers/passwords_mailer.rb`
- Create through generator: auth views under `app/views/sessions/`, `app/views/passwords/`, and `app/views/passwords_mailer/`
- Create through generator: user/session migrations under `db/migrate/`
- Modify: `app/controllers/application_controller.rb`
- Modify: `config/routes.rb`

**Interfaces:**
- Consumes: `bcrypt` from Task 1.
- Produces: `User`, `Session`, `Current.user`, `start_new_session_for(user)`, `terminate_session`, and `allow_unauthenticated_access`.

- [ ] **Step 1: Generate Rails authentication**

Run:

```bash
bin/rails generate authentication
```

Expected: Rails creates the standard authentication models, controllers, concern, views, mailer, and migrations.

- [ ] **Step 2: Ensure ApplicationController includes authentication and current_account**

Edit `app/controllers/application_controller.rb` to:

```ruby
class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_account

  private

  def current_account
    Current.user&.accounts&.first
  end
end
```

- [ ] **Step 3: Ensure auth routes exist**

Edit `config/routes.rb` so it contains the generated session/password routes while keeping the health check:

```ruby
Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  get "up" => "rails/health#show", as: :rails_health_check
end
```

- [ ] **Step 4: Run auth migrations**

Run:

```bash
bin/rails db:migrate
```

Expected: users and sessions tables are created.

- [ ] **Step 5: Verify auth files load**

Run:

```bash
bin/rails runner "puts [User.name, Session.name, Current.name].join(', ')"
```

Expected:

```text
User, Session, Current
```

- [ ] **Step 6: Commit**

Run:

```bash
git add Gemfile Gemfile.lock app config db test
git commit -m "Add Rails authentication shell"
```

Expected: commit succeeds with generated authentication files and route/controller wiring.

---

### Task 3: Account, Membership, Home, And Item Models

**Files:**
- Create: `db/migrate/20260715000000_create_accounts.rb`
- Create: `db/migrate/20260715000100_create_memberships.rb`
- Create: `db/migrate/20260715000200_create_homes.rb`
- Create: `db/migrate/20260715000300_create_items.rb`
- Create: `app/models/account.rb`
- Create: `app/models/membership.rb`
- Create: `app/models/home.rb`
- Create: `app/models/item.rb`
- Modify: `app/models/user.rb`
- Create: `test/fixtures/accounts.yml`
- Create: `test/fixtures/memberships.yml`
- Create: `test/fixtures/homes.yml`
- Create: `test/fixtures/items.yml`
- Create: `test/models/account_test.rb`
- Create: `test/models/membership_test.rb`
- Create: `test/models/home_test.rb`
- Create: `test/models/item_test.rb`

**Interfaces:**
- Consumes: `User` from Task 2.
- Produces: `Account::DEFAULT_NAME`, `Membership::OWNER_ROLE`, `Home::HOME_TYPES`, `Item::ITEM_KINDS`, and user/account/home/item associations.

- [ ] **Step 1: Write failing account and membership tests**

Create `test/models/account_test.rb`:

```ruby
require "test_helper"

class AccountTest < ActiveSupport::TestCase
  test "requires a name" do
    account = Account.new

    assert_not account.valid?
    assert_includes account.errors[:name], "can't be blank"
  end

  test "has users through memberships" do
    assert_includes accounts(:household).users, users(:owner)
  end
end
```

Create `test/models/membership_test.rb`:

```ruby
require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "requires an allowed role" do
    membership = Membership.new(user: users(:owner), account: accounts(:other_household), role: "admin")

    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "enforces unique user account pairs" do
    duplicate = Membership.new(user: users(:owner), account: accounts(:household), role: Membership::OWNER_ROLE)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end
end
```

- [ ] **Step 2: Write failing home and item tests**

Create `test/models/home_test.rb`:

```ruby
require "test_helper"

class HomeTest < ActiveSupport::TestCase
  test "requires a name" do
    home = Home.new(account: accounts(:household))

    assert_not home.valid?
    assert_includes home.errors[:name], "can't be blank"
  end

  test "allows blank home type" do
    home = Home.new(account: accounts(:household), name: "Lake House")

    assert home.valid?
  end

  test "normalizes blank home type to nil" do
    home = Home.new(account: accounts(:household), name: "Lake House", home_type: "")

    assert home.valid?
    assert_nil home.home_type
  end

  test "validates allowed home type" do
    home = Home.new(account: accounts(:household), name: "Lake House", home_type: "castle")

    assert_not home.valid?
    assert_includes home.errors[:home_type], "is not included in the list"
  end
end
```

Create `test/models/item_test.rb`:

```ruby
require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "requires a name" do
    item = Item.new(home: homes(:main), item_kind: "appliance")

    assert_not item.valid?
    assert_includes item.errors[:name], "can't be blank"
  end

  test "validates allowed item kind" do
    item = Item.new(home: homes(:main), name: "Kitchen Paint", item_kind: "finish")

    assert_not item.valid?
    assert_includes item.errors[:item_kind], "is not included in the list"
  end
end
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
bin/rails test test/models/account_test.rb test/models/membership_test.rb test/models/home_test.rb test/models/item_test.rb
```

Expected: FAIL with missing constants/tables such as `uninitialized constant Account`.

- [ ] **Step 4: Add migrations**

Create `db/migrate/20260715000000_create_accounts.rb`:

```ruby
class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false

      t.timestamps
    end
  end
end
```

Create `db/migrate/20260715000100_create_memberships.rb`:

```ruby
class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :role, null: false, default: "owner"

      t.timestamps
    end

    add_index :memberships, [ :user_id, :account_id ], unique: true
    add_check_constraint :memberships, "role IN ('owner')", name: "memberships_role_check"
  end
end
```

Create `db/migrate/20260715000200_create_homes.rb`:

```ruby
class CreateHomes < ActiveRecord::Migration[8.1]
  def change
    create_table :homes do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.text :address
      t.string :home_type

      t.timestamps
    end

    add_check_constraint :homes,
      "home_type IS NULL OR home_type IN ('house', 'condo', 'apartment', 'rental', 'other')",
      name: "homes_home_type_check"
  end
end
```

Create `db/migrate/20260715000300_create_items.rb`:

```ruby
class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :home, null: false, foreign_key: true
      t.string :item_kind, null: false
      t.string :name, null: false
      t.string :brand
      t.string :model_number
      t.string :serial_number
      t.date :installed_on
      t.text :notes

      t.timestamps
    end

    add_check_constraint :items,
      "item_kind IN ('appliance', 'system')",
      name: "items_item_kind_check"
  end
end
```

- [ ] **Step 5: Add models**

Create `app/models/account.rb`:

```ruby
class Account < ApplicationRecord
  DEFAULT_NAME = "My household"

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :homes, dependent: :destroy

  validates :name, presence: true
end
```

Create `app/models/membership.rb`:

```ruby
class Membership < ApplicationRecord
  OWNER_ROLE = "owner"
  ROLES = [ OWNER_ROLE ].freeze

  belongs_to :user
  belongs_to :account

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }
end
```

Create `app/models/home.rb`:

```ruby
class Home < ApplicationRecord
  HOME_TYPES = %w[house condo apartment rental other].freeze

  belongs_to :account
  has_many :items, dependent: :destroy
  has_many :entries, dependent: :destroy

  before_validation :normalize_blank_home_type

  validates :name, presence: true
  validates :home_type, inclusion: { in: HOME_TYPES }, allow_nil: true

  private

  def normalize_blank_home_type
    self.home_type = nil if home_type.blank?
  end
end
```

Create `app/models/item.rb`:

```ruby
class Item < ApplicationRecord
  ITEM_KINDS = %w[appliance system].freeze

  belongs_to :home
  has_many :entries, dependent: :nullify

  validates :name, presence: true
  validates :item_kind, inclusion: { in: ITEM_KINDS }
end
```

Edit `app/models/user.rb` so it keeps the generated authentication code and also includes these associations:

```ruby
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :created_entries, class_name: "Entry", foreign_key: :created_by_user_id, inverse_of: :created_by_user, dependent: :restrict_with_exception
```

- [ ] **Step 6: Add fixtures**

Create `test/fixtures/accounts.yml`:

```yaml
household:
  name: My household

other_household:
  name: Other household
```

Ensure `test/fixtures/users.yml` contains password-backed users:

```yaml
owner:
  email_address: owner@example.com
  password_digest: <%= BCrypt::Password.create("password") %>

other_owner:
  email_address: other@example.com
  password_digest: <%= BCrypt::Password.create("password") %>
```

Create `test/fixtures/memberships.yml`:

```yaml
owner_membership:
  user: owner
  account: household
  role: owner

other_owner_membership:
  user: other_owner
  account: other_household
  role: owner
```

Create `test/fixtures/homes.yml`:

```yaml
main:
  account: household
  name: Main Home
  address: 123 Main Street
  home_type: house

other:
  account: other_household
  name: Other Home
  address: 456 Other Avenue
  home_type: condo
```

Create `test/fixtures/items.yml`:

```yaml
water_heater:
  home: main
  item_kind: appliance
  name: Water Heater
  brand: Rheem
  model_number: WH-100
  serial_number: SN-100
  installed_on: 2024-01-15
  notes: Basement utility closet

other_water_heater:
  home: other
  item_kind: appliance
  name: Other Water Heater
```

- [ ] **Step 7: Migrate and run model tests**

Run:

```bash
bin/rails db:migrate
bin/rails test test/models/account_test.rb test/models/membership_test.rb test/models/home_test.rb test/models/item_test.rb
```

Expected: all four model test files pass.

- [ ] **Step 8: Commit**

Run:

```bash
git add app/models db/migrate test/fixtures test/models
git commit -m "Add account home and item models"
```

Expected: commit succeeds with account, membership, home, and item foundation.

---

### Task 4: Entry Model And Cross-Home Constraint

**Files:**
- Create: `db/migrate/20260715000400_create_entries.rb`
- Create: `app/models/entry.rb`
- Create: `test/fixtures/entries.yml`
- Create: `test/models/entry_test.rb`

**Interfaces:**
- Consumes: `Home`, `Item`, and `User` from earlier tasks.
- Produces: `Entry::ENTRY_TYPES` and `Entry` same-home item validation.

- [ ] **Step 1: Write failing entry tests**

Create `test/models/entry_test.rb`:

```ruby
require "test_helper"

class EntryTest < ActiveSupport::TestCase
  test "requires title" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:title], "can't be blank"
  end

  test "requires occurred on" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "replacement", title: "Replaced water heater")

    assert_not entry.valid?
    assert_includes entry.errors[:occurred_on], "can't be blank"
  end

  test "validates allowed entry type" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "reminder", title: "Change filter", occurred_on: Date.current)

    assert_not entry.valid?
    assert_includes entry.errors[:entry_type], "is not included in the list"
  end

  test "allows blank item" do
    entry = Entry.new(home: homes(:main), created_by_user: users(:owner), entry_type: "memory", title: "Moved in", occurred_on: Date.current)

    assert entry.valid?
  end

  test "rejects item from another home" do
    entry = Entry.new(
      home: homes(:main),
      item: items(:other_water_heater),
      created_by_user: users(:owner),
      entry_type: "replacement",
      title: "Replaced water heater",
      occurred_on: Date.current
    )

    assert_not entry.valid?
    assert_includes entry.errors[:item], "must belong to the same home"
  end

  test "rejects negative cost" do
    entry = Entry.new(
      home: homes(:main),
      created_by_user: users(:owner),
      entry_type: "repair",
      title: "Garage door repair",
      occurred_on: Date.current,
      cost_cents: -1
    )

    assert_not entry.valid?
    assert_includes entry.errors[:cost_cents], "must be greater than or equal to 0"
  end
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
bin/rails test test/models/entry_test.rb
```

Expected: FAIL with `uninitialized constant Entry`.

- [ ] **Step 3: Add migration**

Create `db/migrate/20260715000400_create_entries.rb`:

```ruby
class CreateEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :entries do |t|
      t.references :home, null: false, foreign_key: true
      t.references :item, foreign_key: true
      t.string :entry_type, null: false
      t.string :title, null: false
      t.date :occurred_on, null: false
      t.text :description
      t.integer :cost_cents
      t.string :contractor_name
      t.references :created_by_user, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_check_constraint :entries,
      "entry_type IN ('maintenance', 'repair', 'installation', 'replacement', 'inspection', 'purchase', 'note', 'memory')",
      name: "entries_entry_type_check"

    add_check_constraint :entries,
      "cost_cents IS NULL OR cost_cents >= 0",
      name: "entries_cost_cents_check"
  end
end
```

- [ ] **Step 4: Add model**

Create `app/models/entry.rb`:

```ruby
class Entry < ApplicationRecord
  ENTRY_TYPES = %w[maintenance repair installation replacement inspection purchase note memory].freeze

  belongs_to :home
  belongs_to :item, optional: true
  belongs_to :created_by_user, class_name: "User", inverse_of: :created_entries

  validates :entry_type, inclusion: { in: ENTRY_TYPES }
  validates :title, presence: true
  validates :occurred_on, presence: true
  validates :cost_cents, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :item_belongs_to_home

  private

  def item_belongs_to_home
    return if item.blank? || home.blank?

    errors.add(:item, "must belong to the same home") if item.home_id != home_id
  end
end
```

- [ ] **Step 5: Add fixtures**

Create `test/fixtures/entries.yml`:

```yaml
water_heater_replacement:
  home: main
  item: water_heater
  entry_type: replacement
  title: Replaced water heater
  occurred_on: 2024-01-15
  description: Replaced the failing tank water heater.
  cost_cents: 180000
  contractor_name: Reliable Plumbing
  created_by_user: owner

move_in:
  home: main
  entry_type: memory
  title: Moved in
  occurred_on: 2023-09-01
  created_by_user: owner
```

- [ ] **Step 6: Migrate and run entry tests**

Run:

```bash
bin/rails db:migrate
bin/rails test test/models/entry_test.rb
```

Expected: entry model tests pass.

- [ ] **Step 7: Run all model tests**

Run:

```bash
bin/rails test test/models
```

Expected: all model tests pass.

- [ ] **Step 8: Commit**

Run:

```bash
git add app/models db/migrate test/fixtures test/models
git commit -m "Add entry model"
```

Expected: commit succeeds with entry behavior and tests.

---

### Task 5: Signup And Account-Scoped Home Lookup

**Files:**
- Modify: `app/models/user.rb`
- Create: `app/controllers/registrations_controller.rb`
- Create: `app/controllers/homes_controller.rb`
- Create: `app/views/registrations/new.html.erb`
- Create: `app/views/homes/index.html.erb`
- Create: `app/views/homes/show.html.erb`
- Modify: `config/routes.rb`
- Modify: `test/test_helper.rb`
- Create: `test/integration/registration_default_account_test.rb`
- Create: `test/controllers/homes_controller_test.rb`

**Interfaces:**
- Consumes: `Account::DEFAULT_NAME`, `Membership::OWNER_ROLE`, `Current.user`, `start_new_session_for(user)`, and `current_account`.
- Produces: `User.create_with_default_account!(attributes)`, `RegistrationsController#create`, and account-scoped `HomesController#show`.

- [ ] **Step 1: Add test auth helper**

Edit `test/test_helper.rb` to:

```ruby
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module AuthenticationTestHelper
  def sign_in_as(user, password: "password")
    post session_url, params: { email_address: user.email_address, password: password }
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
  end
end

ActionDispatch::IntegrationTest.include AuthenticationTestHelper
```

- [ ] **Step 2: Write failing signup integration test**

Create `test/integration/registration_default_account_test.rb`:

```ruby
require "test_helper"

class RegistrationDefaultAccountTest < ActionDispatch::IntegrationTest
  test "signup creates default account and owner membership" do
    assert_difference -> { User.count }, 1 do
      assert_difference -> { Account.count }, 1 do
        assert_difference -> { Membership.count }, 1 do
          post registration_url, params: {
            user: {
              email_address: "new@example.com",
              password: "password",
              password_confirmation: "password"
            }
          }
        end
      end
    end

    user = User.find_by!(email_address: "new@example.com")

    assert_redirected_to homes_url
    assert_equal [ "My household" ], user.accounts.pluck(:name)
    assert_equal [ "owner" ], user.memberships.pluck(:role)
  end
end
```

- [ ] **Step 3: Write failing scoped lookup controller tests**

Create `test/controllers/homes_controller_test.rb`:

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
end
```

- [ ] **Step 4: Run tests to verify they fail**

Run:

```bash
bin/rails test test/integration/registration_default_account_test.rb test/controllers/homes_controller_test.rb
```

Expected: FAIL with missing registration and homes routes/controllers.

- [ ] **Step 5: Add atomic user/account creation helper**

Edit `app/models/user.rb` to keep generated authentication behavior and add:

```ruby
  has_many :memberships, dependent: :destroy
  has_many :accounts, through: :memberships
  has_many :created_entries, class_name: "Entry", foreign_key: :created_by_user_id, inverse_of: :created_by_user, dependent: :restrict_with_exception

  def self.create_with_default_account!(attributes)
    transaction do
      user = create!(attributes)
      account = Account.create!(name: Account::DEFAULT_NAME)
      Membership.create!(user: user, account: account, role: Membership::OWNER_ROLE)
      user
    end
  end
```

If these associations already exist from Task 3, keep one copy and add only the class method.

- [ ] **Step 6: Add controllers**

Create `app/controllers/registrations_controller.rb`:

```ruby
class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
  end

  def create
    @user = User.create_with_default_account!(registration_params)
    start_new_session_for @user
    redirect_to homes_path
  rescue ActiveRecord::RecordInvalid => error
    @user = error.record.is_a?(User) ? error.record : User.new(registration_params)
    flash.now[:alert] = "Please check your signup details."
    render :new, status: :unprocessable_entity
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
```

Create `app/controllers/homes_controller.rb`:

```ruby
class HomesController < ApplicationController
  def index
    @homes = current_account.homes.order(:name)
  end

  def show
    @home = current_account.homes.find(params[:id])
  end
end
```

- [ ] **Step 7: Add routes**

Edit `config/routes.rb` to:

```ruby
Rails.application.routes.draw do
  resource :registration, only: %i[new create]
  resource :session
  resources :passwords, param: :token
  resources :homes, only: %i[index show]

  get "up" => "rails/health#show", as: :rails_health_check

  root "registrations#new"
end
```

- [ ] **Step 8: Add minimal views**

Create `app/views/registrations/new.html.erb`:

```erb
<% content_for :title, "Sign up" %>

<section>
  <h1>Sign up</h1>

  <%= form_with model: @user, url: registration_path do |form| %>
    <div>
      <%= form.label :email_address %>
      <%= form.email_field :email_address, required: true, autofocus: true, autocomplete: "email" %>
    </div>

    <div>
      <%= form.label :password %>
      <%= form.password_field :password, required: true, autocomplete: "new-password" %>
    </div>

    <div>
      <%= form.label :password_confirmation %>
      <%= form.password_field :password_confirmation, required: true, autocomplete: "new-password" %>
    </div>

    <%= form.submit "Create account" %>
  <% end %>
</section>
```

Create `app/views/homes/index.html.erb`:

```erb
<% content_for :title, "Homes" %>

<section>
  <h1>Homes</h1>

  <% if @homes.any? %>
    <ul>
      <% @homes.each do |home| %>
        <li><%= link_to home.name, home_path(home) %></li>
      <% end %>
    </ul>
  <% else %>
    <p>No homes yet.</p>
  <% end %>
</section>
```

Create `app/views/homes/show.html.erb`:

```erb
<% content_for :title, @home.name %>

<section>
  <h1><%= @home.name %></h1>

  <% if @home.address.present? %>
    <p><%= @home.address %></p>
  <% end %>
</section>
```

- [ ] **Step 9: Run signup and authorization tests**

Run:

```bash
bin/rails test test/integration/registration_default_account_test.rb test/controllers/homes_controller_test.rb
```

Expected: tests pass.

- [ ] **Step 10: Run the full test suite**

Run:

```bash
bin/rails test
```

Expected: full test suite passes.

- [ ] **Step 11: Commit**

Run:

```bash
git add app config test
git commit -m "Add signup account creation and scoped homes"
```

Expected: commit succeeds with signup and scoped lookup behavior.

---

## Final Verification

- [ ] **Step 1: Run full tests**

Run:

```bash
bin/rails test
```

Expected: all tests pass.

- [ ] **Step 2: Run style check**

Run:

```bash
bin/rubocop
```

Expected: no offenses.

- [ ] **Step 3: Run local CI if dependencies and PostgreSQL are ready**

Run:

```bash
bin/ci
```

Expected: CI sequence completes with no failures.

If `bin/ci` fails because PostgreSQL is not running, start PostgreSQL and rerun `bin/ci`.

## Self-Review

- Spec coverage: The plan covers authentication, default account creation, account/membership/home/item/entry models, validations, database constraints, same-home entry/item validation, and account-scoped home lookup.
- Placeholder scan: The plan has no unresolved markers or vague implementation steps; generated auth file names are listed by stable Rails paths, while timestamped Rails auth migrations are created by the generator.
- Type consistency: Constants and method names used across tasks are defined before consumers rely on them: `Account::DEFAULT_NAME`, `Membership::OWNER_ROLE`, `Home::HOME_TYPES`, `Item::ITEM_KINDS`, `Entry::ENTRY_TYPES`, `User.create_with_default_account!`, and `current_account`.
