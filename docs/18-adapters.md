# 18. Database adapters

The gateway ships with these adapters. Each one is a separate package in `sethucms-adapters`, passes the same conformance suite, and is checked by the same guard layer (field allowlist, parameters only, permission engine).

| Adapter | Kind | Package | Driver | Tested against |
|---|---|---|---|---|
| Memory | `memory` | `@sethucms/adapter-memory` | none | in-process |
| PostgreSQL | `postgres` | `@sethucms/adapter-postgres` | `pg` | PostgreSQL 16 |
| SQLite | `sqlite` | `@sethucms/adapter-sqlite` | Node's built-in `node:sqlite` | real SQLite files |
| MySQL / MariaDB | `mysql` | `@sethucms/adapter-mysql` | `mysql2` (peer) | **MariaDB 10.11** and **MySQL 8.0** (real servers, full conformance suite) and Dolt |
| MongoDB | `mongodb` | `@sethucms/adapter-mongodb` | `mongodb` (peer) | **FerretDB 1.24** (MongoDB-compatible), not MongoDB itself |
| Firestore | `firestore` | `@sethucms/adapter-firestore` | `@google-cloud/firestore` (peer) | an **in-memory fake**, not Firestore |

Read the "Tested against" column before you rely on an adapter. A compatible server is not the real thing: MySQL, MariaDB, MongoDB and Firestore have not been run through these tests, and you should run the live tests (below) against your own server before production use.

Peer drivers are not installed for you. Add the one you need to the gateway (`pnpm add mysql2` in `apps/api`).

## Shared rules

- Passwords and keys go in the connection's credentials, which the vault encrypts. They never appear in settings, logs or error messages.
- Network connections go through the gateway's network guard (private ranges blocked in production unless `SETHUCMS_ALLOW_PRIVATE_NETWORKS=true`).
- Connections can be read-only. Writes are then refused before reaching the driver.
- Every adapter can *create* a missing collection when a migration asks for it (doc 17).

## SQLite

For small sites, edge deployments and local work. A "connection" is a **file on the gateway's disk**.

| Setting | Meaning |
|---|---|
| `path` | `:memory:` or a file name **inside** the folder set by `SETHUCMS_SQLITE_DIR` |
| `busyTimeoutMs` | how long to wait for a lock (0-60000, default 5000) |

- File databases are off until `SETHUCMS_SQLITE_DIR` is set. Paths with `..`, absolute paths outside the folder, and URIs are refused.
- Needs **Node 22.5 or newer** (`node:sqlite`). The Docker image must use Node 22.
- SQLite allows one writer at a time. Do not point another program at a file the gateway is writing unless you accept lock waits.
- Back up with the SQLite backup API or by copying the file while the gateway is stopped. Copying a live file can give a torn copy.

## MySQL and MariaDB

| Setting | Meaning |
|---|---|
| `host`, `port` | server address (port default 3306) |
| `database` | database name |
| `ssl` | default **true**; turn off only on a trusted private link |
| `maxConnections` | 1-20, default 5 |
| `statementTimeoutMs` | 100-120000, default 15000 |
| credentials `user`, `password` | encrypted in the vault |

- Identifiers are quoted with backticks and values are always parameters.
- Pagination is offset based.
- `LIKE` wildcards in user text are escaped.
- Not verified on MySQL 5.7 or 9, or other MariaDB versions. MariaDB 10.11 and MySQL 8.0 are verified. It has no real JSON type (JSON is LONGTEXT plus a `json_valid` check), and the adapter finds those columns from the check; a bug where they came back as text was found and fixed that way.

## MongoDB

MongoDB has no schema, so the adapter works out collection shapes by **sampling documents**, or you declare them.

| Setting | Meaning |
|---|---|
| `host`, `port`, `srv` | address; `srv: true` for Atlas `mongodb+srv` (no port) |
| `database`, `authSource` | database, and where the user is defined (default `admin`) |
| `tls` | default **true** |
| `sampleSize` | documents sampled per collection (1-1000, default 100) |
| `collections` | declared definitions that replace sampling |
| `maxConnections`, `statementTimeoutMs` | as above |

- Integer ids are issued from a counter collection `_sethucms_counters`; declared and discovered shapes are kept in `_sethucms_schemas`. Both are hidden from content.
- Queries are built as typed documents from the allowlisted filter tree. Operators in user values (`$ne`, `$where`) are rejected before they reach the driver.
- Sampling can miss rare fields. Declare the collections you care about.
- Tested against FerretDB 1.24 only. Real MongoDB behaviour (collation, index use, transactions) is not verified.

## Firestore

| Setting | Meaning |
|---|---|
| `projectId`, `databaseId` | project and database (default `(default)`) |
| `emulatorHost` | `host:port` of the emulator, for development only |
| `sampleSize`, `collections` | as for MongoDB |
| `maxScanDocuments` | most documents a text search may read (10-50000, default 5000) |
| credentials `serviceAccount` | service account key JSON, encrypted in the vault; otherwise Google default credentials |

- Firestore cannot do OR with inequality, several inequality fields, or arbitrary text search. The gateway **refuses** such queries (`CAPABILITY_UNSUPPORTED`) instead of approximating them.
- `contains` and `startsWith` on text are done by reading up to `maxScanDocuments` documents; they are slow and bounded on purpose.
- Integer ids come from `_sethucms_counters`, as for MongoDB.
- **Only tested against an in-memory fake that we wrote.** It has never talked to Firestore or the emulator. Treat this adapter as experimental until you have run it against the emulator or a test project.

## Running the live tests against your own server

From `sethucms-adapters`:

```sh
SETHUCMS_TEST_PG_URL=postgres://user:pass@host:5432/db  pnpm --filter @sethucms/adapter-postgres test
SETHUCMS_TEST_MYSQL_URL=mysql://user:pass@host:3306     pnpm --filter @sethucms/adapter-mysql test
SETHUCMS_TEST_MONGO_URL=mongodb://host:27017            pnpm --filter @sethucms/adapter-mongodb test
```

The tests create and drop their own scratch database or collections. Use a throwaway server. Without these variables the live tests are skipped.

## Writing your own adapter

Implement the `Adapter` contract (doc 5) and run `defineConformanceSuite`. SQL databases should build on `@sethucms/adapter-sql-kit`, which holds the dialects, query builders, table creation and row normalising shared by PostgreSQL, MySQL and SQLite. Optional methods: `createCollection` (needed for migration table creation) and `finishBulkLoad` (for example, moving a sequence past copied ids).
