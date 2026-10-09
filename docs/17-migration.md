# 17. Moving data between databases

Copy the records of one connection into another: PostgreSQL to a new PostgreSQL, a demo into a real database, or between any two adapters the gateway supports (memory, PostgreSQL, SQLite, MySQL/MariaDB, MongoDB, Firestore; doc 18). Admin only.

## What it does and does not do

Does:
- can **create the missing tables or collections** in the target (`createMissing`, below);
- reads the source (never writes to it) and writes to the target through the same adapter layer the CMS uses;
- checks first (a dry run), then copies in the background, with progress you can follow and cancel;
- copies parent collections before the ones that point at them;
- checks every record against the target's own rules before writing it;
- rewrites references when the target assigns new ids;
- is safe to repeat: with the default conflict rule, records already in the target are left alone, so a stopped or failed run is continued by running it again;
- checks the result: record counts per collection, and whether each stored record matches what was sent.

Does not:
- **create indexes, constraints or views** in the target. With `createMissing` it creates plain tables or collections (below); otherwise the target must already have them.
- translate between very different types. Only compatible types are allowed (see below).
- copy relations as such, indexes, constraints, views, users or permissions. Only records.
- freeze the source. Records changed in the source while the copy runs may be missed or copied twice (see "Before you start").

## Quick start (admin page)

1. Open **Move data**.
2. Choose *Copy from* and *Copy into*. The target must be read-write.
3. Pick what happens when a record already exists, and whether to keep the original ids.
4. **Check first.** Fix anything listed in red. Warnings are information.
5. **Start copying.** Watch progress; use **Cancel** if needed.

The page copies every collection with the same names. For renamed collections or fields, use the API.

## API

All routes need an admin token.

| Route | Purpose |
|---|---|
| `POST /v1/admin/migrations/plan` | dry run; writes nothing |
| `POST /v1/admin/migrations` | start; answers `202` with a job |
| `GET /v1/admin/migrations` | recent jobs (kept in memory, last 50) |
| `GET /v1/admin/migrations/:id` | progress |
| `POST /v1/admin/migrations/:id/cancel` | stop after the current record |

```json
{
  "source": "conn_old",
  "target": "conn_new",
  "collections": [
    "orders",
    { "from": "customers", "to": "clients", "fields": { "name": "full_name" } }
  ],
  "onConflict": "skip",
  "preserveIds": false,
  "dropUnmappedFields": false,
  "batchSize": 100,
  "maxRecords": 1000000,
  "maxErrors": 100,
  "verify": true
}
```

| Setting | Default | Meaning |
|---|---|---|
| `collections` | `"all"` | names, or `{from, to, fields}` to rename a collection or fields (source → target) |
| `onConflict` | `skip` | `skip` leaves existing records, `overwrite` updates them, `fail` reports an error |
| `preserveIds` | `false` | write the original ids even if the target normally numbers its own (see below) |
| `dropUnmappedFields` | `false` | allow source fields with no target field to be left behind |
| `batchSize` | `100` | records read per page (1-500) |
| `maxRecords` | `1000000` | per collection |
| `maxErrors` | `100` | stop after this many failed records |
| `verify` | `true` | count records before and after, compare stored values |
| `createMissing` | `false` | create collections the target does not have, from the source's definitions |

Unknown settings are rejected.

## Creating the target tables (`createMissing`)

With `createMissing: true` a collection that does not exist in the target is created for you:

1. the target definition is derived from the source (field names, canonical types, required, primary key, references);
2. tables are created in reference order, parents first;
3. the gateway re-reads the target, so the plan is checked against the tables that really exist;
4. records are copied;
5. `finishBulkLoad` runs once per collection: PostgreSQL moves its sequence past the copied ids, so the next new record does not collide.

What you get: plain tables with a primary key, columns of the nearest native type and foreign keys between collections that are part of the run. What you do not get: indexes, unique constraints, defaults, check constraints, views, triggers. Add those yourself afterwards.

Type choices differ by target (for example `json` becomes `jsonb`, `longtext` or `TEXT`; MongoDB and Firestore store native values). A plan lists each collection under "will be created" so you can read it first. If a collection already exists, it is never altered; the normal checks apply to it.

The admin page has a checkbox for this. In the API it is blocked for read-only targets. Creating objects in someone else's database is a bigger step than copying rows: check the plan, and use a database user that is allowed to create tables only while the migration runs.

Verified combinations (with `createMissing`): SQLite → SQLite, PostgreSQL 16, MariaDB 10.11 and MySQL 8.0 (real servers) and Dolt (MySQL-compatible), FerretDB (MongoDB-compatible) and the Firestore fake. See "Limits".

## Checks the plan makes

Blocking (the run is refused):
- the target has no such collection, or a mapped field does not exist;
- a source field has no target field (unless `dropUnmappedFields`);
- a target field is required but nothing fills it;
- types that cannot hold each other's values;
- the target key is not filled by any source field;
- a collection that points at itself while the target renumbers records.

Warnings (the run is allowed):
- compatible-but-different types (`string`↔`text`, `integer`→`decimal`, `reference`↔`string`/`integer`): each value is checked and bad ones are reported per record;
- fields the target generates or locks (not copied);
- references to collections outside this migration (copied as they are);
- optional in the source but required in the target.

## Ids

- **Target key is not generated** (a normal text or integer key): ids are copied as they are. Running again is safe.
- **Target numbers its own records** (PostgreSQL `serial`, MySQL `AUTO_INCREMENT`, SQLite `INTEGER PRIMARY KEY`, the MongoDB/Firestore counter, the memory adapter's generated key): by default the target assigns new ids and every reference in later collections is rewritten to match. The target collection must be empty, because running again would duplicate everything. The gateway refuses a second run into a non-empty collection.
- **`preserveIds: true`:** the original ids are written into the generated key. PostgreSQL accepts this for `serial` columns. Afterwards move the sequence past the largest id, or new inserts will collide:
  ```sql
  SELECT setval(pg_get_serial_sequence('"schema"."orders"', 'id'), (SELECT max(id) FROM "schema"."orders"));
  ```
  Databases that ignore the id (the memory adapter does) make the run fail with a clear message instead of quietly renumbering. PostgreSQL `GENERATED ALWAYS` identity columns reject explicit ids; use the default renumbering instead.

References are found two ways: a `references` marker on a field, or a many-to-one relation whose mapping goes from that field to the other collection's key (what PostgreSQL foreign keys become). Links to a non-key column cannot be rewritten.

## Safety

- Admin only. The target must be read-write. The source is only read.
- Both connections pass the network guard when they open, as for any connection.
- One migration runs at a time per gateway.
- Record values are never logged, audited or put in error messages. A job error holds the collection, the source id, a code and a short reason.
- The audit log records `migration.start`, `migration.finish` and `migration.cancel`, with counts only. It does not record each record, so it is not a copy of the data.
- Every record is validated before it is written, so a value the target would not accept through the CMS is not written through a migration either.
- Overwrite replaces data in the target. Run **Check first**, and back up the target before using it.

## Before you start (production checklist)

1. Back up the target. Take a snapshot of the source too.
2. Pause writes to the source (maintenance window), or accept that late changes are not copied. For a live system, run once, stop writes, then run again: with `skip` only the new records are added; use `overwrite` to pick up edits.
3. Make the target schema first. Use the same names, or map them.
4. Plan, read every message, then start.
5. When it finishes, check `verified` per collection, `failed` and `differences`. A `differences` count means the database stored something a little different from what was sent (for example numeric rounding or time zone). Look at a few records.
6. For `preserveIds` into PostgreSQL, reset the sequences.
7. Check the audit log and switch your application to the new connection.

## Limits you should know

- **History survives a restart.** Jobs are saved to the data folder (the last 50, counts and errors only, never record values). A job that was running when the gateway stopped is shown as *interrupted*. Start it again; with `skip` it continues where it stopped. The copy itself does not resume by itself.
- Records are copied one at a time, not in one transaction. A failure part-way leaves a partial copy; there is no rollback. Repeating the run completes it.
- Pages are read in the database's own order. Heavy changes to the source during a run can shift pages.
- Verification counts stop at 50 million records per collection.
- Tested here:
  - memory↔memory, PostgreSQL→PostgreSQL (ids kept and renumbered, with foreign keys), memory→PostgreSQL, PostgreSQL→memory (refusal), against PostgreSQL 16;
  - SQLite → SQLite, PostgreSQL 16, MariaDB 10.11, MySQL 8.0, Dolt, FerretDB and the Firestore fake, with table creation, full verification (counts, 0 differences) and a new record getting the next id afterwards.
- Not tested: MySQL 5.7 and 9, other MariaDB versions, real MongoDB, real Firestore, other PostgreSQL versions, very large tables, a live production workload. Dolt, FerretDB and the fake are stand-ins.
