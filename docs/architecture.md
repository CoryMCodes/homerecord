# HouseOS Architecture

## Architecture Baseline

HouseOS is a Rails-first monolith with a mobile-first server-rendered UI and thin native shells.

The initial stack:

```text
Ruby 3.4
Rails 8.1
PostgreSQL
ERB
Turbo
Stimulus
Tailwind CSS
Importmap
Active Storage
Solid Queue
Solid Cache
PostgreSQL-backed search
Minitest
Capybara system tests
Hotwire Native iOS after the first web slice
Kamal later for deployment
S3-compatible object storage in production
```

## Deliberate Non-Choices

V1 should not use:

```text
React
separate JSON API
GraphQL
Node service
Python service
microservices
Redis
Elasticsearch
OpenSearch
vector database
Kubernetes
AI
OCR
PDF text extraction
payments
Android
```

These may be reconsidered only when a real product need appears.

## Domain Model

Initial model shape:

```text
User
  has many Memberships
  has many Accounts through Memberships

Account
  has many Memberships
  has many Users through Memberships
  has many Homes

Membership
  belongs to User
  belongs to Account

Home
  belongs to Account
  has many Items
  has many Entries

Item
  belongs to Home
  has many Entries

Entry
  belongs to Home
  optionally belongs to Item
  has many attached files
```

## Account Model

Use `Account` as the access, billing, and future collaboration container. Avoid `Owner` because it sounds like a user role and does not fit renters, family members, or property managers.

V1 creates one account automatically during signup. The data model supports multiple users per account, but invite UI is post-MVP.

## Home Model

Use `Home` in code and product language.

`Home` should represent a house, condo, apartment, rental, or managed property. Avoid `House` because it is too narrow and avoid `Property` because it makes the consumer product feel too business-oriented.

Suggested attributes:

```text
account_id
name
address optional
home_type optional
```

## Item Model

`Item` is the top-level trackable thing attached to a home.

V1 exposes only:

```text
appliance
system
```

Use `item_kind`, not `type`, for this field because `type` has special meaning in Rails for single-table inheritance.

Suggested attributes:

```text
home_id
item_kind
name
brand optional
model_number optional
serial_number optional
installed_on optional
notes optional
```

The model should leave room for future types:

```text
fixture
finish
space
project
```

Rooms should not be required in v1. Later, a room can become an optional organizing layer:

```text
Home
  has many Rooms
  has many Items

Room
  has many Items

Item
  optionally belongs to Room
```

## Entry Model

`Entry` is the central object in the product. It represents something that happened to the home.

Suggested attributes:

```text
home_id
item_id optional
entry_type
title
occurred_on
description
cost_cents optional
contractor_name optional
created_by_user_id
```

Entry types:

```text
maintenance
repair
installation
replacement
inspection
purchase
note
memory
```

## Attachments

Use Active Storage.

Entries have many attached files. Files should not belong directly to homes or items in v1.

The UI can still offer upload actions from an item screen. Those actions should create an item-linked entry behind the scenes and attach files to that entry.

Development storage:

```text
local disk
```

Production storage:

```text
private S3-compatible object storage
short-lived signed URLs
```

Allowed v1 file types:

```text
jpg
jpeg
png
heic
heif
pdf
```

V1 attachment validations:

```text
content type allowlist
extension allowlist
20 MB maximum per file
10 files maximum per entry
```

## Search

Use PostgreSQL-backed search for v1. Prefer Rails and PostgreSQL primitives before adding search infrastructure.

Searchable fields:

```text
homes.name
homes.address
items.name
items.brand
items.model_number
items.serial_number
entries.title
entries.description
entries.contractor_name
```

Robust search is a roadmap pillar, but not part of the initial implementation.

## Authentication

Use the Rails authentication generator as the starting point unless a concrete reason emerges to use something heavier.

Use cookie-backed sessions for both web and Hotwire Native. Do not introduce token authentication or a separate API for v1.

## Authorization

Every home, item, and entry must be scoped through the current user's account membership.

Authorization boundaries are a critical test target because HouseOS may contain sensitive home addresses, documents, receipts, and photos.

## UI Architecture

Use ERB, Turbo, Stimulus, Tailwind CSS, and Importmap.

The app should be mobile-first. The first post-onboarding screen is a vertical home timeline with:

- home name near the top
- search near the top
- vertical scrolling timeline
- bottom dock for timeline/items/add/search
- prominent entry creation

## Background Jobs

Use Solid Queue.

Early jobs may include:

- attachment preview generation
- image normalization
- orphaned upload cleanup

Later jobs may include:

- PDF text extraction
- OCR
- document classification
- maintenance suggestion generation

## Testing

Use Minitest and Capybara system tests.

Priority test areas:

- account scoping
- authorization boundaries
- home creation
- item creation
- entry creation
- attachment validation
- timeline visibility
- search results

## Deployment Direction

Use Kamal later for deployment to a Rails container.

Do not self-host the production database for the first real launch. Prefer managed PostgreSQL and S3-compatible object storage.
