# HouseOS Domain Foundation Design

## Purpose

Build the first HouseOS implementation slice around the product's core domain and access boundary. This slice proves that a signed-up user receives an account container, that homes/items/entries have the right Rails model shape, and that records are scoped through account membership before the product grows a timeline UI.

## Selected Approach

Use a domain foundation slice with the Rails authentication shell. This is smaller than the full MVP vertical slice but more useful than models alone because it proves the account and authorization boundary early.

The first implementation should add authentication, account creation, core Active Record models, database constraints, model validations, and focused Minitest coverage. UI should stay minimal: only enough routes/controllers are needed to verify signup and scoped home lookup. Polished timeline, item, entry, attachment, and search UI are later slices.

## Architecture

HouseOS remains a Rails-first monolith with server-rendered Rails conventions. The slice uses the Rails authentication generator as the starting point, cookie-backed sessions, Active Record associations, PostgreSQL constraints, and Minitest.

The central access path is:

```text
User -> Membership -> Account -> Home -> Item
                                -> Entry
```

The `Account` is the access and future collaboration container. V1 automatically creates one account per signup, but the data model supports more than one user per account later.

## Domain Model

### User

`User` signs in through Rails authentication.

Associations:

- has many `memberships`
- has many `accounts`, through `memberships`
- has many created `entries`

### Account

`Account` is the access container.

Fields:

- `name`

Associations:

- has many `memberships`
- has many `users`, through `memberships`
- has many `homes`

Validation:

- `name` must be present

### Membership

`Membership` connects users to accounts.

Fields:

- `user_id`
- `account_id`
- `role`

Associations:

- belongs to `user`
- belongs to `account`

Validations and constraints:

- `role` must be present
- `role` must be one of `owner`
- each user/account pair must be unique

V1 only creates owner memberships. Invite UI and additional roles are out of scope.

### Home

`Home` represents a house, condo, apartment, rental, or managed property.

Fields:

- `account_id`
- `name`
- `address`
- `home_type`

Associations:

- belongs to `account`
- has many `items`
- has many `entries`

Validations:

- `name` must be present
- `home_type` may be blank or one of `house`, `condo`, `apartment`, `rental`, `other`

### Item

`Item` is a tracked appliance or system in a home.

Fields:

- `home_id`
- `item_kind`
- `name`
- `brand`
- `model_number`
- `serial_number`
- `installed_on`
- `notes`

Associations:

- belongs to `home`
- has many `entries`

Validations:

- `name` must be present
- `item_kind` must be one of `appliance`, `system`

The field is named `item_kind`, not `type`, to avoid Rails single-table inheritance behavior.

### Entry

`Entry` represents something that happened to the home.

Fields:

- `home_id`
- `item_id`
- `entry_type`
- `title`
- `occurred_on`
- `description`
- `cost_cents`
- `contractor_name`
- `created_by_user_id`

Associations:

- belongs to `home`
- belongs to `item`, optional
- belongs to `created_by_user`, class name `User`

Validations:

- `entry_type` must be one of `maintenance`, `repair`, `installation`, `replacement`, `inspection`, `purchase`, `note`, `memory`
- `title` must be present
- `occurred_on` must be present
- `created_by_user` must be present
- `cost_cents` may be blank but cannot be negative
- if `item` is present, it must belong to the same `home` as the entry

## Authentication And Account Creation

Use the Rails authentication generator as the starting point. On signup, the application creates:

1. a `User`
2. an `Account` named `My household`
3. a `Membership` connecting the user to that account with role `owner`

Account creation should happen in the signup flow in a way that fails atomically. A user should not be persisted without the default account and membership if account creation fails.

This slice does not build account switching UI. `current_account` should return the signed-in user's first account for now.

## Authorization Boundary

Every home lookup in application controllers must be scoped through the current account.

Use a small Rails-native access pattern:

```ruby
def current_account
  Current.user.accounts.first
end
```

Controllers should load records through the account:

```ruby
current_account.homes.find(params[:id])
current_account.homes.find(params[:home_id]).items.find(params[:id])
```

This slice should add only the minimal controller route needed to prove another account's home cannot be accessed by ID. A denied cross-account lookup should raise `ActiveRecord::RecordNotFound` and return the normal Rails not-found behavior.

## Testing

Use Minitest and Rails fixtures or helper methods that future slices can reuse.

Coverage required:

- signup creates a user, default account, and owner membership
- user/account/membership associations work
- membership enforces one record per user/account pair
- home requires a name and validates allowed `home_type`
- item requires a name and validates allowed `item_kind`
- entry requires title, occurred date, type, and creator
- entry validates allowed `entry_type`
- entry allows a blank item
- entry rejects an item from another home
- account-scoped home lookup prevents one account from accessing another account's home

## Out Of Scope

- timeline UI
- item creation UI
- entry creation UI
- attachments and Active Storage validations
- search
- account switching UI
- invite or collaboration UI
- roles beyond `owner`
- polished mobile styling
- Hotwire Native behavior

## Success Criteria

The slice is successful when:

- a new user can sign up and receive a default `My household` account
- the core models and database constraints match the MVP docs
- tests prove the core associations, validations, and account boundary
- later timeline, item, entry, attachment, and search slices can build on this foundation without revisiting the domain names
