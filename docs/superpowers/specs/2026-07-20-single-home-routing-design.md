# Single-Home Routing Design

## Goal

Make the one-home MVP route authenticated users directly into their useful home experience. Users without a home should create one, while users with a home should land on its timeline. The application must not expose a home listing or allow a second home to be created.

## Routing Behavior

`GET /homes` is the single decision point for the default authenticated destination. It does not render an index:

- If the current account has no home, redirect to `new_home_path`.
- If the current account has a home, redirect to `home_path(home)`.

Successful sign-in and registration redirect to `homes_path`, allowing this endpoint to choose the correct destination. A stored return URL created when authentication interrupted a protected request still takes precedence after sign-in.

## One-Home Enforcement

The homes controller enforces the MVP constraint in addition to removing multi-home navigation:

- `GET /homes/new` redirects to the existing home's timeline when the current account already has a home.
- `POST /homes` redirects to the existing home's timeline without creating a record when the current account already has a home.
- A valid first home is created under the current account and redirects to its timeline.
- Invalid first-home submissions continue to render the form with validation errors.

This is application-level enforcement scoped to the MVP. It does not add a database uniqueness constraint because the product may support multiple homes later and the relevant rule is account workflow behavior rather than a permanent data invariant.

## Navigation and Views

The homes index view is removed because it is unreachable and no longer represents supported product behavior. The property header's `Homes` link is replaced with a link to the current home's timeline so the interface does not suggest multi-home navigation.

Existing nested home routes for items, entries, and search remain unchanged.

## Data Access and Authorization

All home lookup and creation continues through `current_account.homes`. Redirect decisions use the current account's first home, preserving account isolation. Requests for a home belonging to another account continue to return not found.

## Tests

Controller and integration coverage will verify:

- Sign-in without a stored return URL routes a user with no home through `/homes` to the new-home form.
- Sign-in without a stored return URL routes a user with a home through `/homes` to its timeline.
- A stored return URL still takes precedence after sign-in.
- Registration routes the new user through `/homes` to the new-home form.
- `GET /homes` redirects according to whether a home exists.
- `GET /homes/new` redirects when a home already exists.
- `POST /homes` cannot create a second home.
- First-home creation and invalid submissions retain their existing behavior.
- The property header links to the timeline rather than the removed index experience.

