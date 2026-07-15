# HouseOS Product Principles

## Timeline First

The home timeline is the primary product surface. Items, files, search, and future reminders exist to support the timeline.

## Records Before Tasks

HouseOS v1 is not a task manager. Reminders, recurring schedules, due dates, and notifications are intentionally post-MVP.

## Fast Capture

Users should be able to record something meaningful quickly, especially on a phone. The app should avoid asking users to build a complete home inventory before getting value.

## Mobile First

The web app should be designed mobile-first and should consider Hotwire Native iOS from the beginning. The build order is still:

1. Mobile-first Rails web app.
2. Complete the first vertical slice on the web.
3. Wrap that slice in Hotwire Native iOS.
4. Adjust web/native behavior early.
5. Add Android later after product patterns stabilize.

## Practical and Personal

HouseOS should support both utility and memory. A home timeline can include repairs, installations, inspections, family visits, move-in day, storm damage, or what a room looked like at Christmas.

## Simple Models, Clear UI

The domain model may support future flexibility, but the first UI should feel concrete. V1 should guide users toward systems and appliances rather than asking them to decide whether everything in the home is an item.

## Architecture for Growth, UI for Focus

The data model should support multiple homes and future collaboration. The initial UI should stay focused on one user's core workflow.

## Search Matters

Search is part of the core promise. V1 search can be simple, but robust search should be a major roadmap pillar.

## Avoid Premature Automation

AI, OCR, appliance manual lookup, utility imports, and home valuation are not part of the MVP. They should only be added once the manual workflow proves valuable.

## Rails Conventions Win

Prefer conventional Rails, simple server-rendered UI, Hotwire, and PostgreSQL before introducing new layers. Add dependencies only when they solve a concrete problem.
