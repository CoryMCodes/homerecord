# Task 3 Report: Entry Creation And Cost Normalization

## What Changed

- Added `EntriesController#create` to create entries under the route-selected home and assign `Current.user` as creator.
- Added strong parameters that exclude client-supplied home, creator, and cents fields.
- Scoped optional item assignment to the selected home's items and surfaced an item-home validation error.
- Normalized non-negative dollar input to integer cents with `BigDecimal`; retained normalized valid input and invalid input on re-render.
- Added controller coverage for successful creation, blank optional fields, model validation failures, invalid and negative costs, and cross-home items.

## TDD Evidence

- RED: `bin/rails test test/controllers/entries_controller_test.rb` produced 6 expected failures because `EntriesController#create` was missing. Creation assertions observed no record change, and invalid submissions returned 404 rather than 422.
- GREEN: after implementing the brief-specified controller methods, `bin/rails test test/controllers/entries_controller_test.rb` passed with `8 runs, 70 assertions, 0 failures, 0 errors, 0 skips`.

## Test Command/Output Summary

- `bin/rails test test/controllers/entries_controller_test.rb`: PASS - 8 runs, 70 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rubocop app/controllers/entries_controller.rb test/controllers/entries_controller_test.rb`: PASS - 2 files inspected, no offenses detected.
- `bin/rails test`: BLOCKED before execution by an existing untracked test at `test/components/entries/timeline_component_test.rb`; it raises `NameError: uninitialized constant Entries`. This is outside Task 3's files and was left untouched.
- `git diff --check`: PASS.

## Files Changed

- `app/controllers/entries_controller.rb`
- `test/controllers/entries_controller_test.rb`
- `.superpowers/sdd/task-3-report.md` (this report; intentionally not staged)

## Self-Review

- `set_items` now runs for both `new` and `create`, so failed creates can re-render the scoped item select.
- The route-selected home and current user are authoritative; unpermitted client fields cannot override them.
- `assign_item` rejects records outside the selected home with the exact required message.
- Cost conversion rejects malformed and negative values, leaves blank costs as `nil`, and stores valid decimal dollars as cents.
- The task does not add or alter an entry detail action or view.

## Concerns

- The focused Task 3 suite and targeted lint check pass. The full suite is currently prevented by the unrelated, untracked component-test namespace error described above.

## Task 3 review fix

- Rejected non-finite `NaN` and `Infinity` cost values before rounding so they use the existing `Cost must be a valid dollar amount` validation error, preserve the submitted input, and do not create an entry.
- Added focused controller coverage for both non-finite inputs.
- `bin/rails test test/controllers/entries_controller_test.rb`: PASS - 10 runs, 84 assertions, 0 failures, 0 errors, 0 skips.
- `bin/rubocop --cache false app/controllers/entries_controller.rb test/controllers/entries_controller_test.rb`: PASS - 2 files inspected, no offenses detected.
- `git diff --check`: PASS.
