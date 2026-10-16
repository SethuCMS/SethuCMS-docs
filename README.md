# SethuCMS: Documentation

**One CMS for every database.** SethuCMS connects to SQL, document, key-value and realtime databases (including cloud-hosted ones such as Firebase, Supabase, Neon, MongoDB Atlas, AWS, Google Cloud and Azure) and gives every client stack (Next.js, Flutter, Python, mobile) one REST/GraphQL API and one admin UI.

> Status (0.1.0, released to npm in October 2026): the core, six adapters (memory, PostgreSQL, SQLite, MySQL/MariaDB, MongoDB, Firestore), the gateway, the admin app, drafts, publish, live preview, single sign-on (Google, GitHub and Firebase), per-person workspaces, schema as code, image and PDF storage, change feed and webhooks are built. PostgreSQL, MySQL, MariaDB and SQLite are tested against real servers. MongoDB and Firestore are only tested against stand-ins. A hosted gateway with the admin app runs on Vercel with its state in Firestore (doc 26). The container image, the other deploy workflows and a real identity provider have not been run end to end. Pages 1 to 11 describe the full design (parts of it are still future work); pages 12 to 33 describe what is built and how to run, deploy and use it. See the [roadmap](docs/11-roadmap.md) for what is done and what is next.

## Reading order

| # | Document | What it answers |
|---|---|---|
| 1 | [Overview](docs/01-overview.md) | What is it, who is it for, scope and non-goals |
| 2 | [What to build](docs/02-what-to-build.md) | Components, deliverables, MVP vs later |
| 3 | [Language decision](docs/03-language-decision.md) | Which programming language for which part |
| 4 | [Architecture](docs/04-architecture.md) | System, request flow, deployment (Mermaid) |
| 5 | [Adapter contract](docs/05-adapter-contract.md) | How a new database is added |
| 6 | [Data model & schemas](docs/06-data-model.md) | Control-plane schema, canonical content model, query AST |
| 7 | [Security](docs/07-security.md) | Credentials, least privilege, SSRF, audit |
| 8 | [API](docs/08-api.md) | REST/GraphQL surface, errors, pagination |
| 9 | [SDKs](docs/09-sdks.md) | Generated clients (TS, Dart, Python, others) |
| 10 | [Deployment](docs/10-deployment.md) | Docker, Kubernetes, cloud identity, networking |
| 11 | [Roadmap](docs/11-roadmap.md) | Phases, file counts, order of work, where we are |
| 12 | [Gateway](docs/12-gateway.md) | The built gateway: request pipeline, many databases, security, limits |
| 13 | [Drafts and publishing](docs/13-drafts-and-publishing.md) | Drafts, publish, conflict checks, live preview |
| 14 | [Build and run](docs/14-build-and-run.md) | Build everything and run it on your machine |
| 15 | [Deploy to production](docs/15-deploy-production.md) | One image, secrets, HTTPS, verify, operate, limits |
| 16 | [Logging and monitoring](docs/16-logging-and-monitoring.md) | Log fields, metrics, alerts, audit chain, shipping logs |
| 17 | [Moving data](docs/17-migration.md) | Copy one database into another: plan, create tables, ids, safety, limits |
| 18 | [Database adapters](docs/18-adapters.md) | The six adapters, their settings, and what each was really tested on |
| 19 | [Open-source release checklist](docs/19-open-source-release.md) | What to do before and on the day the repositories go public |
| 20 | [Sponsorship and funding](docs/20-sponsorship.md) | Where sponsorship can go, what it pays for, rules for sponsors |
| 21 | [Single sign-on](docs/21-sso.md) | Sign in with an identity provider (OIDC) |
| 22 | [Deploy to the cloud](docs/22-deploy-cloud.md) | Cloud Run and a VPS with Compose |
| 23 | [gRPC adapters](docs/23-grpc-adapters.md) | Write an adapter in another language |
| 24 | [Changes and webhooks](docs/24-changes-and-webhooks.md) | The change feed and outgoing webhooks |
| 25 | [Use it from your app](docs/25-use-from-your-app.md) | Install the SDK, call it from Next.js, React, Angular or plain JavaScript |
| 26 | [Hosted gateway and first content connection](docs/26-hosted-gateway.md) | The live setup on Vercel, the admin app, adding your content database safely, reading it from a website |
| 27 | [Upcoming features and plans](docs/27-upcoming-and-plans.md) | Planned, not built: agentic schema writer, dashboards, ads, and the Free, Pro and Ultra plans |
| 28 | [Run it yourself](docs/28-run-it-yourself.md) | Run the gateway and admin app on your own machine |
| 29 | [Schema as code](docs/29-schema-as-code.md) | A schema file that names fields, picks editors, hides and limits them, without touching your database |
| 30 | [Workspaces](docs/30-workspaces.md) | Every person who signs in gets an isolated workspace of their own |
| 31 | [Images and files](docs/31-files-and-images.md) | Upload, safety rules and limits for images and PDFs stored in Firestore |
| 32 | [The admin app](docs/32-admin-app.md) | Hosted and content-only builds, the content page, field picker, edit as code |
| 33 | [How the code is laid out](docs/33-code-layout.md) | The 700-line rule and where each part lives |

A printable version is in [`latex/`](latex) (`sethucms-design-docs.pdf`). The slide deck (PowerPoint and PDF) is in [`presentations/`](presentations). Instructions for coding agents are in each repository's `AGENTS.md`. Decision records live in [`docs/adr/`](docs/adr). Machine-readable schemas live in [`schemas/`](schemas).

## Conventions

- Diagrams are Mermaid and render on GitHub.
- "MVP" means the first release: Postgres, MySQL, MongoDB, Firestore, SQL Server, DynamoDB.
- Time and file-count estimates are planning guesses, not benchmarks.
- The npm scope is `@sethucms`. Trademark and domain checks are listed in the [release checklist](docs/19-open-source-release.md).
