# Home Creation And Timeline Design

## Purpose

Build the next HouseOS vertical slice: an authenticated user can create a home and land on that home's timeline. This moves the app from a domain foundation into the first visible onboarding loop from the MVP docs:

```text
Sign up -> create first Home -> land on Home timeline
```

The slice should stay small. It should prove home creation, account scoping, redirect behavior, and the first timeline surface without introducing item creation, entry creation, attachments, search, or polished mobile navigation.

## Selected Approach

Upgrade `homes#show` into the home timeline page and add standard Rails `new` and `create` actions to `HomesController`.

This approach is preferred because the timeline is the primary surface for a selected home, and `homes#show` is already the account-scoped route for viewing one home. A separate timeline controller would add routing and ownership complexity before there is enough timeline behavior to justify it. Folding home fields into signup would make signup do too much and would obscure the account creation boundary proven in the previous slice.

## Routes And Controllers

`config/routes.rb` should expose:

```ruby
resources :homes, only: %i[index new create show]
```

`HomesController` should remain the owner of this slice:

- `index`: load `current_account.homes.order(:name)` and show either existing homes or an empty state.
- `new`: build `current_account.homes.build`.
- `create`: create through `current_account.homes` using permitted home params.
- `show`: load the home through `current_account.homes.find(params[:id])` and present it as the timeline page.

All home reads and writes must be scoped through `current_account`. A request must never be able to create a home for, or view a home from, another account by passing IDs in params.

## Home Form

The first home form should collect only the v1 home fields:

- `name`, required
- `address`, optional
- `home_type`, optional

`home_type` should use the existing `Home::HOME_TYPES` list:

```text
house, condo, apartment, rental, other
```

The form should not ask for inventory, rooms, entries, photos, documents, or collaborators. On success, `homes#create` redirects to `home_path(@home)`. On validation failure, it re-renders `homes/new` with `422 Unprocessable Entity` and preserves validation messages.

## Homes Index

The homes index remains a simple authenticated landing page. If homes exist, it lists them and provides a path to add another home. If no homes exist, it should make the next action obvious by linking to `new_home_path`.

This is still intentionally simple. The polished first-screen layout from the MVP docs is a later UI slice.

## Timeline Page

`homes#show` becomes the first home timeline surface.

It should display:

- the home name
- the address when present
- timeline entries ordered newest first, using `occurred_on` descending and a stable secondary order
- an empty timeline state when there are no entries

This slice should not add entry creation UI. The page may include a short empty-state prompt about adding entries later, but the actual route, form, and behavior belong to a later entry slice.

## Data Flow

The happy path is:

```text
Authenticated user
-> GET /homes
-> GET /homes/new
-> POST /homes
-> Home is created under current_account
-> redirect to GET /homes/:id
-> show the home timeline
```

The invalid path is:

```text
Authenticated user
-> POST /homes with invalid attributes
-> no home is created
-> render /homes/new with 422
```

The authorization boundary remains:

```text
current_account.homes.find(params[:id])
current_account.homes.create!(home_params)
```

## Error Handling

Validation failures should use normal Rails model errors and render the form with `status: :unprocessable_entity`.

Cross-account lookup should continue to raise `ActiveRecord::RecordNotFound`, producing the app's normal not-found response. This keeps the behavior consistent with the existing account-scoped show test.

If a user somehow has no current account, this slice does not introduce account recovery or switching behavior. Signup already creates a default account atomically, and account switching is out of scope.

## Testing

Use Minitest with focused controller or integration tests.

Required coverage:

- authenticated users can open the new home form
- creating a valid home increases `Home.count` by one
- the new home belongs to the current account
- successful creation redirects to the new home's timeline page
- the timeline page displays the created home's name
- invalid home creation does not create a record and renders `422`
- cross-account show access remains blocked
- timeline entries render newest first on the home page
- a home with no entries shows the empty timeline state

Existing model tests continue to cover field validations and allowed home types.

## Out Of Scope

- entry creation UI
- item creation UI
- attachments
- search
- account switching
- invite or collaboration UI
- bottom dock navigation
- polished mobile visual design
- Hotwire Native behavior

## Success Criteria

The slice is complete when:

- an authenticated user can create a home from the homes index
- the created home is scoped to the user's current account
- successful creation lands on `homes#show`
- `homes#show` reads as the home's timeline, not merely a details page
- timeline entries, when present, render newest first
- tests prove creation, validation failure, timeline rendering, and account boundaries
