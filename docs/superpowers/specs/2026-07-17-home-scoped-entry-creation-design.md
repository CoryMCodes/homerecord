# Home-Scoped Entry Creation Design

## Purpose

Build the next HouseOS MVP slice: an authenticated user can add a timeline entry to a selected home, optionally link it to one of that home's systems or appliances, land on the new entry's detail page, and see the entry appear on the home timeline.

This follows the MVP sequence after home creation and item management:

```text
Sign up -> create first Home -> land on Home timeline -> add Item: Water Heater -> add Entry: Replaced water heater
```

Attachments are intentionally deferred to the next slice. This slice proves entry creation, item linking, detail display, timeline integration, and authorization boundaries without adding file upload behavior.

## Selected Approach

Add nested entry routes under homes and create an `EntriesController` for entry creation and detail display:

```ruby
resources :homes, only: %i[index new create show] do
  resources :items, only: %i[index new create show edit update]
  resources :entries, only: %i[new create show]
end
```

This approach is preferred because entries belong to a selected home in both the domain model and the user experience. Nesting keeps authorization straightforward: every entry action first loads the home through `current_account.homes`, then loads or builds entries through that home.

A global `/entries` resource is out of scope for v1 because it would force home selection into the form before the product has a multi-home navigation model. Item-nested entry creation is also deferred because many valid entries are home-level and not linked to an item.

## Routes And Controllers

`config/routes.rb` should nest entries under homes:

```ruby
resources :homes, only: %i[index new create show] do
  resources :items, only: %i[index new create show edit update]
  resources :entries, only: %i[new create show]
end
```

`EntriesController` should own:

- `new`: build a new entry for one home.
- `create`: create an entry through the selected home and current user.
- `show`: display entry details for one home.

Every action should load the home with:

```ruby
@home = current_account.homes.find(params[:home_id])
```

The `show` action should load the entry with:

```ruby
@entry = @home.entries.find(params[:id])
```

Entry params must not permit `home_id` or `created_by_user_id`. The URL owns the home association, and the current session owns the creator association.

Entry params should also avoid accepting raw `cost_cents` from the browser. Cost should come from the user-facing dollars field and be converted server-side.

## Timeline Integration

`homes#show` remains the selected home's timeline. The timeline page should add a clear entry creation action:

- `new_home_entry_path(@home)` for adding a timeline entry.

When timeline entries render, each entry title should link to its detail page:

- `home_entry_path(@home, entry)`

The existing item actions can remain below the timeline. The entry creation action should be closer to the timeline heading or empty state because adding entries is the primary home timeline action.

## Entry Fields

The entry form should expose the v1 fields already supported by the model:

- `entry_type`, required, using `Entry::ENTRY_TYPES`
- `title`, required
- `occurred_on`, required
- `description`, optional
- cost, optional, entered in dollars and stored in `cost_cents`
- `contractor_name`, optional
- `item_id`, optional and limited to items belonging to the selected home

The user-facing label for `contractor_name` can be "Contractor or vendor" to match the broader MVP search language.

The cost field should use dollars in the form and persist cents in `cost_cents`. The controller can normalize a form-only cost parameter into `cost_cents` before assigning attributes. Blank cost means no cost is stored. Invalid, negative, or non-numeric cost input should re-render the form with a validation error.

The form should not expose attachments, recurring schedules, reminders, search metadata, rooms, spaces, or collaboration behavior.

## Entry Creation

`entries#new` renders a standard Rails form for a new entry under the selected home. It should have access to the home's items ordered by name so the optional item select can be populated.

`entries#create` builds through:

```ruby
@entry = @home.entries.build(entry_params)
@entry.created_by_user = Current.user
```

On success, it redirects to `home_entry_path(@home, @entry)`.

On validation failure, it re-renders `entries/new` with `422 Unprocessable Entity`, preserves validation messages, and keeps the selected form values available.

If `item_id` is present, the controller should resolve it through `@home.items.find(item_id)` or otherwise ensure that the final entry cannot link to an item from another home. A forged cross-home item id must not create a record.

## Entry Detail

`entries#show` displays one entry detail page. It should show:

- back link to the home timeline
- entry title
- entry type
- occurred date
- optional linked item, with a link to that item detail page
- optional description
- optional formatted cost
- optional contractor or vendor

The detail page should not include editing, deleting, attachments, or attachment placeholders in this slice.

## Data Flow

The entry creation happy path is:

```text
Authenticated user
-> GET /homes/:home_id
-> click Add entry
-> GET /homes/:home_id/entries/new
-> POST /homes/:home_id/entries
-> Entry is created under the loaded home with the current user as creator
-> redirect to GET /homes/:home_id/entries/:id
```

The optional item link path is:

```text
Authenticated user
-> GET /homes/:home_id/entries/new
-> choose an item from that home's items
-> POST /homes/:home_id/entries
-> Entry is created with item_id only if the item belongs to the loaded home
```

The timeline return path is:

```text
Authenticated user
-> GET /homes/:home_id/entries/:id
-> click Back to timeline
-> GET /homes/:home_id
-> new entry appears in occurred_on descending order
```

## Error Handling

Validation failures should use normal Rails model errors and render the form with `422 Unprocessable Entity`.

Cross-account home access should raise `ActiveRecord::RecordNotFound` through `current_account.homes.find(params[:home_id])`.

Cross-home entry access should raise `ActiveRecord::RecordNotFound` through `@home.entries.find(params[:id])`.

Cross-home item linking should fail before save by loading the item through `@home.items` or by adding a model validation error and re-rendering the form. The user should not be able to create an entry linked to an item outside the selected home.

If a user somehow has no current account, this slice does not add account recovery, account switching, or invite behavior.

## Testing

Use Minitest with focused controller or integration tests.

Required coverage:

- the home timeline links to the new entry form
- timeline entry titles link to entry detail pages
- authenticated users can open the new entry form
- the entry form includes required entry fields and an optional item select
- valid entry creation increases `Entry.count` by one
- created entries belong to the selected home
- created entries use the current user as `created_by_user`
- entry creation ignores any attempted `home_id` or `created_by_user_id` params
- successful creation redirects to the entry detail page
- entry detail displays title, type, occurred date, description, linked item, cost, and contractor/vendor when present
- invalid entry creation does not create a record and renders `422`
- entry creation without an item is allowed
- entry creation with an item from the selected home is allowed
- entry creation with an item from another home is blocked
- cross-account home access is blocked for entry routes
- cross-home entry access is blocked

Existing model tests continue to cover required fields, allowed entry types, optional item links, item-home consistency, creator presence, and non-negative cost.

## Out Of Scope

- Active Storage attachments
- attachment validations
- attachment previews
- editing entries
- deleting entries
- item-nested entry shortcuts
- global entry index
- search
- reminders
- recurring schedules
- bottom dock navigation
- polished mobile visual design
- Hotwire Native behavior

## Success Criteria

The slice is complete when:

- the home timeline has a clear Add entry action
- users can create a home-scoped entry from the selected home
- users can optionally link an entry to an item belonging to that home
- successful entry creation redirects to the new entry's detail page
- entry detail displays the core v1 entry fields
- the new entry appears on the home timeline
- entry creation and detail actions are scoped through the current account's home
- tests prove creation, validation failure, item linking, detail display, timeline integration, and authorization boundaries
