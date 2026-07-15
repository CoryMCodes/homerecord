# Repository Guidelines

## Project Structure & Module Organization

This is a Rails 8 application. Core app code lives in `app/`: models in `app/models`, controllers in `app/controllers`, views in `app/views`, jobs in `app/jobs`, mailers in `app/mailers`, and helpers in `app/helpers`. Frontend JavaScript uses import maps and Stimulus under `app/javascript`; Tailwind source styles are in `app/assets/tailwind/application.css`, with built assets in `app/assets/builds`. Database schemas, seeds, and migrations belong in `db/`. Tests live in `test/`, grouped by Rails convention (`test/models`, `test/controllers`, `test/integration`, etc.). Project documentation is in `docs/`.

## Build, Test, and Development Commands

- `bin/setup`: install dependencies and prepare the local database.
- `bin/dev`: run the Rails server and Tailwind watcher via `Procfile.dev`.
- `bin/rails server`: run only the web server.
- `bin/rails test`: run the Minitest suite.
- `bin/rails test:system`: run browser-based system tests.
- `bin/rubocop`: check Ruby style with Rails Omakase rules.
- `bin/ci`: run the local CI sequence: setup, RuboCop, security audits, tests, and seed validation.

## Coding Style & Naming Conventions

Follow standard Rails naming: singular model classes (`User`), plural table names (`users`), controllers ending in `Controller`, and test files ending in `_test.rb`. Use two-space indentation for Ruby, ERB, YAML, and JavaScript. Keep business logic in models or service objects rather than controllers when it grows beyond request handling. Ruby style is enforced by `rubocop-rails-omakase` through `.rubocop.yml`.

## Testing Guidelines

Use Minitest, Rails fixtures, and the default Rails test layout. Add or update tests for every behavior change. Prefer focused model, controller, or integration tests before adding slower system tests. Name tests descriptively, for example `test "creates account with valid attributes"`. Run `bin/rails test` before submitting, and use `bin/ci` for a full local check.

## Commit & Pull Request Guidelines

This repository has no existing commit history yet, so use clear, imperative commit subjects such as `Add account model` or `Fix onboarding redirect`. Keep each commit focused. Pull requests should include a short summary, testing notes, linked issues when applicable, and screenshots for UI changes. Confirm CI is green before requesting review.

## Security & Configuration Tips

Do not commit secrets. Rails credentials are stored in `config/credentials.yml.enc`; share required keys through the team’s secure channel. Run `bin/bundler-audit`, `bin/importmap audit`, and `bin/brakeman` when changing dependencies, JavaScript imports, or request-handling code.
