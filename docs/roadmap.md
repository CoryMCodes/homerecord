# HouseOS Roadmap

## Phase 0: Product Foundation

- Establish product docs.
- Decide core domain language.
- Lock the initial Rails-first architecture.
- Keep scope focused on the timeline-first MVP.

## Phase 1: Web MVP Vertical Slice

Goal: prove the core loop on the mobile-first Rails web app.

- Authentication.
- Automatic account creation.
- Home creation.
- Home timeline.
- Item creation for systems and appliances.
- Entry creation with fixed entry types.
- Optional item link on entries.
- Active Storage file attachments on entries.
- Attachment content type, extension, size, and count validation.
- Entry detail screen.
- Simple search across homes, items, and entries.
- Basic authorization boundaries.
- Minitest coverage for the critical domain behavior.

## Phase 2: Product Hardening

Goal: make the web app feel usable and trustworthy.

- Empty states.
- Mobile polish.
- Attachment previews.
- Better timeline grouping.
- Editing and deleting entries.
- Editing items.
- Multiple homes UI.
- Import/export backup considerations.
- Sentry and structured error reporting.
- Production storage configuration.

## Phase 3: Hotwire Native iOS

Goal: wrap the proven web slice in a thin native shell.

- Hotwire Native iOS shell.
- Cookie-backed Rails session handling.
- Native navigation conventions.
- Camera/photo picker compatibility.
- Document picker compatibility.
- Route rules for native presentation.
- Basic native smoke tests.

## Phase 4: Collaboration

Goal: let a home record become shared.

- Invite another user.
- Pending invitation state.
- Role model.
- Revoke/resend invitations.
- Shared timeline access.
- Audit considerations for edits and deletes.

## Phase 5: Robust Search

Goal: make HouseOS excellent at finding home history.

- PostgreSQL full-text search tuning.
- Better ranking.
- Search result grouping by home, item, and entry.
- PDF text extraction.
- OCR for receipt images and appliance labels.
- Document metadata extraction.
- Search inside attachments.
- Optional semantic search if ordinary search is not enough.
- Later: "ask my home" AI retrieval.

## Phase 6: Records to Intelligence

Goal: use accumulated records to reduce user effort.

- Appliance label scanning.
- Receipt classification.
- Suggested item fields.
- Suggested entry type and title.
- Maintenance suggestions.
- Reminder creation from entries.
- Utility and renovation cost tracking.
- Home value and project ROI exploration.

## Phase 7: Portability and Trust

Goal: make the promise of a long-lived home record credible.

- Export a home's timeline, items, files, and documents.
- Generate a shareable home history packet.
- Improve backup and recovery processes.
- Add account-level data deletion and portability controls.
- Document storage and retention expectations clearly.

## Future Product Areas

- Android with Hotwire Native Android.
- Payments and subscription plans.
- Property-management mode.
- Contractor/vendor history.
- Insurance and warranty workflows.
