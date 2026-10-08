# 3. Language decision

This is a recommendation based on the project's needs, not a measured benchmark.

## Recommendation

**TypeScript for the whole MVP.** Add **Go** later for performance-critical or third-party adapters through the adapter protocol. Dart and Python SDKs are generated from OpenAPI.

| Part | Language | Why |
|---|---|---|
| core, adapter-sdk, api, worker | TypeScript (Node.js) | One language across server and UI, shared types, strong official SDKs for Firestore, MongoDB, DynamoDB, Postgres |
| admin UI | TypeScript + React (Refine) | Backend-agnostic data providers, same types as the API |
| Control-plane migrations | SQL | Plain, reviewable |
| SDK: TypeScript | TypeScript | Hand-tuned, first class |
| SDK: Flutter | Dart | Generated + small hand-written layer |
| SDK: Python | Python | Generated + small hand-written layer |
| Third-party / heavy adapters (later) | Go (or any language) | Separate process via the protocol |

## Why TypeScript first

- The query AST, content model and capability flags are shared by the gateway, adapters, SDK and admin UI. One type system avoids drift.
- Database SDK coverage is best on Node for the targets that matter (Firebase Admin, MongoDB, DynamoDB, pg/mysql2, Azure and Google clients).
- Fastest path to a working MVP for one or two engineers.

## Where TypeScript is weaker

- CPU-heavy work and very high connection counts are better in Go or Rust.
- A single event loop needs care: run adapters in worker processes, not inside the API process.

## Options compared

| Option | Strength | Weakness | Verdict |
|---|---|---|---|
| TypeScript everywhere | Shared types, fastest MVP, best DB SDK coverage | Weaker for CPU-bound work | **MVP choice** |
| Go core | Fast, small binaries, great concurrency | Admin UI still needs TypeScript; two type systems | Good for later adapters |
| Python core | Rich data libraries | Slower, weaker typing for a gateway | SDK and scripting only |
| Rust core | Performance and safety | Slow to build, thin cloud-SDK coverage | Not worth it for MVP |
| Java/Kotlin | Mature DB drivers | Heavier, slower iteration | Only if a client requires it |

## Language freedom for adapters

Adapters run as separate processes speaking the protocol in `protocol/adapter.proto`. The gateway does not care what language an adapter is written in. First-party adapters ship in TypeScript and run through the same protocol, with an in-process fast path allowed for trusted ones.

See [ADR 0001](adr/0001-language-choice.md).
