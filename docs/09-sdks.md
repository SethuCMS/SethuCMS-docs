# 9. SDKs

Every client stack uses the same API. SDKs are generated from `openapi.yaml` so they never drift, with a small hand-written layer for ergonomics.

```mermaid
flowchart LR
    OA[openapi.yaml] --> GEN[Generator in CI]
    GEN --> TS[sdk-ts]
    GEN --> DT[sdk-dart]
    GEN --> PY[sdk-python]
    GEN --> OT[Kotlin, Swift, Go, C#, PHP, Ruby, Rust]
    HW[Hand-written layer:<br/>auth, retries, pagination, realtime] --> TS & DT & PY
```

## Language matrix

| Language | Package | Approach |
|---|---|---|
| TypeScript / JavaScript | `@sethucms/sdk` | Hand-tuned, first class |
| Dart / Flutter | `sethucms` (pub.dev) | Generated models + hand-written client |
| Python | `sethucms` (PyPI) | Generated models + hand-written client |
| Kotlin / Java | generated | Android and JVM |
| Swift | generated | iOS |
| Go, C#, PHP, Ruby, Rust | generated | On demand |

Check package names on npm, pub.dev and PyPI before committing to them.

## Hand-written layer

Each first-party SDK adds the same small set of behaviours:

| File | Purpose |
|---|---|
| `client` | Base URL, token, request pipeline |
| `auth` | Token refresh |
| `query_builder` | Build filters and sorts in the language's idiom |
| `pagination` | Async iterator over cursors |
| `realtime` | Optional subscription helper |
| `errors` | Typed error classes from the API error codes |

## TypeScript additions in 0.2.0

```ts
const { count, exact } = await orders.where(eq('status', 'paid')).count();   // exact: false means "at least"
const all = await cms.counts('conn_123');                                       // every collection you can read

const draft = await orders.drafts.create({ recordId: 7, values: { status: 'paid' } });
await orders.drafts.schedule(draft.id, new Date('2026-12-01T09:00:00+05:30'));
await orders.drafts.cancelSchedule(draft.id);
await orders.drafts.publish(draft.id, { version: draft.version });
```

A scheduled draft publishes its latest saved values with the scheduler's permissions. On a serverless gateway, `schedule` fails with `CAPABILITY_UNSUPPORTED`. `0.2.0` is on npm. It only adds methods, so code written for `0.1.0` keeps working.

## Dart example (shape only)

```dart
final client = SethuClient(baseUrl: url, token: token);
final page = await client
    .collection('c1', 'orders')
    .where('status', eq: 'paid')
    .orderBy('created_at', desc: true)
    .limit(50)
    .list();
```

## Python example (shape only)

```python
client = SethuClient(base_url=url, token=token)
for order in client.collection("c1", "orders").where("status", "eq", "paid").iterate():
    print(order["id"])
```

## Rules

1. SDKs never hold database credentials. They only hold API tokens.
2. Browser and mobile SDKs use short-lived user tokens, never service tokens.
3. CI regenerates SDKs on every API release and fails if generated code is out of date.
4. Semantic versioning follows the API version.
