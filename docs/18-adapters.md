# 18. Database adapters

The gateway ships with these adapters. Each one is a separate package in `sethucms-adapters`, passes the same conformance suite, and is checked by the same guard layer (field allowlist, parameters only, permission engine).

| Adapter | Kind | Package | Driver | Tested against |
|---|---|---|---|---|
| Memory | `memory` | `@sethucms/adapter-memory` | none | in-process |
| PostgreSQL | `postgres` | `@sethucms/adapter-postgres` | `pg` | PostgreSQL 16 (real server, in CI) |
| SQLite | `sqlite` | `@sethucms/adapter-sqlite` | Node's built-in `node:sqlite` | real SQLite files |
| MySQL / MariaDB | `mysql` | `@sethucms/adapter-mysql` | `mysql2` (peer) | **MySQL 8** and **MariaDB 11** (real servers, in CI, full conformance suite) |
| MongoDB | `mongodb` | `@sethucms/adapter-mongodb` | `mongodb` (peer) | **MongoDB 7** (real server, in CI) |
| Firestore | `firestore` | `@sethucms/adapter-firestore` | `@google-cloud/firestore` (peer) | the **Firestore emulator** (in CI). Experimental |

Read the "Tested against" column before you rely on an adapter. "Tested" means the real server (or Google's emulator for Firestore) in the continuous-integration workflow `.github/workflows/databases.yml`. Run the live tests (below) against your own server before production use.

**Services that speak the same protocol.** The `postgres` adapter is meant to work with Supabase, Neon, RDS, Aurora, Cloud SQL, AlloyDB, Azure PostgreSQL and CockroachDB, and the `mysql` adapter with TiDB, using only a connection string. **None of these has a test of its own yet**, so treat them as untested until you have tried one on a copy of your data. Notes:
- Poolers in transaction mode (Supabase on port 6543, Neon's `-pooler` host) do not keep session state or prepared statements. Use the direct or session-mode address if a connection fails.
- Supabase's service-role key bypasses row-level security (doc 7).
- Turso/libSQL is **not** supported: the SQLite adapter opens only local files.

**Not built:** SQL Server, DynamoDB (and Redis). See the database research in the roadmap (doc 11) for the order we plan them in.

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
- Tested against MongoDB 7 in CI. Amazon DocumentDB, Azure Cosmos DB for MongoDB and FerretDB are not tested; they do not support every feature.

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
- **A new, empty collection.** Firestore has a collection only once it holds a document, so a scan of an empty database finds nothing. An administrator can declare one: on the connection page, fill in **New collection** and **Fields**, or call `POST /v1/admin/connections/{id}/collections` with `{ "name": "projects", "fields": [{ "name": "title", "type": "string", "required": true }] }`. Only the definition is saved (in `_sethucms_schemas`); the database makes the collection with its first record. The connection must be read and write, and the collection is switched on unless you send `"expose": false`.
  The saved fields are the ones records may use, and they cannot be edited yet. Choose them with the data in mind. A collection made by hand in the Firebase console is different: its fields are guessed from the documents already in it.
  This is offered only for Firestore. It is not offered for SQL databases, where creating tables stays a migration step (doc 17).
- **Files.** A Firestore connection can also store images and PDFs, with cleaning, a type check on the bytes and limits (doc 31).
- **The content adapter is tested against the Firestore emulator in CI, not against a real Firestore project.** (The gateway's shared state store, a different piece of code, is also tested against the emulator; see doc 26.) Treat it as experimental until you have run it against a test project.

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
