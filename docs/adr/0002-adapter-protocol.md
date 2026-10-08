# ADR 0002: Adapters as processes behind a protocol

- Status: Proposed
- Date: 2026-10-08

## Context

Supporting "any database" means supporting many drivers, some with weak or no Node support. One crashing or slow connection must not affect others. Tenants bring their own databases, which is an outbound-connection and isolation risk.

## Decision

Define the adapter contract in `schemas/adapter.proto` (gRPC) with an equivalent OpenAPI form. Run adapters as separate worker processes. Allow an in-process fast path for trusted first-party adapters that implement the same interface.

## Consequences

Positive:
- Any language can implement an adapter.
- Failure and resource isolation per connection or tenant.
- A conformance kit can test every adapter the same way.

Negative:
- A network hop adds latency.
- More moving parts to deploy and monitor.

## Mitigations

In-process mode for trusted adapters, connection reuse, and per-connection pool caps.
