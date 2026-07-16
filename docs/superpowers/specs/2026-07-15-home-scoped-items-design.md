# Home-Scoped Items Design

## Purpose

Build the next HouseOS MVP slice: an authenticated user can add systems and appliances to a selected home, view that home's item list, open an item detail page, and edit item details without a full page refresh.

This follows the MVP sequence after home creation and timeline display:

```text
Sign up -> create first Home -> land on Home timeline -> add Item: Water Heater
```

The slice should keep `homes#show` focused on the home timeline. Item browsing and management should live in a nested, home-scoped items resource.

## Selected Approach

Add nested item routes under homes and create an `ItemsController` for item management:

```ruby
resources :homes, only: %i[index new create show] do
  resources :items, only: %i[index new create show edit update]
end
```

This is preferred because items belong to a specific home in both the domain model and the user experience. Nesting keeps authorization straightforward: every item action first loads the home through `current_account.homes`, then loads or builds items through that home.

A global `/items` resource is out of scope for v1 because it would blur the selected-home context. Folding item lists into `homes#show` is also avoided because the home show page is currently the timeline surface and should not become responsible for a second primary view.

## Routes And Controllers

`config/routes.rb` should nest items under homes:

```ruby
resources :homes, only: %i[index new create show] do
  resources :items, only: %i[index new create show edit update]
end
```

`ItemsController` should own:

- `index`: list items for one home.
- `new`: build a new item for one home.
- `create`: create an item through the selected home.
- `show`: display item details.
- `edit`: render an edit form for Turbo-frame replacement.
- `update`: update item details and re-render the detail frame.

Every action should load the home with:

```ruby
@home = current_account.homes.find(params[:home_id])
```

Member actions should load the item with:

```ruby
@item = @home.items.find(params[:id])
```

Item params must not permit `home_id`. The URL and loaded home own the association.

## Timeline Integration

`homes#show` remains the selected home's timeline. At the bottom of the timeline, the page should link to the home-scoped item area:

- `home_items_path(@home)` for viewing the home's items.
- `new_home_item_path(@home)` as a quick action to add a system or appliance.

These links belong below the timeline content so the timeline remains the primary surface.

## Item Fields

The item form should expose the v1 fields already supported by the model:

- `item_kind`, required, using `Item::ITEM_KINDS`
- `name`, required
- `brand`, optional
- `model_number`, optional
- `serial_number`, optional
- `installed_on`, optional
- `notes`, optional

The UI should describe items as systems and appliances. It should not expose rooms, spaces, fixtures, finishes, projects, vendors, attachments, or item-linked entries in this slice.

## Items Index

`items#index` should be scoped to one home and should display:

- a link back to the home timeline
- the home name
- a list of the home's items ordered by name
- each item's kind and optional identifying details when present
- a link to each item detail page
- a link to add a new item
- an empty state when the home has no items

This page is the place to browse systems and appliances for a home. It should not replace or duplicate the home timeline.

## Item Creation

`items#new` renders a standard Rails form for a new item under the selected home. `items#create` builds through:

```ruby
@home.items.build(item_params)
```

On success, it redirects to `home_item_path(@home, @item)`. On validation failure, it re-renders `items/new` with `422 Unprocessable Entity` and displays model validation messages.

## Item Detail And Turbo Editing

`items#show` displays one item detail page. The item detail content should be wrapped in a stable Turbo Frame, for example:

```erb
<%= turbo_frame_tag dom_id(@item) do %>
  ...
<% end %>
```

The detail frame should include an "Edit" link to `edit_home_item_path(@home, @item)`. That link targets the same frame so clicking edit swaps the detail view for the edit form without a full page refresh.

`items#edit` renders the edit form inside the same item frame. `items#update` should:

- update the item from permitted params
- redirect to `home_item_path(@home, @item)` with `303 See Other` on success, letting Turbo replace the matching item frame with updated detail content
- re-render the edit form with `422 Unprocessable Entity` on validation failure

The user should be able to edit an item from its show page using normal Turbo conventions. JavaScript beyond Turbo is not needed for this slice.

## Data Flow

The item creation happy path is:

```text
Authenticated user
-> GET /homes/:home_id
-> click Add item near the bottom of the timeline
-> GET /homes/:home_id/items/new
-> POST /homes/:home_id/items
-> Item is created under the loaded home
-> redirect to GET /homes/:home_id/items/:id
```

The browsing path is:

```text
Authenticated user
-> GET /homes/:home_id/items
-> ItemsController loads the home through current_account
-> ItemsController lists @home.items ordered by name
```

The edit path is:

```text
Authenticated user
-> GET /homes/:home_id/items/:id
-> click Edit inside the item Turbo Frame
-> GET /homes/:home_id/items/:id/edit
-> frame swaps to the edit form
-> PATCH /homes/:home_id/items/:id
-> frame returns to updated item details
```

## Error Handling

Validation failures should use normal Rails model errors and render the relevant form with `422 Unprocessable Entity`.

Cross-account home access should raise `ActiveRecord::RecordNotFound` through `current_account.homes.find(params[:home_id])`.

Cross-home item access should raise `ActiveRecord::RecordNotFound` through `@home.items.find(params[:id])`.

If a user somehow has no current account, this slice does not add account recovery, account switching, or invite behavior.

## Testing

Use Minitest with focused controller or integration tests.

Required coverage:

- authenticated users can view a home-scoped item index
- the item index lists only items for that home
- the home timeline links to the item index and new item form
- authenticated users can open the new item form
- valid item creation increases `Item.count` by one
- created items belong to the selected home
- item creation ignores any attempted `home_id` param
- invalid item creation does not create a record and renders `422`
- authenticated users can view an item detail page
- item show access is blocked for items outside the selected home
- cross-account home access is blocked for item routes
- edit renders inside the item Turbo Frame
- valid update changes item fields and returns updated details without requiring a full page refresh
- invalid update re-renders the edit form with `422`

Existing model tests continue to cover required fields, allowed item kinds, and item-home consistency for entries.

## Out Of Scope

- item deletion
- item-linked entry creation
- attachments
- search
- rooms or spaces
- fixtures, finishes, furniture, projects, or paint
- global item index across all homes
- inline editing directly from `items#index`
- bottom dock navigation
- polished mobile visual design
- Hotwire Native behavior

## Success Criteria

The slice is complete when:

- the home timeline remains `homes#show`
- the bottom of the timeline links to home-scoped item browsing and creation
- users can create systems and appliances under a selected home
- users can browse a selected home's item list
- users can view an item detail page
- users can edit item details from the show page through a Turbo Frame
- item create, show, edit, and update actions are scoped through the current account's home
- tests prove creation, validation failure, listing, Turbo edit behavior, and authorization boundaries
