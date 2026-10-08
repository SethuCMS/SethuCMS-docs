# 5. Adapter contract

An adapter is the only code that knows a database's native language. It turns the portable query AST into native queries and native results into canonical records.

## Required operations

| Operation | Purpose |
|---|---|
| `connect(config)` | Open a connection or client using resolved credentials |
| `introspect()` | Return collections, fields, types, keys, relations, indexes |
| `capabilities()` | Return capability flags (see below) |
| `find(query)` | List records by filter, sort, projection, cursor |
| `get(collection, id)` | Fetch one record |
| `create / update / delete` | Write operations (blocked on read-only connections) |
| `batch(ops)` | Multiple writes, atomic only if `transactions` is true |
| `subscribe(query)` | Optional realtime stream |
| `close()` | Release resources |

## Capability flags

```ts
interface Capabilities {
  joins: boolean;
  transactions: "none" | "single-document" | "multi-document";
  filters: { or: boolean; inequality: "full" | "single-field" | "none"; fullText: boolean };
  sort: "any-field" | "indexed-only" | "key-only";
  pagination: { cursor: true; offset: boolean };   // cursor is mandatory
  aggregations: boolean;
  realtime: boolean;
  schema: "enforced" | "inferred";
  writes: boolean;
}
```

The gateway and admin UI use these flags to hide or disable unsupported controls instead of doing silent client-side work.

## Mapping rules per family

| Concern | SQL | Document | Key-value |
|---|---|---|---|
| Introspection | Read catalog (information_schema) | Sample documents, infer draft schema | Read table key schema, sample items |
| Filters | Parameterised SQL | Native filter objects | Key conditions only |
| Pagination | Keyset | `startAfter` cursor | `LastEvaluatedKey` |
| Relations | Foreign keys | Reference fields or embedding | Denormalised |
| Transactions | Full | Limited | Limited |

## Error model

Adapters map native errors to a fixed set so clients see one vocabulary:

`CONNECTION_FAILED`, `AUTH_FAILED`, `NOT_FOUND`, `CONFLICT`, `VALIDATION_FAILED`, `CAPABILITY_UNSUPPORTED`, `RATE_LIMITED`, `TIMEOUT`, `READ_ONLY`, `INTERNAL`.

## Protocol

Adapters run as separate processes (or in-process for trusted first-party ones). The wire contract is defined in [`schemas/adapter.proto`](../schemas/adapter.proto) so an adapter can be written in any language.

## Conformance suite

A shared test kit runs the same scenarios against every adapter:

1. introspect returns stable collections and field types
2. create, get, update, delete round trip
3. cursor pagination returns each record exactly once
4. unsupported filters return `CAPABILITY_UNSUPPORTED`
5. read-only connection rejects writes with `READ_ONLY`
6. hostile identifiers and operators are rejected (injection)
7. errors map to the standard set

An adapter is not releasable until all pass.

## Adding a new adapter

1. Copy `packages/adapters/_template`.
2. Fill in `config.schema.ts`, `connection.ts`, `introspect.ts`, `query-compiler.ts`, `type-map.ts`.
3. Declare `capabilities.ts` honestly.
4. Register in `registry.ts`.
5. Pass conformance and security suites.

Nothing in core, api or admin changes.
