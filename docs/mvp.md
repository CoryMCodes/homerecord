# HouseOS MVP

## MVP Promise

HouseOS v1 lets a user create a home, record what happens to it, attach files and photos, and find those records later.

The core loop is:

```text
Create home -> add item -> add entry -> attach files/photos -> view timeline -> search later
```

## First Build Milestone

The first complete vertical slice is:

```text
Sign up
-> create first Home
-> land on Home timeline
-> add Item: Water Heater
-> add Entry: Replaced water heater
-> attach photo/PDF
-> see Entry on timeline
-> tap Entry detail
-> search "water heater" and find it
```

This proves authentication, account structure, homes, items, entries, attachments, timeline display, search, and authorization boundaries.

## Core Objects

```text
Account
  access, billing, and collaboration container

User
  person who signs in

Membership
  connects users to accounts

Home
  a house, condo, apartment, rental, or managed property

Item
  a tracked appliance or system in v1

Entry
  something that happened to the home
```

## V1 Home Fields

A home should include:

- name
- address optional
- home_type optional: house, condo, apartment, rental, other

The address is useful for search, future weather/location-aware features, and future home context, but the first product should not require users to enter a full address before they can start.

## V1 Item Scope

In code, `Item` should be flexible enough to grow. In the v1 product, items should be limited to systems and appliances.

Examples:

- refrigerator
- dishwasher
- washer
- dryer
- oven
- HVAC
- furnace
- water heater
- roof
- electrical panel
- plumbing
- garage door
- sprinkler system

Do not expose rooms, paint, fixtures, spaces, furniture, projects, or finishes as first-class item categories in v1.

Use `item_kind`, not `type`, for the item category because `type` has special meaning in Rails.

V1 item fields:

- item_kind: appliance or system
- name
- brand optional
- model_number optional
- serial_number optional
- installed_on optional
- notes optional

Brand, model number, and serial number are intentionally optional. Appliances often have them, some systems have them, and broad systems like roof or plumbing often will not.

## V1 Entry Types

Entries use a small fixed set of types:

- maintenance
- repair
- installation
- replacement
- inspection
- purchase
- note
- memory

Entries can be attached to a home directly or optionally linked to an item.

Examples of house-level entries:

- moved in
- hosted Christmas
- basement flooded
- water damage
- closing day photos

Examples of item-linked entries:

- changed furnace filter
- replaced water heater
- uploaded dishwasher manual
- repaired garage door

## Attachments

All files belong to entries in v1. Nothing is just uploaded.

The UI may still allow uploads from an item page. For example, a user viewing Dishwasher can tap "Upload manual." Internally, that should create an item-linked entry such as "Uploaded dishwasher manual" and attach the file to that entry.

Allowed attachment types:

- JPEG
- PNG
- HEIC
- HEIF
- PDF

V1 validates:

- content type
- extension
- file size
- number of files per entry

Recommended v1 limits:

- 20 MB maximum per file
- 10 files maximum per entry

Examples:

```text
Entry: Replaced water heater
Item: Water Heater
Files: receipt.pdf, warranty.pdf, install-photo.jpg
```

V1 should not introduce separate Photo, Document, Receipt, Warranty, or Manual models.

## Search

V1 includes simple database-backed search across:

- home name/address
- item name
- item brand
- item model number
- item serial number
- entry title
- entry description
- contractor/vendor name

V1 search does not include OCR, PDF text extraction, AI search, semantic search, or saved filters.

## Onboarding

Onboarding should be light:

1. Sign up.
2. Create an account automatically.
3. Add first home.
4. Land on the home timeline.
5. Prompt user to add the first entry.

Do not ask users to create a full home inventory during onboarding.

## First Screen

After onboarding, the user lands on the selected home's timeline.

The mobile-first layout should include:

- home name at the top
- search near the top
- vertical scrolling timeline as the primary surface
- bottom dock for quick navigation/actions
- prominent add-entry action
- fast access to items

## Explicitly Out of MVP

- reminders
- recurring schedules
- push notifications
- AI
- OCR
- PDF text extraction
- appliance manual lookup
- utility imports
- home valuation
- multi-user invite UI
- payments
- Android app
- property management workflows
