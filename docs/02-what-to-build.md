# 2. What to build

## Components

| Component | Purpose | MVP |
|---|---|---|
| `packages/core` | Canonical content model, query AST, capability flags, errors | Yes |
| `protocol/` | Language-neutral adapter contract (`adapter.proto` + OpenAPI) | Yes |
| `packages/adapter-sdk` | Base adapter, registry, conformance test kit | Yes |
| `packages/adapters/*` | One adapter per database | 6 adapters |
| `packages/vault` | Envelope encryption, KMS, key rotation, cloud-identity tokens | Yes |
| `packages/auth` | OIDC, RBAC/ABAC, field and row rules | Yes |
| `packages/audit` | Append-only audit writer with redaction | Yes |
| `packages/network-guard` | SSRF blocklist, TLS rules, egress and tunnels | Yes |
| `apps/api` | Gateway: REST, GraphQL, OpenAPI | Yes |
| `apps/worker` | Isolated adapter runners, introspection jobs, realtime | Yes |
| `apps/admin` | Editor/admin UI | Yes |
| `db/control-plane` | Migrations for tenants, connections, metadata, permissions, audit | Yes |
| `sdk-ts` | Hand-tuned TypeScript client | Yes |
| `sdks/dart`, `sdks/python` | Generated from OpenAPI plus a small hand-written layer | Yes |
| `infra/` | Docker, Terraform, Kubernetes | Yes |
| `tests/` | Conformance, security, end-to-end | Yes |

## Adapter families

| Family | Adapters | Notes |
|---|---|---|
| SQL | postgres, mysql, mssql | postgres covers Supabase, Neon, RDS, Aurora, Cloud SQL, AlloyDB, Azure PostgreSQL |
| Document | mongodb, firestore, cosmosdb | mongodb also covers Atlas, DocumentDB (feature gaps), Cosmos Mongo API |
| Key-value | dynamodb, redis | key conditions only; scans are explicit and costly |
| Realtime | firebase-rtdb | path-based |
| Analytics (read-only default) | bigquery, redshift | later |
| Other cloud | spanner, athena, opensearch | later, on demand |

## Per-adapter files

Every adapter folder has the same layout so a new database is a copy-and-fill job:

```
package.json  tsconfig.json  README.md
src/index.ts  adapter.ts  config.schema.ts  connection.ts  auth.ts
src/introspect.ts  capabilities.ts  query-compiler.ts  type-map.ts
src/operations.ts  pagination.ts  realtime.ts  errors.ts
tests/conformance.test.ts  compiler.test.ts  introspect.test.ts  security.test.ts
```

## Dependency rules (enforce in CI)

- `core` imports nothing internal.
- `adapters/*` depend only on `core` and `adapter-sdk`.
- `admin` talks only to `api` or `sdk-ts`, never to a database.
- Only `api` and `worker` may import `vault`.

## Definition of done for an adapter

1. Passes the shared conformance suite.
2. Passes the security suite (injection, identifier allowlist).
3. Declares accurate capability flags.
4. Documents supported services, auth modes and limits in its README.
