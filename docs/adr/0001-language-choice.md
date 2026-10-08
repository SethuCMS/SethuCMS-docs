# ADR 0001: Language choice

- Status: Proposed
- Date: 2026-10-08

## Context

The platform has a gateway, adapters for many databases, an admin UI, and SDKs for several languages. The team is small. Query AST, content model and capability flags are shared across all layers.

## Decision

Use **TypeScript** for core, adapter-sdk, first-party adapters, api, worker and admin. Generate Dart and Python SDKs from OpenAPI. Allow adapters in any language, including Go, through a language-neutral protocol.

## Consequences

Positive:
- One type system across server, adapters and UI.
- Strong official SDK coverage for the target databases.
- Fastest route to an MVP.

Negative:
- CPU-heavy and very high-concurrency work is weaker than in Go or Rust.
- The event loop must be protected: adapters run in worker processes, not in the API process.

## Alternatives considered

Go core, Python core, Rust core, Java/Kotlin. See [Language decision](../03-language-decision.md).

## Revisit when

Worker CPU or connection counts become the bottleneck, or a customer needs an adapter for a database whose best driver is not on Node.
