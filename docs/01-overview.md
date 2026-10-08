# 1. Overview

## Problem

Content tools are tied to one database. Strapi and Directus are SQL-only, FireCMS is Firestore-first, and internal-tool builders (Retool, Appsmith) reach many databases but are not content CMSs. Teams running several stacks end up with several admin panels.

## Product

AnyDB CMS is a **database-agnostic CMS and admin layer**:

- Connect any supported database, including bring-your-own cloud databases.
- Introspect it, describe it as a canonical content model, and edit it through one admin UI.
- Expose one REST/GraphQL API so every client stack uses the same contract.
- Keep credentials server-side, read-only by default, with a full audit trail.

## Users

| User | Needs |
|---|---|
| Developer | Connect a database, get an API and SDK |
| Editor | Edit content without touching the database |
| Admin / security | Control who sees what, rotate credentials, read audit logs |
| Tenant (multi-tenant mode) | Bring their own database safely |

## In scope (MVP)

- Adapters: Postgres, MySQL, MongoDB, Firestore, SQL Server, DynamoDB
- Introspection, content-model overlay, CRUD, cursor pagination
- RBAC with field and row rules, SSO/OIDC
- Encrypted credential vault, audit log, SSRF guard
- REST + GraphQL + OpenAPI, TypeScript SDK, generated Dart and Python SDKs
- Admin UI

## Later

Cosmos DB, Spanner, BigQuery, Redshift, Redis, Firebase RTDB, realtime subscriptions across all adapters, gRPC, adapters in other languages through the adapter protocol.

## Non-goals

- Not a database or migration tool. It reads and writes the customer's database; it does not replace it.
- Not a cross-database transaction manager. Cross-source relations are resolved at the gateway, not made atomic.
- Not a BI or analytics tool. Warehouse adapters (BigQuery, Redshift) are read-only by default.

## Principles

1. **Security first.** Credentials never reach a browser or mobile app.
2. **Honest capabilities.** Each adapter declares what it can and cannot do; the UI follows it.
3. **Adapters are isolated.** One slow or hostile database cannot starve the rest.
4. **One contract.** Clients never talk to a database directly.
