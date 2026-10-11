# 27. Upcoming features and planned plans

> **Status: planned, not built.** Nothing on this page exists in 0.1.0. It records the direction so contributors, design partners and investors can see where the project is going. Dates, prices and limits are not set.

## Upcoming features

| Feature | What it will do | Rule it follows |
|---|---|---|
| Agentic schema writer | You describe the content you need in plain words. An AI agent drafts the database schema, shows the plan and the exact changes, and applies them only after a person approves | Same rule as drafts (doc 13): it proposes, a person approves. It never changes a database on its own |
| Dashboards | Business and vendor dashboards on top of the same permission system, so each person sees only their own rows | Row filters and field masking (doc 7) apply to every chart and table |
| Ads and paid plans | A free plan supported by ads, and paid plans without them | See the plans below |

These come after the 90-day evidence plan in doc 11. The first priority is still proving the existing adapters, the container image and single sign-on against real servers.

## Planned plans

The plans are for a **hosted** SethuCMS service. The open-source core stays MIT and free to self-host (doc 19). Nothing already shipped will be moved behind a paid plan.

| | Free | Pro | Ultra |
|---|---|---|---|
| Gateway, admin app, drafts, migration | Yes | Yes | Yes |
| Ads | Shown in the middle of the page | None | None |
| Agentic AI features (schema writer and later agents) | No | Yes | Yes, with higher limits (to be decided) |
| Extra databases | Standard price | Standard price | Discounted (future) |

Open points, to decide before any plan goes live:

- Prices, usage limits and what counts as an "extra database" connection.
- How ads are shown in an admin app that handles customer data. Ads must never receive record content, field values or tokens.
- Which agentic features ship first, and how their cost is limited per plan.
- Whether the hosted service needs a data processing agreement and legal review first, because hosting would make SethuCMS a processor of customer data.

## What this means for contributors

Self-hosting is unchanged: you can run every feature that exists today without any plan. Plans only apply to the hosted service, once it exists. A decision on whether to build the hosted service is planned for day 90, based on design-partner feedback.
