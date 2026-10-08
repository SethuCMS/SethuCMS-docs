# AnyDB CMS: Documentation

**One CMS for every database.** AnyDB CMS connects to SQL, document, key-value and realtime databases (including cloud-hosted ones such as Firebase, Supabase, Neon, MongoDB Atlas, AWS, Google Cloud and Azure) and gives every client stack (Next.js, Flutter, Python, mobile) one REST/GraphQL API and one admin UI.

> Status: the core, two adapters (memory, PostgreSQL), the gateway, the admin app, drafts, publish and live preview are built and tested locally. Pages 1 to 11 describe the full design (parts of it are still future work); pages 12 to 15 describe what is built and how to run and deploy it. See the [roadmap](docs/11-roadmap.md) for what is done and what is next.

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

A printable version is in [`latex/`](latex) (`anydbcms-design-docs.pdf`). Instructions for coding agents are in each repository's `AGENTS.md`. Decision records live in [`docs/adr/`](docs/adr). Machine-readable schemas live in [`schemas/`](schemas).

## Conventions

- Diagrams are Mermaid and render on GitHub.
- "MVP" means the first release: Postgres, MySQL, MongoDB, Firestore, SQL Server, DynamoDB.
- Time and file-count estimates are planning guesses, not benchmarks.
- "anydbcms" is the working name. Check domain, npm scope and trademark before committing.
